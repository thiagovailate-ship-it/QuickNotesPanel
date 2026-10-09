# Compilar pelo iPhone usando GitHub Actions

Este fluxo usa o GitHub Actions para compilar a biblioteca em um runner macOS. Você só precisa do Safari para enviar os arquivos e baixar o resultado; a compilação não acontece fisicamente no iPhone.

## 1. Criar um repositório

1. No Safari, entre em https://github.com/new e crie um repositório chamado `QuickNotesPanel`.
2. Para manter o código privado, escolha **Private**. Verifique os limites de minutos gratuitos para runners macOS na sua conta antes de executar o workflow; os limites variam conforme o plano e a configuração do GitHub.
3. Descompacte `QuickNotesPanel-source.zip` no app Arquivos, se ainda não fez isso.
4. Envie o conteúdo da pasta `QuickNotesPanel` para a raiz do repositório. É importante incluir a pasta oculta `.github/workflows/build.yml`. Se o upload web não mostrar arquivos ocultos, crie `.github/workflows/build.yml` manualmente no site do GitHub e copie o conteúdo do arquivo fornecido.

Estrutura esperada na raiz do repositório depois de enviar o conteúdo da pasta `QuickNotesPanel`:

```text
.github/workflows/build.yml
Makefile
Tweak.xm
build.sh
README.md
README-GITHUB.md
```

## 2. Executar a compilação

1. Abra o repositório no Safari.
2. Entre na aba **Actions**.
3. Se o GitHub pedir, confirme **I understand my workflows, go ahead and enable them**.
4. Escolha **Build QuickNotesPanel dylib** na lista de workflows.
5. Toque em **Run workflow** e confirme.
6. Abra a execução recém-criada e espere ficar verde. Se falhar, abra o job `build` e veja o primeiro erro em vermelho antes de tentar novamente.

O workflow também roda em `push` para `main` ou `master` quando arquivos do projeto mudam.

## 3. Baixar o artefato

Na página da execução concluída, desça até **Artifacts** e toque em `QuickNotesPanel-dylib`. O ZIP baixado contém `QuickNotesPanel.dylib`.

## 4. Importar no LiveContainer

1. Descompacte o artefato no app Arquivos.
2. No LiveContainer, abra o gerenciador de tweaks e importe `QuickNotesPanel.dylib` para o aplicativo de teste desejado.
3. Force o encerramento e abra novamente o app-alvo.
4. Se a interface não aparecer, não conclua imediatamente que a compilação falhou: confira os logs do LiveContainer/TweakLoader e a compatibilidade da versão do app-alvo. Nem todo aplicativo ou configuração de injeção é compatível.

## Limitações

- O workflow compila a biblioteca, mas não consegue garantir que ela funcione em todos os aplicativos. A execução real precisa ser testada no LiveContainer.
- Não inclua certificados, senhas ou tokens pessoais no repositório.
- O GitHub Actions pode exigir que você habilite workflows para o repositório e pode impor limites de uso, especialmente para runners macOS.
