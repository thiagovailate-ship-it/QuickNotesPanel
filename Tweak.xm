
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString * const QNPNotesKey = @"dev.quicknotespanel.notes.v2";
static NSString * const QNPLegacyKey = @"QuickNotesPanel.savedNote";

@interface QNOverlayView : UIView <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UITextFieldDelegate>

@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIButton *launcher;
@property(nonatomic, strong) UILabel *heading;
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UILabel *emptyLabel;
@property(nonatomic, strong) UITextField *titleField;
@property(nonatomic, strong) UITextView *textView;
@property(nonatomic, strong) UIButton *newButton;
@property(nonatomic, strong) UIButton *backButton;
@property(nonatomic, strong) UIButton *deleteButton;
@property(nonatomic, strong) UIButton *saveButton;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) NSMutableArray<NSMutableDictionary *> *notes;
@property(nonatomic, copy) NSString *editingID;
@property(nonatomic, assign) BOOL editingMode;

@end

@implementation QNOverlayView

- (UIColor *)blue {
    return [UIColor colorWithRed:0.12 green:0.36 blue:0.95 alpha:1.0];
}

- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    b.backgroundColor = [self blue];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.layer.cornerRadius = 10;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = UIColor.clearColor;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.notes = [NSMutableArray array];

    id saved = [[NSUserDefaults standardUserDefaults] objectForKey:QNPNotesKey];

    if ([saved isKindOfClass:NSArray.class]) {
        for (id item in (NSArray *)saved) {
            if ([item isKindOfClass:NSDictionary.class]) {
                [self.notes addObject:[item mutableCopy]];
            }
        }
    } else {
        NSString *legacy = [[NSUserDefaults standardUserDefaults] stringForKey:QNPLegacyKey];
        if (legacy.length) {
            [self.notes addObject:[@{
                @"id": NSUUID.UUID.UUIDString,
                @"title": [self firstLine:legacy],
                @"body": legacy,
                @"updated": @([[NSDate date] timeIntervalSince1970])
            } mutableCopy]];
            [self persist];
        }
    }

    [self buildInterface];
    return self;
}

- (NSString *)firstLine:(NSString *)text {
    NSString *line = [[text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet] firstObject] ?: @"";
    line = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (line.length > 32) line = [[line substringToIndex:32] stringByAppendingString:@"…"];
    return line;
}

- (void)persist {
    [[NSUserDefaults standardUserDefaults] setObject:self.notes forKey:QNPNotesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)buildInterface {
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor = [UIColor colorWithRed:0.985 green:0.989 blue:1 alpha:1];
    self.panel.layer.cornerRadius = 20;
    self.panel.layer.borderWidth = 1;
    self.panel.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
    self.panel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.panel.layer.shadowOpacity = 0.20;
    self.panel.layer.shadowRadius = 14;
    self.panel.layer.shadowOffset = CGSizeMake(0, 5);
    self.panel.hidden = YES;
    [self addSubview:self.panel];

    self.heading = [[UILabel alloc] init];
    self.heading.text = @"Notas rápidas";
    self.heading.font = [UIFont boldSystemFontOfSize:23];
    self.heading.textColor = [UIColor colorWithWhite:0.12 alpha:1];
    [self.panel addSubview:self.heading];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"×" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:34];
    [close setTitleColor:[UIColor colorWithWhite:0.35 alpha:1] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    close.tag = 1001;
    [self.panel addSubview:close];

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.table.backgroundColor = UIColor.clearColor;
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.rowHeight = 65;
    [self.panel addSubview:self.table];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"Nenhuma nota ainda.\nToque em + Nova para começar.";
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    [self.panel addSubview:self.emptyLabel];

    self.newButton = [self button:@"+ Nova" action:@selector(newNote)];
    [self.panel addSubview:self.newButton];

    self.titleField = [[UITextField alloc] init];
    self.titleField.placeholder = @"Título da nota";
    self.titleField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.titleField.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.titleField.layer.cornerRadius = 9;
    self.titleField.layer.borderWidth = 1;
    self.titleField.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1].CGColor;
    self.titleField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
    self.titleField.leftViewMode = UITextFieldViewModeAlways;
    self.titleField.delegate = self;
    [self.titleField addTarget:self action:@selector(editorChanged) forControlEvents:UIControlEventEditingChanged];
    [self.panel addSubview:self.titleField];

    self.textView = [[UITextView alloc] init];
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.textView.layer.cornerRadius = 9;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1].CGColor;
    self.textView.textContainerInset = UIEdgeInsetsMake(10, 8, 10, 8);
    self.textView.delegate = self;
    [self.panel addSubview:self.textView];

    self.backButton = [self button:@"Voltar" action:@selector(showList)];
    self.backButton.backgroundColor = [UIColor colorWithWhite:0.91 alpha:1];
    [self.backButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [self.panel addSubview:self.backButton];

    self.deleteButton = [self button:@"Excluir" action:@selector(deleteCurrent)];
    self.deleteButton.backgroundColor = [UIColor colorWithWhite:0.91 alpha:1];
    [self.deleteButton setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal];
    [self.panel addSubview:self.deleteButton];

    self.saveButton = [self button:@"Salvar nota" action:@selector(saveCurrent)];
    [self.panel addSubview:self.saveButton];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:11];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1];
    self.statusLabel.text = @"Notas salvas neste app";
    [self.panel addSubview:self.statusLabel];

    self.launcher = [UIButton buttonWithType:UIButtonTypeCustom];
    self.launcher.backgroundColor = [self blue];
    self.launcher.layer.cornerRadius = 25;
    self.launcher.layer.shadowColor = UIColor.blackColor.CGColor;
    self.launcher.layer.shadowOpacity = 0.25;
    self.launcher.layer.shadowRadius = 7;
    self.launcher.layer.shadowOffset = CGSizeMake(0, 3);
    [self.launcher setTitle:@"N" forState:UIControlStateNormal];
    [self.launcher setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.launcher.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [self.launcher addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.launcher];

    [self setEditingMode:NO];
}

