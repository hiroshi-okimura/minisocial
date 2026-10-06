# MiniSocial で学ぶ Ruby on Rails — カリキュラム

> ステータス：**レビュー待ち（初版）**
> 作成日：2026-10-02

---

## 1. このチュートリアルで完成させるアプリ

### MiniSocial — 小規模 SNS

ユーザーが登録・ログインし、短い投稿（テキスト＋画像）を公開し、他のユーザーをフォローしてタイムラインを見る、という小さな SNS です。

SNS を題材にするのは、Rails の重要な機能を「必要だから使う」という自然な流れで一通り学べるからです。

| 作りたいもの | そこで必然的に学ぶ Rails の仕組み |
|---|---|
| ユーザー登録 | Model / Migration / Validation / フォーム / REST |
| ログイン状態を保つ | Session / Cookie / パスワードのハッシュ化 |
| 「自分のプロフィールだけ編集できる」 | before_action / Authorization |
| 本人確認メール・パスワード再設定 | Action Mailer / Active Job / 有効期限付きトークン |
| 投稿 | has_many / belongs_to / 外部キー |
| フォロー | 自己参照の多対多（has_many :through） / JOIN |
| タイムライン | 複雑なクエリ / サブクエリ / INDEX / N+1 問題 |
| 画像付き投稿 | Active Storage |
| 画面遷移なしの操作 | Hotwire（Turbo / Stimulus） |

### 最終的な機能一覧と対応章

| 機能 | 章 |
|---|---|
| ユーザー登録 | 第10章 |
| ログイン / ログアウト | 第11章・第12章 |
| プロフィール表示・編集 | 第10章・第13章 |
| ユーザー一覧・ページネーション | 第13章 |
| 権限制御（本人のみ編集・管理者のみ削除） | 第13章 |
| メール認証（アカウント有効化） | 第14章 |
| パスワードリセット | 第15章 |
| 投稿の作成・編集・削除・一覧 | 第16章・第17章 |
| 画像アップロード | 第18章 |
| フォロー / フォロー解除 | 第19章 |
| タイムライン | 第19章 |
| テスト（Model / Request / System spec） | 第2章以降すべての章 |
| ~~本番環境へのデプロイ~~ | 扱わない（下記「学習のための方針」を参照） |

---

## 2. 使用技術

バージョンは **2026-10-02 時点** で確認したものです。章を始めるときに改めて確認し、変わっていればその章の教材に明記します。

| 技術 | 採用バージョン | 備考 |
|---|---|---|
| Ruby | **3.4.x**（このリポジトリでは 3.4.10 を `mise.toml` で固定） | 現在の安定版の1つ（2026-10-05 決定）。最新の 4.0 系ではなく、gem の互換性問題に当たりにくい 3.4 系を選んだ |
| Ruby on Rails | **8.1.x**（確認時点の最新は 8.1.4） | Ruby 3.2 以上が必要 |
| MySQL | **8.4 LTS**（確認時点の最新は 8.4.11） | 長期サポート版。MySQL 8.0 は 2026年4月に EOL |
| MySQL 接続アダプタ | trilogy または mysql2 | Rails 8 の `rails new -d mysql` が生成する Gemfile に従う（第2章で確認） |
| RSpec | rspec-rails 8.0.x | |
| FactoryBot | factory_bot_rails 6.5.x | |
| Capybara | 3.40.x | System spec で使用 |
| Hotwire | turbo-rails 2.0.x / stimulus-rails 1.3.x | Rails 8 では標準で組み込まれる |
| アセット | Propshaft + importmap | Rails 8 の標準構成（Node.js のビルドは不要） |
| 画像処理 | Active Storage + image_processing（libvips） | 第18章 |
| バックグラウンドジョブ | Active Job + Solid Queue | Rails 8 の標準。第14章でメール送信に使う |
| CI | GitHub Actions | プッシュや Pull Request のたびに RSpec を自動実行する（第7章） |
| 開発用メール確認 | Action Mailer のプレビュー機能 ＋ letter_opener 系の gem | 実際には送信せず、ブラウザでメールを確認する（第14章で選定） |

