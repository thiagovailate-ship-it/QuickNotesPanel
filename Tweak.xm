#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// QuickNotesPanel — a small, self-contained UI tweak for LiveContainer.
// It adds a floating button to the current app and stores notes in that app's
// NSUserDefaults domain. No private frameworks or Logos hooks are required.

static NSString * const QNDefaultsKey = @"dev.quicknotespanel.note.v1";

@interface QNOverlayView : UIView <UITextViewDelegate>
@property (nonatomic, strong) UIButton *launcher;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation QNOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // The card is added first so the floating launcher stays above it.
    _panel = [[UIView alloc] initWithFrame:CGRectZero];
    _panel.backgroundColor = [UIColor colorWithRed:0.985 green:0.989 blue:1.0 alpha:1.0];
    _panel.layer.cornerRadius = 18.0;
    _panel.layer.borderWidth = 1.0;
    _panel.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
    _panel.layer.shadowColor = [UIColor blackColor].CGColor;
    _panel.layer.shadowOpacity = 0.18;
    _panel.layer.shadowRadius = 16.0;
    _panel.layer.shadowOffset = CGSizeMake(0, 6);
    _panel.hidden = YES;
    [self addSubview:_panel];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = @"Notas rápidas";
    _titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    _titleLabel.textColor = [UIColor colorWithRed:0.10 green:0.13 blue:0.20 alpha:1.0];
    [_panel addSubview:_titleLabel];

    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_closeButton setTitle:@"×" forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightRegular];
    [_closeButton setTitleColor:[UIColor colorWithWhite:0.35 alpha:1.0] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    _closeButton.accessibilityLabel = @"Fechar notas";
    [_panel addSubview:_closeButton];

    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.font = [UIFont systemFontOfSize:15.0];
    _textView.textColor = [UIColor colorWithRed:0.12 green:0.15 blue:0.22 alpha:1.0];
    _textView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    _textView.layer.cornerRadius = 11.0;
    _textView.layer.borderWidth = 1.0;
    _textView.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1.0].CGColor;
    _textView.textContainerInset = UIEdgeInsetsMake(10, 8, 10, 8);
    _textView.delegate = self;
    _textView.alwaysBounceVertical = YES;
    _textView.accessibilityLabel = @"Texto da nota";
    NSString *savedText = [[NSUserDefaults standardUserDefaults] stringForKey:QNDefaultsKey];
    _textView.text = savedText ?: @"";
    [_panel addSubview:_textView];

    _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _placeholderLabel.text = @"Escreva uma nota, lembrete ou link…";
    _placeholderLabel.font = [UIFont systemFontOfSize:15.0];
    _placeholderLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    _placeholderLabel.numberOfLines = 0;
    _placeholderLabel.userInteractionEnabled = NO;
    [_textView addSubview:_placeholderLabel];
    _placeholderLabel.hidden = _textView.text.length > 0;

    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _saveButton.backgroundColor = [UIColor colorWithRed:0.12 green:0.36 blue:0.93 alpha:1.0];
    _saveButton.layer.cornerRadius = 10.0;
    [_saveButton setTitle:@"Salvar nota" forState:UIControlStateNormal];
    [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _saveButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [_saveButton addTarget:self action:@selector(saveNote) forControlEvents:UIControlEventTouchUpInside];
    [_panel addSubview:_saveButton];

    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _clearButton.backgroundColor = [UIColor colorWithWhite:0.91 alpha:1.0];
    _clearButton.layer.cornerRadius = 10.0;
    [_clearButton setTitle:@"Limpar" forState:UIControlStateNormal];
    [_clearButton setTitleColor:[UIColor colorWithWhite:0.20 alpha:1.0] forState:UIControlStateNormal];
    _clearButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    [_clearButton addTarget:self action:@selector(clearNote) forControlEvents:UIControlEventTouchUpInside];
    [_panel addSubview:_clearButton];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.font = [UIFont systemFontOfSize:11.0];
    _statusLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.text = @"Salvo somente neste app";
    [_panel addSubview:_statusLabel];

    _launcher = [UIButton buttonWithType:UIButtonTypeCustom];
    _launcher.backgroundColor = [UIColor colorWithRed:0.12 green:0.36 blue:0.93 alpha:1.0];
    _launcher.layer.cornerRadius = 25.0;
    _launcher.layer.shadowColor = [UIColor blackColor].CGColor;
    _launcher.layer.shadowOpacity = 0.25;
    _launcher.layer.shadowRadius = 9.0;
    _launcher.layer.shadowOffset = CGSizeMake(0, 4);
    [_launcher setTitle:@"N" forState:UIControlStateNormal];
    [_launcher setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _launcher.titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
    _launcher.accessibilityLabel = @"Abrir notas rápidas";
    [_launcher addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_launcher];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    if (width < 80.0 || height < 180.0) return;

    CGFloat panelWidth = MIN(340.0, width - 24.0);
    CGFloat panelHeight = MIN(350.0, MAX(220.0, height - 32.0));
    CGFloat panelX = (width - panelWidth) / 2.0;
    CGFloat panelY = MIN(112.0, MAX(8.0, (height - panelHeight) / 2.0));
    self.panel.frame = CGRectMake(panelX, panelY, panelWidth, panelHeight);

    self.titleLabel.frame = CGRectMake(16.0, 13.0, panelWidth - 72.0, 28.0);
    self.closeButton.frame = CGRectMake(panelWidth - 48.0, 7.0, 38.0, 38.0);

    CGFloat editorY = 51.0;
    CGFloat buttonY = panelHeight - 65.0;
    CGFloat editorHeight = MAX(100.0, buttonY - editorY - 10.0);
    self.textView.frame = CGRectMake(13.0, editorY, panelWidth - 26.0, editorHeight);
    self.placeholderLabel.frame = CGRectMake(5.0, 7.0, self.textView.bounds.size.width - 20.0, 42.0);

    self.saveButton.frame = CGRectMake(13.0, buttonY, panelWidth - 112.0, 38.0);
    self.clearButton.frame = CGRectMake(panelWidth - 87.0, buttonY, 74.0, 38.0);
    self.statusLabel.frame = CGRectMake(12.0, panelHeight - 25.0, panelWidth - 24.0, 16.0);

    self.launcher.frame = CGRectMake(MAX(8.0, width - 64.0), 62.0, 50.0, 50.0);
}

// Do not swallow taps on the host app's content. Only the launcher and the
// visible note card receive touches; taps elsewhere pass through.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    return hit;
}

- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
    if (self.panel.hidden) {
        [self.textView resignFirstResponder];
    } else {
        [self bringSubviewToFront:self.launcher];
        // Let the user choose when to focus the editor and open the keyboard.
    }
}

- (void)closePanel {
    self.panel.hidden = YES;
    [self.textView resignFirstResponder];
}

- (void)saveNote {
    [[NSUserDefaults standardUserDefaults] setObject:(self.textView.text ?: @"") forKey:QNDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.placeholderLabel.hidden = self.textView.text.length > 0;
    self.statusLabel.text = @"✓ Nota salva neste app";
    [self.textView resignFirstResponder];
}

- (void)clearNote {
    self.textView.text = @"";
    self.placeholderLabel.hidden = NO;
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:QNDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.statusLabel.text = @"Nota apagada";
    [self.textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    // Keep the latest note even if the app is closed before the Save button is tapped.
    [[NSUserDefaults standardUserDefaults] setObject:(textView.text ?: @"") forKey:QNDefaultsKey];
    self.statusLabel.text = @"Salvo automaticamente neste app";
}

@end

static UIWindow *QNFindHostWindow(void) {
    UIApplication *app = [UIApplication sharedApplication];
    if (!app) return nil;

    // Prefer the active app window. UIApplication.windows/keyWindow is used
    // deliberately to keep compatibility with older SDK headers.
    for (UIWindow *window in app.windows) {
        if (window.isKeyWindow && !window.hidden && window.alpha > 0.01) {
            return window;
        }
    }
    if (app.keyWindow && !app.keyWindow.hidden) return app.keyWindow;

    // Some apps briefly have no key window during launch; pick a visible normal
    // window and retry if none exists yet.
    for (UIWindow *window in app.windows) {
        if (!window.hidden && window.alpha > 0.01 && window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    }
    return nil;
}

static __weak UIWindow *QNInstalledOnWindow = nil;
static QNOverlayView *QNOverlay = nil;
static NSUInteger QNAttempts = 0;

static void QNInstallOverlay(void) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ QNInstallOverlay(); });
        return;
    }

    UIWindow *hostWindow = QNFindHostWindow();
    if (hostWindow && QNOverlay && QNInstalledOnWindow == hostWindow && QNOverlay.superview == hostWindow) {
        return;
    }

    if (!hostWindow) {
        if (QNAttempts++ < 80) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC / 2)),
                           dispatch_get_main_queue(), ^{ QNInstallOverlay(); });
        }
        return;
    }

    if (QNOverlay) [QNOverlay removeFromSuperview];
    QNOverlay = [[QNOverlayView alloc] initWithFrame:hostWindow.bounds];
    QNOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [hostWindow addSubview:QNOverlay];
    [hostWindow bringSubviewToFront:QNOverlay];
    QNInstalledOnWindow = hostWindow;
}

__attribute__((constructor)) static void QuickNotesPanelEntry(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ QNInstallOverlay(); });
}
