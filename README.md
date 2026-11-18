# KidoPalette

**KidoPalette** is a macOS app launcher. After LaunchPad was removed in macOS 26 Tahoe, it offers a simple, registration-based palette: pick your apps, group them in tabs, and open the launcher from a hot corner.

Screenshots can be added later under `assets/`.

## Features

- Show or hide the launcher from a configurable hot corner (no Accessibility permission)
- Optional full-screen launcher presentation (borderless, above the menu bar and Dock)
- Tabs for grouping apps; move apps between tabs; register the same app in multiple tabs
- Manual registration via Open Panel or drag-and-drop from Finder
- Drag to reorder apps and tabs
- Optional Dock icon (Settings)
- UI languages: English and Japanese

## Requirements

- macOS 26.5 or later
- Xcode (open `KidoPalette.xcodeproj` directly; XcodeGen is not used)

## Structure

```text
KidoPalette/              # App sources
KidoPaletteTests/         # Unit tests (@testable import KidoPalette)
KidoPaletteUITests/       # XCUITest
Configs/                  # Shared.xcconfig + Local.xcconfig.example
docs/                     # Help / EULA markdown
Scripts/                  # pandoc helpers (Credits.rtf / Help RTF)
```

## Setup

```bash
# Once: set your Apple Developer Team ID (do not commit Local.xcconfig)
cp Configs/Local.xcconfig.example Configs/Local.xcconfig
# Edit Configs/Local.xcconfig and set DEVELOPMENT_TEAM

open KidoPalette.xcodeproj
```

Manage the Team ID only in `Configs/Local.xcconfig`. Avoid changing the Team in Xcode’s Signing & Capabilities UI, or Xcode may write `DEVELOPMENT_TEAM` back into `project.pbxproj`.

```bash
xcodebuild -scheme KidoPalette -configuration Debug build

xcodebuild -scheme KidoPalette -destination 'platform=macOS' -only-testing:KidoPaletteTests test
```

### App Sandbox

Official builds enable **App Sandbox** (`KidoPalette/KidoPalette.entitlements`) with user-selected file read-only access. Registered apps are stored with security-scoped bookmarks so icons and launches keep working after relaunch.

### Docs and Scripts

Markdown help and EULA live under `docs/`. **About KidoPalette** and **KidoPalette Help** open dedicated windows (default 720×780) with scrollable RTF from `KidoPalette/Credits.rtf`, `Help.rtf`, and `Help.ja.rtf`. Builds do **not** require pandoc; regenerate when the sources change:

```bash
./Scripts/generate-eula-rtf.sh
./Scripts/generate-help-rtf.sh
```

Help chooses `Help.ja.rtf` when the preferred language is Japanese, otherwise `Help.rtf`.

## Branches and Releases

We use GitHub Flow.

- Default branch: `main` (kept buildable)
- Changes via short-lived branches and Pull Requests
- Releases via version tags and GitHub Releases

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

- Source code: [MIT](LICENSE)
- App usage: [EULA (End-User License Agreement)](docs/EULA.md)
- Help source: [Help](docs/Help.md) / [ヘルプ](docs/Help.ja.md)

## Links

- Repository: [KidoPalette on GitHub](https://github.com/takenori-kabeya/KidoPalette)
- Issues: [GitHub Issues](https://github.com/takenori-kabeya/KidoPalette/issues)

---

**KidoPalette** は、macOS 向けのアプリランチャーです。macOS 26 Tahoe で LaunchPad が廃止されたあとに、登録制のシンプルなパレットとして使えることを目指しています。

## できること

- ホットコーナーからの表示／非表示（アクセシビリティ権限は不要）
- フルスクリーン表示（ボーダーレス、メニューバー／Dock より手前）
- タブでのグループ分け、タブ間移動、同一アプリの複数タブ登録
- Open Panel または Finder からのドラッグ＆ドロップで登録
- アプリアイコン／タブのドラッグ並べ替え
- Dock アイコンの表示切替（設定）
- UI 言語: 英語／日本語

## 動作環境

- macOS 26.5 以降
- Xcode（`KidoPalette.xcodeproj` を直接開く。XcodeGen は使いません）

## 構成

```text
KidoPalette/              # アプリ本体
KidoPaletteTests/         # ユニットテスト
KidoPaletteUITests/       # XCUITest
Configs/                  # Shared.xcconfig + Local.xcconfig.example
docs/                     # Help / EULA の Markdown
Scripts/                  # pandoc ヘルパー（Credits.rtf / Help RTF）
```

## セットアップ

```bash
# 初回のみ: Apple Developer Team ID を設定（Local.xcconfig はコミットしない）
cp Configs/Local.xcconfig.example Configs/Local.xcconfig
# Configs/Local.xcconfig を編集して DEVELOPMENT_TEAM を設定

open KidoPalette.xcodeproj
```

Team ID は `Configs/Local.xcconfig` だけで管理してください。Xcode の Signing & Capabilities で Team を変えると、`project.pbxproj` に書き戻されることがあります。

```bash
xcodebuild -scheme KidoPalette -configuration Debug build

xcodebuild -scheme KidoPalette -destination 'platform=macOS' -only-testing:KidoPaletteTests test
```

### App Sandbox

公式ビルドは **App Sandbox**（`KidoPalette/KidoPalette.entitlements`）と、ユーザー選択ファイルの読み取り専用を有効にします。登録アプリはセキュリティスコープ付きブックマークとして保存し、再起動後もアイコン表示と起動ができるようにします。

### ドキュメントと Scripts

ヘルプ／EULA の Markdown は `docs/` にあります。**KidoPaletteについて** と **KidoPaletteヘルプ** は専用ウィンドウ（既定 720×780）で、`Credits.rtf` / `Help.rtf` / `Help.ja.rtf` をスクロール表示します。ビルドに pandoc は不要です。原稿を更新したら次で再生成してください:

```bash
./Scripts/generate-eula-rtf.sh
./Scripts/generate-help-rtf.sh
```

優先言語が日本語のときは `Help.ja.rtf`、それ以外は `Help.rtf` を使います。

## ブランチとリリース

GitHub Flow を使います。詳細は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## ライセンス

- ソースコード: [MIT](LICENSE)
- アプリ利用: [EULA](docs/EULA.md)
- ヘルプ原稿: [Help](docs/Help.md) / [ヘルプ](docs/Help.ja.md)

## リンク

- リポジトリ: [KidoPalette on GitHub](https://github.com/takenori-kabeya/KidoPalette)
- Issues: [GitHub Issues](https://github.com/takenori-kabeya/KidoPalette/issues)