- (void)setEditingMode:(BOOL)editing {
    self.editingMode = editing;

    self.table.hidden = editing;
    self.emptyLabel.hidden = editing || self.notes.count > 0;
    self.newButton.hidden = editing;

    self.titleField.hidden = !editing;
    self.textView.hidden = !editing;
    self.backButton.hidden = !editing;
    self.deleteButton.hidden = !editing;
    self.saveButton.hidden = !editing;

    self.heading.text = editing
        ? (self.editingID ? @"Editar nota" : @"Nova nota")
        : @"Notas rápidas";

    [self setNeedsLayout];
}

- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
    if (!self.panel.hidden) {
        [self setEditingMode:NO];
        [self.table reloadData];
    } else {
        [self endEditing:YES];
    }
}

- (void)closePanel {
    [self endEditing:YES];
    self.panel.hidden = YES;
}

- (void)newNote {
    [self endEditing:YES];
    self.editingID = nil;
    self.titleField.text = @"";
    self.textView.text = @"";
    self.statusLabel.text = @"Digite sua nova nota";
    [self setEditingMode:YES];
    [self.titleField becomeFirstResponder];
}

- (NSMutableDictionary *)currentNote {
    if (!self.editingID) return nil;
    for (NSMutableDictionary *note in self.notes) {
        if ([note[@"id"] isEqualToString:self.editingID]) return note;
    }
    return nil;
}

- (void)saveDraft {
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *body = self.textView.text ?: @"";

    if (!title.length && !body.length && !self.editingID) return;
    if (!title.length) title = [self firstLine:body];
    if (!title.length) title = @"Sem título";

    NSMutableDictionary *note = [self currentNote];

    if (!note) {
        note = [@{
            @"id": NSUUID.UUID.UUIDString,
            @"title": title,
            @"body": body,
            @"updated": @([[NSDate date] timeIntervalSince1970])
        } mutableCopy];

        [self.notes insertObject:note atIndex:0];
        self.editingID = note[@"id"];
    } else {
        note[@"title"] = title;
        note[@"body"] = body;
        note[@"updated"] = @([[NSDate date] timeIntervalSince1970]);
    }

    [self persist];
    [self.table reloadData];
    self.emptyLabel.hidden = self.notes.count > 0;
}

- (void)editorChanged {
    self.statusLabel.text = @"Alterações não salvas";
    [self saveDraft];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self editorChanged];
}

- (void)saveCurrent {
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *body = self.textView.text ?: @"";

    if (!title.length && !body.length) {
        self.statusLabel.text = @"Escreva algo antes de salvar";
        return;
    }

    [self saveDraft];
    [self endEditing:YES];
    self.statusLabel.text = @"✓ Nota salva neste app";
    [self setEditingMode:NO];
}