### あなたのローカル環境との差分（2026-10-02 時点）

| | 現在 | 必要な対応 |
|---|---|---|
| Ruby | 3.3.5（mise で管理） | 3.4.10 をインストールし、`mise.toml` でこのリポジトリに固定（2026-10-05 対応済み） |
| Rails | 7.1.5 | 8.1.x をインストール |
| MySQL | 未インストール | Homebrew で `mysql@8.4` をインストール（`mysql` という formula は 26.7.0 で、8.4 LTS とは別の系列なので注意） |

いずれも第1章で手順を説明します。

### 学習のための方針

- **認証は手書きする**：Rails 8 には認証ジェネレータ（`bin/rails generate authentication`）がありますが、Session・Cookie・パスワードのハッシュ化の仕組みを理解するため、自分で実装します。第13章の「実務ではどう使われるか」で、ジェネレータが生成するコードと比較します
- **トークンは「手書き → Rails の機能」の順に学ぶ**：永続ログイン（第12章）ではトークンとダイジェストを自分で実装して仕組みを理解します。メール認証とパスワードリセット（第14・15章）では、Rails 7.1 以降の `generates_token_for` を使い、内部で何をしているかを第12章の実装と比べて説明します
- **ページネーションも同じ順で学ぶ**：まず `limit` / `offset` で手書きし、SQL として何が起きているかを理解してから gem に置き換えます
- **デプロイは扱わない（2026-10-02 決定）**：Rails の学習に集中するため、ゴールは「ローカル環境で全機能が動き、テストが通ること」とします。メールはローカルでブラウザから確認し、画像はローカルディスクに保存します。本番環境に関わる知識（環境ごとの設定、credentials、本番でのメール送信・ファイル保存の違い）は、該当する章の「実務ではどう使われるか」と「発展知識」で概要を紹介するにとどめます

---

## 3. 全体カリキュラム（20章）

5つの部に分けています。Part 数は目安で、1 Part は1〜2時間程度です。

### 第I部 Rails の全体像をつかむ

| 章 | タイトル | MiniSocial の到達点 | Part |
|---|---|---|---|
| 1 | Rails とは何か・開発環境を整える | Ruby / Rails / MySQL / Git が動く状態 | 1〜2 |
| 2 | 最初の Rails アプリ・RSpec・Git | `rails new` し、RSpec を導入、GitHub に初プッシュ | 2 |
| 3 | scaffold で見る MVC とリクエストの一生 | 使い捨てブランチで scaffold を作り、読んで、捨てる | 2 |
| 4 | 静的ページ・Routing・はじめての Request spec | トップ / About / Help ページ（テスト駆動で作る） | 2 |
| 5 | Rails を読み書きするための Ruby | （コードは増えない。console で Ruby を学ぶ） | 2 |
| 6 | レイアウト・ビュー・アセット | 共通ヘッダー・フッター・CSS・ナビゲーション | 2〜3 |
| 7 | GitHub での開発フロー —— Pull Request と CI | feature ブランチ → PR → CI（RSpec の自動実行）→ マージの流れが回る | 1〜2 |

### 第II部 ユーザーと認証

| 章 | タイトル | MiniSocial の到達点 | Part |
|---|---|---|---|
| 8 | データベースと Active Record | users テーブルと User モデル | 2〜3 |
| 9 | バリデーションとパスワード | 入力チェック・一意性・`has_secure_password` | 2 |
| 10 | ユーザー登録 —— REST とフォーム | 登録フォーム・プロフィールページ | 3 |
| 11 | ログイン・ログアウト —— Session | ログイン・ログアウト・ログイン状態の表示 | 2 |
| 12 | 永続ログイン —— Cookie | 「ログイン状態を保持する」チェックボックス | 2 |
| 13 | ユーザー管理と権限制御 | プロフィール編集・ユーザー一覧・ページネーション・管理者による削除 | 3 |

