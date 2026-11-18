# Contributing to KidoPalette

Thank you for your contribution. This document outlines the development process for this public repository.

## Branching Strategy (GitHub Flow)

- Perform work on short-lived branches created from `main`.
- Branch name examples: `feat/hot-corner`, `fix/drop-target`, `docs/readme`.
- Merge changes into `main` via a Pull Request (PR).
- You may delete the working branch after merging.
- The same applies to hotfixes (`main` → short `fix/...` branch → PR → tag if necessary).

Long-lived branches such as `develop` or `release/*` are not used.

## Preparation

1. Fork or clone the repository.
2. Install Xcode (see requirements in [README.md](README.md)).
3. Copy `Configs/Local.xcconfig.example` to `Configs/Local.xcconfig`, set your `DEVELOPMENT_TEAM`, and keep `Local.xcconfig` uncommitted.
4. Open `KidoPalette.xcodeproj` in Xcode.
5. Edit in-app help sources in [`docs/Help.md`](docs/Help.md) / [`docs/Help.ja.md`](docs/Help.ja.md), then run `./Scripts/generate-help-rtf.sh` and commit the updated `KidoPalette/Help.rtf` / `Help.ja.rtf`.

## Development Workflow

1. Fetch the latest `main`.
2. Create a working branch.
3. Make changes (following the coding guidelines below).
4. Run tests.
5. Submit a PR (briefly describe the purpose and verification method).

### Testing

Run at least the relevant tests based on the changes made.

```bash
# App unit tests
xcodebuild -scheme KidoPalette -destination 'platform=macOS' -only-testing:KidoPaletteTests test

# Full test suite (may take time)
xcodebuild -scheme KidoPalette -destination 'platform=macOS' test
```

### Commit Messages

Please write them in English using the following format:

```
Prefix: Main message
- Supplementary point 1
- Supplementary point 2
```

Prefixes:

| Prefix | Usage |
|--------|-------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `spec:` | Specification change to an existing feature (not a bug fix) |
| `docs:` | Documentation only |
| `style:` | Formatting changes that do not affect logic |
| `refactor:` | Code restructuring (excluding new features or bug fixes) |
| `perf:` | Performance improvement |
| `test:` | Adding or modifying tests |
| `chore:` | Build, tooling, or miscellaneous tasks |

- Keep the main message (including the prefix) to approximately 50 characters or less.
- Do not end the message with a period.

### Coding Guidelines (Key Points)

- **Write tests first for new features** (or include tests in the PR).
- Do not implement special-case code just to make specific tests pass; implement according to the specifications.
- If a test fails, do not simply loosen the test to match the implementation; explain your interpretation of the specifications in the PR.
- Do not include personal `DEVELOPMENT_TEAM` settings (including `Configs/Local.xcconfig`), certificates, API keys, or personal passwords in changes intended for public release.
- Prefer managing the Team ID in `Configs/Local.xcconfig` instead of Xcode’s Signing UI, so it is not written back into `project.pbxproj`.

## Pull Requests

- Keep the scope focused.
- Describe what changed and how you verified it.
- Link related issues when applicable.

## License

By contributing, you agree that your contributions are licensed under the same terms as the project ([MIT](LICENSE)).

---

# KidoPalette への貢献

ご貢献ありがとうございます。この公開リポジトリの開発プロセスをまとめます。

## ブランチ戦略（GitHub Flow）

- `main` から短命ブランチを切って作業します。
- ブランチ名の例: `feat/hot-corner`, `fix/drop-target`, `docs/readme`
- Pull Request（PR）で `main` にマージします。
- マージ後に作業ブランチを削除して構いません。
- ホットフィックスも同様です（`main` → 短い `fix/...` → PR → 必要ならタグ）。

`develop` や `release/*` のような長寿命ブランチは使いません。

## 準備

1. リポジトリを fork または clone します。
2. Xcode を用意します（[README.md](README.md) の動作環境を参照）。
3. `Configs/Local.xcconfig.example` を `Configs/Local.xcconfig` にコピーし、`DEVELOPMENT_TEAM` を設定します（`Local.xcconfig` はコミットしない）。
4. `KidoPalette.xcodeproj` を Xcode で開きます。
5. ユーザー向けヘルプを直す場合は [`docs/Help.md`](docs/Help.md) / [`docs/Help.ja.md`](docs/Help.ja.md) を編集し、`./Scripts/generate-help-rtf.sh` で `KidoPalette/Help.rtf` / `Help.ja.rtf` を再生成してコミットします。
6. EULA を直す場合は [`docs/EULA.md`](docs/EULA.md) を編集し、`./Scripts/generate-eula-rtf.sh` で `KidoPalette/Credits.rtf` を再生成してコミットします（About がこの RTF を表示します）。

## 開発の流れ

1. 最新の `main` を取得します。
2. 作業ブランチを作ります。
3. 変更します（下記のコーディング方針に従う）。
4. テストを実行します。
5. PR を出します（目的と確認方法を短く書く）。

### テスト

変更内容に応じて、少なくとも関連テストを実行してください。

```bash
# アプリ本体のユニットテスト
xcodebuild -scheme KidoPalette -destination 'platform=macOS' -only-testing:KidoPaletteTests test

# 全テスト（時間がかかることがあります）
xcodebuild -scheme KidoPalette -destination 'platform=macOS' test
```

### コミットメッセージ

英語で、次の形式にしてください。

```
Prefix: Main message
- Supplementary point 1
- Supplementary point 2
```

プレフィクスは上表のとおりです。主メッセージ（プレフィクス込み）はおおよそ 50 文字以内、文末にピリオドは付けません。

### コーディング方針（要点）

- **新機能はテストを先に書く**（または PR にテストを含める）。
- 特定のテストだけ通すための特例実装はしない。仕様に沿って実装する。
- テストが落ちても、実装に合わせてテストを緩めるだけでは不十分。仕様の解釈を PR で説明する。
- 個人の `DEVELOPMENT_TEAM`（`Configs/Local.xcconfig` を含む）、証明書、API キー、パスワードを公開向けの変更に含めない。
- Team ID は Xcode の Signing UI より `Configs/Local.xcconfig` で管理し、`project.pbxproj` への書き戻しを避ける。

## Pull Request

- スコープを絞る。
- 何を変えたか、どう確認したかを書く。
- 関連 Issue があればリンクする。

## ライセンス

貢献により、あなたの変更がプロジェクトと同じ条件（[MIT](LICENSE)）でライセンスされることに同意したものとします。
