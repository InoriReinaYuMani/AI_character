# AI_character

このリポジトリには、iOSアプリ本体の前段として使える **CompanionCore**（Swift Package）を追加しています。

## できること（実装済み）
- 質問イベントを時系列で記録
- 「総質問数」「一緒に過ごした日数」「アクティブ日数」「連続日数」を自動集計
- 質問カテゴリ・感情スコア・攻撃的発話フラグに応じて、親密度/信頼度を更新

## 構成
- `Package.swift`: パッケージ定義
- `Sources/CompanionCore/Models.swift`: イベント/メトリクス/状態モデル
- `Sources/CompanionCore/CompanionService.swift`: 質問入力APIとタイムライン取得
- `Tests/CompanionCoreTests/CompanionCoreTests.swift`: 挙動テスト

## ローカル実行
```bash
swift test
```

## iOSアプリへ組み込むとき
1. Xcode プロジェクトを作成
2. Local Package として本リポジトリを追加
3. `CompanionService` を `ObservableObject` でラップして SwiftUI に接続
4. Chat 送信時に `ask(...)` を呼び、Stats 画面で `metrics` を表示