### 第III部 メールとアカウントの保護

| 章 | タイトル | MiniSocial の到達点 | Part |
|---|---|---|---|
| 14 | メール送信とアカウント有効化 | 登録後に有効化メールが届き、リンクを踏むと有効になる | 3 |
| 15 | パスワードリセット | 「パスワードを忘れた方」からの再設定 | 2 |

### 第IV部 ソーシャル機能

| 章 | タイトル | MiniSocial の到達点 | Part |
|---|---|---|---|
| 16 | 投稿機能と Association | 投稿の作成・削除・プロフィールでの一覧 | 3 |
| 17 | Hotwire で投稿体験を改善する | ページ遷移なしの投稿・編集・削除、文字数カウンター | 2〜3 |
| 18 | 画像アップロード —— Active Storage | 画像付き投稿・リサイズ | 2 |
| 19 | フォローとタイムライン | フォロー / フォロー解除・フォロー中のユーザーの投稿が並ぶタイムライン | 3 |

### 第V部 実務へ

| 章 | タイトル | MiniSocial の到達点 | Part |
|---|---|---|---|
| 20 | セキュリティ・パフォーマンス・テスト戦略の総まとめ | 脆弱性チェック・N+1 の解消・INDEX の見直し・テストの見直し | 3 |

### Git 運用の段階的な導入

| 時期 | Git / GitHub |
|---|---|
| 第2〜6章 | main ブランチに直接コミット。章の完了時に `chapter-NN` タグ |
| 第7章 | feature ブランチ・Pull Request・CI を導入 |
| 第8章以降 | 機能ごとに feature ブランチを切り、PR で CI が通ったことを確認してからマージ |
| 第20章 | RuboCop・Brakeman などのチェックを CI に追加 |

---

## 4. 各章で身につくスキル

### 第1章 Rails とは何か・開発環境を整える
- Rails の設計思想（設定より規約 / DRY / 全部入りのフレームワーク）と、それが学習・実務にどう効いてくるか
- 1つのリクエストが「Browser → Router → Controller → Model → DB → View → Browser」と流れる全体像（以降の全章で使う地図）
- mise による Ruby のバージョン管理、Homebrew での MySQL 8.4 のインストールと起動、Git の初期設定

### 第2章 最初の Rails アプリ・RSpec・Git
- `rails new` のオプション（`-d mysql`、テストを生成しない設定）と、生成されるディレクトリ構成の意味
- `config/database.yml` と、Rails が MySQL に接続する仕組み。`bin/rails db:create` で何が起きるか
- Minitest を外して RSpec を導入する手順。`rails_helper.rb` と `spec_helper.rb` の役割
- Git の基本操作、コミットの単位、GitHub へのプッシュ

### 第3章 scaffold で見る MVC とリクエストの一生
- scaffold が生成する Model / Migration / Controller / View / Routes を1ファイルずつ読む
- `resources` が生成する7つのルーティングと、REST・HTTP メソッド・URL・アクションの対応
- サーバーログでリクエストを追い、SQL がいつ発行されるかを観察する
- scaffold を「実務で使わない理由」と「使ってもよい場面」

### 第4章 静的ページ・Routing・はじめての Request spec
- `routes.rb` の書き方（`root`、`get`、名前付きルート、`_path` と `_url`）
- Controller のアクションと、暗黙のレンダリング（規約によるテンプレート探索）
- Red → Green → Refactor のテスト駆動開発
- RSpec の DSL（`describe` / `it` / `expect`）が Ruby のブロックとしてどう動くか
- Routing Error / テンプレートが見つからないエラーの読み方

