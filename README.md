# AI_character

このリポジトリには、iOSアプリ本体の前段として使える Swift Package を実装しています。
- `CompanionCore`: 質問履歴・関係性スコア・統計・永続化
- `CompanionFeature`: プロフィール編集・会話フロー・関係性ステージ
- `CompanionCLI`: 上記をまとめて試せるCLI
- `CompanionDemoApp`: SwiftUIの画面実装をそのまま起動するデモApp

## できること（実装済み）
- 質問イベントを時系列で記録
- 「総質問数」「一緒に過ごした日数」「アクティブ日数」「連続日数」を自動集計
- 質問カテゴリ・感情スコア・攻撃的発話フラグに応じて、親密度/信頼度を更新
- キーワード履歴検索とダッシュボード集計取得
- JSONファイルへの状態保存/読込（`JSONCompanionStateStore`）
- AIプロフィール（名前/話し方/テーマ色/性格タグ）編集
- 関係性ステージ文言（まだぎこちない / 仲良し / とても親しい）
- SwiftUI 5画面（Onboarding/Chat/History/Stats/Customize）

## 構成
- `Package.swift`: パッケージ定義（Core + Feature + CLI + DemoApp）
- `Sources/CompanionCore/*`: コアドメイン
- `Sources/CompanionFeature/CompanionFeature.swift`: アプリ向けユースケース
- `Sources/CompanionFeature/CompanionSwiftUI.swift`: SwiftUI画面実装（Chat/History/Stats/Customize）
- `Sources/CompanionCLI/main.swift`: CLIデモ
- `Sources/CompanionDemoApp/CompanionDemoApp.swift`: SwiftUIデモアプリのエントリ
- `Tests/CompanionCoreTests/CompanionCoreTests.swift`: テスト
- `UI_MOCKUP_JA.md`: 画面モック（Onboarding/Chat/History/Stats/Customize）

## ローカル実行
```bash
swift test
swift run CompanionCLI
swift run CompanionDemoApp
```

## CLIの使い方
- `profile <name> <speechStyle>`
- `ask <category> <sentiment> <message>`
- `stats`
- `history <keyword(任意)>`
- `quit`

例:
```text
profile Mina gentle
ask emotionalConsultation 0.7 最近つらいです、相談してもいい？
stats
history 相談
quit
```

## iOSアプリへ組み込むとき
1. Xcode プロジェクトを作成
2. Local Package として本リポジトリを追加
3. `CompanionCoordinator` を `ObservableObject` でラップして SwiftUI に接続
4. `CompanionRootView` をアプリのルートに配置（初回はOnboarding）
5. Chatで `ask(...)`、Statsで `stats(...)`、Historyで `history(...)` を表示
6. `JSONCompanionStateStore` でバックグラウンド時に保存・起動時に復元