- (void)showList {
    [self saveDraft];
    [self endEditing:YES];
    self.editingID = nil;
    [self setEditingMode:NO];
}

- (void)deleteCurrent {
    NSMutableDictionary *note = [self currentNote];
    if (!note) {
        self.statusLabel.text = @"Nenhuma nota selecionada";
        return;
    }

    [self.notes removeObject:note];
    [self persist];

    self.editingID = nil;
    self.titleField.text = @"";
    self.textView.text = @"";

    [self setEditingMode:NO];
    [self.table reloadData];
    self.statusLabel.text = @"Nota excluída";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QNPNoteCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }

    NSDictionary *note = self.notes[indexPath.row];

    cell.textLabel.text = note[@"title"] ?: @"Sem título";
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];

    NSString *body = note[@"body"] ?: @"";
    cell.detailTextLabel.text = body.length ? body : @"Nota sem conteúdo";
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.43 alpha:1];
    cell.detailTextLabel.numberOfLines = 1;

    cell.backgroundColor = UIColor.clearColor;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *note = self.notes[indexPath.row];

    self.editingID = note[@"id"];
    self.titleField.text = note[@"title"] ?: @"";
    self.textView.text = note[@"body"] ?: "";

    self.statusLabel.text = @"Nota carregada";
    [self setEditingMode:YES];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    self.launcher.frame = CGRectMake(MAX(8, width - 64), 62, 50, 50);

    CGFloat panelWidth = MIN(370, width - 24);
    CGFloat panelHeight = MIN(self.editingMode ? 430 : 500, height - 32);

    self.panel.frame = CGRectMake(
        (width - panelWidth) / 2,
        MAX(8, (height - panelHeight) / 2),
        panelWidth,
        panelHeight
    );

    self.heading.frame = CGRectMake(16, 13, panelWidth - 72, 34);

    UIView *close = [self.panel viewWithTag:1001];
    close.frame = CGRectMake(panelWidth - 48, 7, 38, 38);

    if (!self.editingMode) {
        CGFloat footerY = panelHeight - 66;

        self.table.frame = CGRectMake(8, 52, panelWidth - 16, MAX(100, footerY - 58));
        self.emptyLabel.frame = CGRectMake(18, 80, panelWidth - 36, MAX(80, panelHeight - 160));
        self.newButton.frame = CGRectMake(12, footerY, panelWidth - 24, 42);
    } else {
        self.titleField.frame = CGRectMake(12, 57, panelWidth - 24, 42);

        CGFloat buttonY = panelHeight - 64;
        self.textView.frame = CGRectMake(12, 107, panelWidth - 24, MAX(100, buttonY - 117));

        self.backButton.frame = CGRectMake(12, buttonY, 62, 40);
        self.deleteButton.frame = CGRectMake(80, buttonY, 76, 40);
        self.saveButton.frame = CGRectMake(162, buttonY, panelWidth - 174, 40);
    }

    self.statusLabel.frame = CGRectMake(10, panelHeight - 20, panelWidth - 20, 14);

    [self bringSubviewToFront:self.launcher];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    return hit;
}

@end

static QNOverlayView *QNPOverlay = nil;
static __weak UIWindow *QNPWindow = nil;

static UIWindow *QNPFindWindow(void) {
    UIApplication *app = [UIApplication sharedApplication];

    for (UIWindow *window in app.windows) {
        if (window.isKeyWindow && !window.hidden && window.alpha > 0.01) {
            return window;
        }
    }

    if (app.keyWindow && !app.keyWindow.hidden) return app.keyWindow;

    for (UIWindow *window in app.windows) {
        if (!window.hidden && window.alpha > 0.01) return window;
    }

    return nil;
}

static void QNPInstall(void) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            QNPInstall();
        });
        return;
    }

    UIWindow *window = QNPFindWindow();
    if (!window) return;

    if (QNPOverlay && QNPWindow == window && QNPOverlay.superview == window) {
        return;
    }

    [QNPOverlay removeFromSuperview];

    QNPOverlay = [[QNOverlayView alloc] initWithFrame:window.bounds];
    QNPOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [window addSubview:QNPOverlay];
    [window bringSubviewToFront:QNPOverlay];

    QNPWindow = window;
}

__attribute__((constructor))
static void QuickNotesPanelEntry(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        QNPInstall();

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:^(__unused NSNotification *note) {
            QNPInstall();
        }];
    });
}