### 第5章 Rails を読み書きするための Ruby
- 文字列・シンボル・配列・ハッシュ・ブロック・範囲
- クラス・継承・モジュール・`attr_accessor`
- 「Rails のコードに出てくる謎の書き方」の正体（括弧の省略、末尾のハッシュの `{}` の省略、`?` / `!` で終わるメソッド、`&:` 記法）
- `rails console` を電卓・実験場として使う習慣

### 第6章 レイアウト・ビュー・アセット
- ERB、レイアウト（`application.html.erb`）、`yield`、パーシャル、`provide` / `content_for`
- ヘルパーメソッド（`link_to` など）と、自作ヘルパーの書き方
- Propshaft と importmap の役割（Rails 8 で何が変わったか、Node.js を使わない理由）
- CSS の組み立て方とレスポンシブ対応
- System spec 入門（Capybara でリンクをクリックして画面遷移を確認する）

### 第7章 GitHub での開発フロー —— Pull Request と CI
- feature ブランチを切って作業し、Pull Request を作り、差分を見直してからマージする流れ
- 「main を常に動く状態に保つ」ことが、チーム開発でなぜ重要か
- GitHub Actions の仕組み（ワークフロー・ジョブ・ステップ）と、`.github/workflows/` の YAML の読み方
- CI 上で MySQL を起動し、RSpec を自動実行する設定（`RAILS_ENV=test` とテスト用データベースの準備）
- CI が落ちたときに、ログから原因を特定する方法
- Rails の環境（development / test / production）の違いと、`config/environments/` の役割（本番環境は概要のみ）

### 第8章 データベースと Active Record
- Migration と `schema.rb` の関係、`db:migrate` / `db:rollback` の内部で何が起きるか
- Active Record の操作と SQL の対応（`new` / `save` / `create` → INSERT、`find` / `where` → SELECT、`update` → UPDATE、`destroy` → DELETE）
- MySQL クライアントで、Rails が作ったテーブルを直接確認する
- UNIQUE INDEX の作成と、なぜアプリ側のチェックだけでは不十分か
- Migration Error / `ActiveRecord::RecordNotFound` への対処

### 第9章 バリデーションとパスワード
- `validates` の仕組み、`valid?` / `errors` / `save` と `save!` の違い
- コールバック（`before_save`）によるメールアドレスの正規化
- `has_secure_password` が内部で行っていること（bcrypt によるハッシュ化、`password_digest` カラム、`authenticate`）
- Model spec の書き方、FactoryBot によるテストデータ作成、fixtures との違い
- `let` / `let!` / `before` / `subject` の使い分け

### 第10章 ユーザー登録 —— REST とフォーム
- `resources :users` で生まれるルーティングを使った new / create / show の実装
- `form_with` が生成する HTML と、フォーム送信時の HTTP リクエストの中身
- Strong Parameters（`params.require(...).permit(...)`）と、それがないと何が起きるか（Mass Assignment 攻撃）
- バリデーションエラーの表示、Turbo 環境下でエラー時に `422` を返す理由
- flash メッセージ、POST の後にリダイレクトする理由（PRG パターン）
- Request spec と System spec による登録フローのテスト

### 第11章 ログイン・ログアウト —— Session
- HTTP がステートレスであることと、Session が必要な理由
- Rails の Session の実体（暗号化された Cookie）と、ブラウザの開発者ツールで実際の Cookie を確認する
- SessionsController、ログインフォーム、`current_user` / `logged_in?` ヘルパー
- CSRF 対策（`protect_from_forgery` と authenticity token）の仕組み
- セッション固定攻撃と `reset_session`

### 第12章 永続ログイン —— Cookie
- `cookies` / `cookies.permanent` / `cookies.signed` / `cookies.encrypted` の違い
- 記憶用トークンとそのダイジェスト（パスワードと同じくハッシュ化して保存する理由）
- Cookie が盗まれた場合の脅威と対策、ログアウト時にトークンを無効化する理由
- 複数ブラウザでのログアウトなど、エッジケースのテスト

