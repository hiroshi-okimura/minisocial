# 学習の進捗

## 現在地

- 段階：**第1章 Part 1（Rails の全体像をつかむ）** を 2026-10-02 に開始
- 教材：`docs/chapters/01-rails-and-setup.md`（Part 1 まで作成済み。Part 2 は開始時に追記）
- 次にやること：Part 1 の観察・実験と最初のコミット → Part 2（開発環境の構築）
- 第1章の演習問題は、Part 2 の最後にまとめて出す

### 環境メモ（2026-10-02 確認）

- mise 2026.9.0（Ruby はグローバルで 3.3.5）。mise は Ruby をビルド済みバイナリでインストールする（なければソースからビルド）
- Rails 7.1.5 がインストール済み。MySQL は未インストール（`/etc/my.cnf` もなし）
- Git 2.50.1。user.name / user.email は設定済み、`init.defaultBranch` は未設定
- GitHub CLI 2.93.0 でログイン済み（HTTPS）
- Apple Silicon（arm64）/ macOS 26.6.2 / Xcode Command Line Tools あり

## 完了した章・Part

（まだありません）

## 演習のレビュー記録

（まだありません）

## 理解度メモ

### 「よくわからない」と言った箇所と説明し直した内容

（まだありません）

### 理解できている・深掘りしてよい領域

（まだありません）

## 後の章で復習すべき項目

（まだありません）

## 決定事項

- 2026-10-02：テストは RSpec + FactoryBot + Capybara を使う
- 2026-10-02：認証は Rails 8 のジェネレータを使わずに手書きする
- 2026-10-02：デプロイは扱わない。ゴールはローカル環境で全機能が動き、テストが通ること（Rails の学習に集中するため）。いったん Kamal + Oracle Cloud Always Free に決めたが、同日に方針転換した
- 2026-10-02：CI（GitHub Actions で RSpec を自動実行）は残し、第7章で PR の運用と一緒に導入する