### 第13章 ユーザー管理と権限制御
- edit / update と、`before_action` による「ログイン必須」「本人のみ」のアクセス制御
- 認証（Authentication）と認可（Authorization）の違い
- フレンドリーフォワーディング（ログイン後に元のページへ戻す）
- `db/seeds.rb` による大量のサンプルデータ作成
- ページネーション：`limit` / `offset` を手書きして SQL を理解し、その後 gem に置き換える
- 管理者フラグと、管理者のみ可能な削除
- Rails 8 の認証ジェネレータとの比較

### 第14章 メール送信とアカウント有効化
- Action Mailer の構成（Mailer クラス・メールのテンプレート・プレビュー）
- `deliver_now` と `deliver_later`、Active Job と Solid Queue によるバックグラウンド処理
- `generates_token_for` による有効化トークンと、その内部（署名付きメッセージ）を第12章の手書き実装と比べる
- 有効化されていないユーザーのログインを制限する
- Mailer spec と、メール本文中のリンクを踏む System spec
- ローカルでメールをブラウザから確認する方法（メールプレビューと、送信内容を保存して表示する gem）
- 本番環境でのメール送信との違い（外部の送信サービス、SPF / DKIM などの概要。実際の設定は扱わない）

### 第15章 パスワードリセット
- 有効期限付きトークンと、パスワード変更後にトークンが無効になる仕組み
- 「そのメールアドレスは登録されていません」と表示してはいけない理由（ユーザー列挙攻撃）
- 異常系（期限切れ・不正なトークン・空のパスワード）のテスト

### 第16章 投稿機能と Association
- Post モデル、`belongs_to` / `has_many` と、それぞれが追加するメソッド
- 外部キー制約、`references` マイグレーション、`dependent: :destroy`
- `user.posts.build` が内部で行っていること、関連を通した作成と権限チェックの関係
- `default_scope` を避けて scope を使う理由、並び順と INDEX
- 他人の投稿を削除できないことを確認するテスト

### 第17章 Hotwire で投稿体験を改善する
- Turbo Drive がページ遷移を速くする仕組み（すでに第6章から効いていたもの）
- Turbo Frames による部分的な編集フォーム
- Turbo Streams による投稿の追加・削除の即時反映
- Stimulus による文字数カウンター（JavaScript を書く場所と、HTML との結びつけ方）
- Hotwire を使った画面の System spec（JavaScript を実行するドライバ）

### 第18章 画像アップロード —— Active Storage
- Active Storage のテーブル構成（attachments / blobs）と、ファイル本体が保存される場所
- `has_one_attached`、ファイル形式・サイズのバリデーション
- variant による画像のリサイズ（libvips）
- `config/storage.yml` の保存先の切り替えと、実務の本番環境でクラウドストレージ（S3 など）を使う理由（概要のみ）

### 第19章 フォローとタイムライン
- Relationship モデルによる自己参照の多対多（`has_many :through`、`source:`、`class_name:`、`foreign_key:`）
- フォローボタン（Turbo Streams でボタンとフォロワー数を更新）
- タイムラインのクエリ：JOIN とサブクエリ、発行される SQL を読む
- 複合 UNIQUE INDEX と、二重フォローを防ぐ仕組み
- N+1 問題の発見（ログで観察する）と `includes` による解消

### 第20章 セキュリティ・パフォーマンス・テスト戦略の総まとめ
- これまでの章で講じてきたセキュリティ対策の総点検（XSS / CSRF / SQL インジェクション / Mass Assignment / 認可漏れ）
- Brakeman による静的解析、bundler-audit による依存 gem の脆弱性確認
- `EXPLAIN` による実行計画の確認と INDEX の見直し、キャッシュの基本
- テスト戦略：Model / Request / System spec をどう使い分けるか、何をテストし何をテストしないか
- RuboCop によるコードスタイルの統一と CI への組み込み
- 実務での Rails 開発の流れ（Issue → ブランチ → PR → レビュー → マージ → デプロイ）
- 発展知識：本番環境へのデプロイで必要になること（Rails 8 標準の Kamal、credentials、本番データベース、アセットのプリコンパイル）の全体像

---

## 5. 最終的に到達できるレベル

このカリキュラムを終えると、次のことができる状態を目指します。

### 設計
- 作りたい機能を「どのリソースを、どの HTTP メソッド・URL・アクションで扱うか」に分解できる
- 要件から、テーブル・カラム・INDEX・外部キー・Association を設計できる
- 認証と認可の境界を意識して、アクセス制御を設計できる

### 実装
- Rails の規約に沿って、ユーザー認証のある CRUD アプリをゼロから作れる
- Active Record のコードを見て、発行される SQL を想像できる（逆に、SQL から Active Record のコードを書ける）
- Hotwire を使って、JavaScript を最小限にしたインタラクティブな画面を作れる

### 品質と運用
- Model / Request / System spec を使い分け、開発と並行してテストを書ける
- エラーメッセージ・ログ・Rails console を使って、自力で原因を突き止められる
- 代表的な脆弱性を理解し、Rails がどこまで防いでくれて、どこからが自分の責任かを説明できる
- GitHub でのブランチ運用・PR・CI を使って、チームと同じ流れで開発を進められる

### 到達レベルの目安
Rails を使う開発チームに参加して、既存コードを読み、小〜中規模の機能を一人で設計・実装・テストし、PR を出せるレベルです。Rails 内部のさらに深い部分（Rack・ミドルウェア・Active Record の実装詳細）や、大規模運用の知識（シャーディング・複雑なキャッシュ戦略）は、このチュートリアルの「発展知識」で入口を示すにとどめます。

---

## 未決事項（レビュー時に決めたいこと）

| 項目 | 決める時期 | 選択肢と論点 |
|---|---|---|
| CSS の方針 | 第6章の前 | **素の CSS**（CSS の基礎から学べる。おすすめ）／ Tailwind CSS（tailwindcss-rails）／ Bootstrap |
| ページネーションの gem | 第13章 | pagy（活発に更新されている）／ kaminari（定番だが更新が止まっている） |

---

## 情報源

- [CLAUDE.md](../CLAUDE.md)（教材方針・章立ての例・必要な機能一覧）
- Ruby の安定版：[Download Ruby — ruby-lang.org](https://www.ruby-lang.org/en/downloads/)（2026-10-02 確認：4.0.7 / 3.4.11 が安定版）
- 各 gem の最新版：RubyGems.org API（`https://rubygems.org/api/v1/gems/<name>.json`、2026-10-02 確認）
  - rails 8.1.4 / rspec-rails 8.0.4 / factory_bot_rails 6.5.1 / capybara 3.40.0 / turbo-rails 2.0.23 / stimulus-rails 1.3.4 / trilogy 2.13.0 / mysql2 0.5.7 / pagy 43.6.3 / kaminari 1.2.2
  - Rails 8.1.4 の Ruby 要件（`>= 3.2.0`）：RubyGems.org API v2
- MySQL 8.4 LTS の最新版とサポート期間：[MySQL — endoflife.date](https://endoflife.date/mysql)、[MySQL July 2026 GA Releases Now Available](https://blogs.oracle.com/mysql/mysql-july-2026-ga-releases-now-available)
- Homebrew の MySQL formula：`brew info mysql@8.4` / `brew info mysql`（2026-10-02 確認：8.4.11 / 26.7.0）
- ローカル環境：`ruby -v`、`rails -v`、`which mysql`（2026-10-02 確認）
- GitHub Actions の料金：[GitHub Actions pricing in 2026 — sengi.run](https://sengi.run/blog/github-actions-pricing)（公開リポジトリは無料・無制限、非公開は Free プランで月 2,000 分。2026-10-02 確認）
