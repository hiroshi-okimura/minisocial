# 第1章 Rails とは何か・開発環境を整える

> 対象バージョン：Ruby 4.0.x / Rails 8.1.x / MySQL 8.4 LTS（2026-10-02 確認）
> Part 1 で使うのは、すでにあなたの Mac に入っている `curl` と Ruby 3.3.5 の `irb` だけです。Ruby 4.0 と Rails 8.1 は Part 2 でインストールします。

---

## これまでの復習

第1章なので、復習する内容はまだありません。次の章からは、ここに「この章で使う、前の章までの知識」をまとめます。

## この章でできるようになること

- Web アプリケーションが「HTTP リクエストを受け取り、HTTP レスポンスを返すプログラム」であることを、実際の通信を見ながら説明できる
- Rails が1つのリクエストを処理する流れ（Browser → Router → Controller → Model → Database → Controller → View → Browser）を、具体例で説明できる
- Rails の設計思想（特に「設定より規約」）が、コードの書き方にどう表れるかを説明できる
- `resources :users` のような Rails 特有の書き方が、Ruby の普通のメソッド呼び出しであることを理解する
- Ruby 4.0 / Rails 8.1 / MySQL 8.4 / Git / GitHub が動く開発環境を構築できる（Part 2）

## 今回作るもの

| Part | 内容 | 成果物 |
|---|---|---|
| Part 1 | Rails の全体像をつかむ | `curl` と `irb` で行う観察と実験。リポジトリの最初のコミット |
| Part 2 | 開発環境を整える | Ruby 4.0 / Rails 8.1 / MySQL 8.4 が動く状態。MySQL に SQL を直接打って、データベースを体験する |

この章では、まだ MiniSocial のコードは書きません。第2章からアプリ作りに入ります。その前に、この章で「地図」と「道具」をそろえます。

## 前提知識

- ターミナルの基本操作（`cd`、`ls`、コマンドの実行）
- HTML がブラウザで表示される仕組みを、大まかに知っていること
- 何らかのプログラミング言語で、変数・関数・条件分岐を書いた経験

---

# Part 1 Rails の全体像をつかむ

## Rails の仕組み

### Web アプリケーションがやっていること

Rails を学ぶ前に、「Web アプリケーションは何をしているのか」を確認します。Rails は、この仕事を分担して整理するための道具だからです。

ブラウザで `https://minisocial.example/users/1` を開くと、次のことが起きます。

```
ブラウザ                                      サーバー（Web アプリ）
   │                                              │
   │  ① HTTP リクエスト                           │
   │  「GET /users/1 をください」                  │
   │ ───────────────────────────────────────────> │
   │                                              │  ② どの処理をするか決める
   │                                              │  ③ データベースから ID=1 のユーザーを取り出す
   │                                              │  ④ そのデータを埋め込んだ HTML を作る
   │  ⑤ HTTP レスポンス                           │
   │  「200 OK。HTML はこれです」                  │
   │ <─────────────────────────────────────────── │
   │                                              │
   ⑥ HTML を画面に描画する
```

Web アプリケーションは、どれほど複雑なものでも、本質的には **「リクエストを受け取り、レスポンスを返す」プログラム** です。ログインも、投稿も、フォローも、すべてこの往復の繰り返しで実現します。

②〜④の部分を自分で一から書くとしたら、次のことをすべて自分で決めて実装する必要があります。

- URL を解析し、どの処理を呼ぶか振り分ける仕組み
- データベースへの接続、SQL の組み立て、結果をプログラムのデータに変換する処理
- HTML のテンプレートにデータを埋め込む仕組み
- フォームの入力値の受け取り、ログイン状態の管理、セキュリティ対策……

Rails は、これらを **役割ごとに部品として用意し、部品同士のつなぎ方を「規約」として決めてある** フレームワークです。

### Rails におけるリクエストの一生

先ほどの ②〜④ を、Rails ではどの部品が担当するかを示したのが次の図です。**これ以降、全章で使う「地図」** なので、何度でもここに戻ってきてください。

```
Browser
  │  GET /users/1
  ▼
Router（config/routes.rb）
  │  「GET /users/:id は UsersController の show アクションへ」と振り分ける
  ▼
Controller（app/controllers/users_controller.rb）
  │  show アクションが動く。「ID=1 のユーザーが必要だ」とモデルに頼む
  ▼
Model（app/models/user.rb） ── Active Record
  │  User.find(1) を SQL に変換する
  ▼
Database（MySQL）
  │  SELECT * FROM users WHERE id = 1 を実行し、行を返す
  ▼
Model
  │  返ってきた行を User オブジェクトに変換する
  ▼
Controller
  │  User オブジェクトを @user という変数に入れ、ビューに渡す
  ▼
View（app/views/users/show.html.erb）
  │  @user の名前などを HTML に埋め込む
  ▼
Browser
     200 OK と HTML を受け取り、画面に描画する
```

この流れを、実際のコードの形で見てみます。**今は打ち込まなくて構いません**。第3章以降で、自分で書けるようになります。ここでは「各部品が、それぞれ短いコードで済んでいる」ことに注目してください。

```ruby
# config/routes.rb —— Router
Rails.application.routes.draw do
  get "/users/:id", to: "users#show"
end
```

```ruby
# app/controllers/users_controller.rb —— Controller
class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end
end
```

```ruby
# app/models/user.rb —— Model
class User < ApplicationRecord
end
```

```erb
<%# app/views/users/show.html.erb —— View %>
<h1><%= @user.name %></h1>
```

いくつか気になる点があるはずです。

- Controller の `show` には「このビューを表示しろ」と書いていないのに、なぜ `show.html.erb` が使われるのか
- `User` クラスの中身は空なのに、なぜ `User.find` が使えて、`users` テーブルからデータを取れるのか
- `params[:id]` の中に、なぜ URL の `1` が入っているのか

これらの答えが、次に説明する **「設定より規約」** です。

### MVC —— なぜ3つに分けるのか

Rails は **MVC（Model / View / Controller）** という考え方でコードを分けます。

| 部品 | 担当すること | たとえるなら（レストラン） |
|---|---|---|
| **Model** | データとそのルール（「メールアドレスは必須」「投稿は140文字まで」など）。データベースとのやりとり | 厨房：食材を管理し、料理を作る |
| **View** | 見た目。データを HTML にする | 盛り付け：料理を皿に美しく載せる |
| **Controller** | 受付と指揮。リクエストを受け、Model に仕事を頼み、結果を View に渡す | ホール係：注文を受け、厨房に伝え、料理を客に運ぶ |
| （Router） | どの Controller のどのアクションに渡すかを決める | 入口の案内係 |

**なぜ分けるのか**。すべてを1つのファイルに書くと、次のような問題が起きるからです。

- 「メールアドレスは必須」というルールが、登録画面と編集画面と API の3か所に散らばる。1か所だけ直し忘れると、バグになる
- デザインを変えたいだけなのに、SQL が混ざったファイルを触ることになる
- テストのとき、「データのルールだけ確かめたい」ということができない

役割ごとに置き場所を決めておけば、**「このルールはどこに書くべきか」「このバグはどこにあるか」の答えが、だいたい1つに決まります**。これが MVC の最大の利点です。

### 設定より規約（Convention over Configuration）

Rails の設計思想の中心にあるのが **「設定より規約」** です。「名前や置き場所のルール（規約）に従えば、設定を書かなくても部品同士が自動的につながる」という考え方です。

先ほどの例で言うと、次の名前がすべて規約でつながっています。

| 何か | 名前 | 規約 |
|---|---|---|
| モデルのクラス | `User` | 単数形・大文字始まり |
| テーブル | `users` | モデル名の複数形・小文字 |
| モデルのファイル | `app/models/user.rb` | クラス名を小文字・スネークケースにしたもの |
| コントローラのクラス | `UsersController` | 複数形 ＋ `Controller` |
| ビューのファイル | `app/views/users/show.html.erb` | `views/コントローラ名/アクション名` |

だから次のことが起きます。

- `User` クラスは何も書かなくても、`users` テーブルを扱うクラスになる
- `UsersController` の `show` アクションが終わると、Rails は自動的に `app/views/users/show.html.erb` を探して表示する

**「設定」の場合と比べる** と、ありがたみがわかります。規約がない場合、次のような対応関係をすべて設定ファイルに書く必要があります。

```
# 架空の設定ファイル（Rails ではこれを書かなくてよい）
User クラス → テーブル名: users
UsersController#show → テンプレート: users/show.html.erb
UsersController#index → テンプレート: users/index.html.erb
...（アクションの数だけ続く）
```

規約に従えば、この設定は1行も要りません。さらに、**Rails を知っている人なら誰でも、初めて見るプロジェクトの「どこに何があるか」がすぐにわかる** という利点があります。実務ではこちらの効果のほうが大きいくらいです。

**他の書き方ではなぜダメなのか**：規約から外れることは可能です（テーブル名を `members` にする設定を書く、など）。ただし外れるたびに設定が増え、Rails の自動化の恩恵が減り、他の人が読みにくくなります。**「迷ったら規約に従う」が Rails の基本姿勢** です。

### Rails の設計思想（Rails Doctrine）

Rails の作者 David Heinemeier Hansson（DHH）は、Rails の設計思想を「Rails Doctrine」として9つの柱にまとめています。全部を覚える必要はありません。この教材に特に関係する4つだけ紹介します。

| 柱 | 意味 | この教材で実感する場面 |
|---|---|---|
| Optimize for programmer happiness | プログラマーが気持ちよく書けることを最優先する | Ruby の読みやすい文法、短いコード |
| Convention over Configuration | 設定より規約 | 全章 |
| The menu is omakase | 必要な部品はフレームワークが選んで最初からそろえておく（「おまかせ」） | Rails 8 では、DB・メール・ジョブ・ファイル保存・Hotwire が最初から入っている |
| Value integrated systems | 1つにまとまったシステム（モノリス）の価値を重視する | MiniSocial は、画面もロジックも1つの Rails アプリで作る |

### Rails を構成する部品

「おまかせ」の中身を見ておきます。Rails は、実は複数のライブラリ（gem）の集まりです。

| 部品 | 役割 | この教材で主に扱う章 |
|---|---|---|
| Action Pack（Action Dispatch / Action Controller） | ルーティング、コントローラ、Session、Cookie | 第3・4・10〜13章 |
| Action View | ビュー（ERB テンプレート、ヘルパー、フォーム） | 第6・10章 |
| Active Record | モデル、データベース操作、バリデーション、関連付け | 第8・9・16・19章 |
| Action Mailer | メール送信 | 第14・15章 |
| Active Job | バックグラウンド処理 | 第14章 |
| Active Storage | ファイルのアップロード | 第18章 |
| Active Support | Ruby の便利な拡張（`"user".pluralize` で `"users"` を返すなど） | 随所 |
| Railties | 部品をまとめ、`rails` コマンドを提供する | 第2章 |
| Turbo / Stimulus（Hotwire） | JavaScript をあまり書かずに、動きのある画面を作る | 第6・10・17章 |

先ほどの「`User` から `users` テーブルを導く」処理は、Active Support の `pluralize`（複数形にする）が担当しています。規約は魔法ではなく、こうした地道な部品で実現されています。

---

## 実装

Part 1 ではアプリのコードは書きません。その代わり、上で学んだことを **自分の手で観察・実験** します。

### Step 1 HTTP リクエストとレスポンスを自分の目で見る

ブラウザが裏でやっている通信を、`curl` コマンドで再現します。`-v` は通信の詳細を表示するオプション、`-o /dev/null` はレスポンス本文（HTML）を捨てて画面を見やすくするオプションです。

```bash
curl -v -o /dev/null https://example.com/
```

出力のうち、行頭が `>` と `<` の行に注目してください。次のような行が見つかるはずです（一部抜粋。日付などは実行時によって異なります）。

```
> GET / HTTP/2
> Host: example.com
> User-Agent: curl/8.7.1
> Accept: */*
>
< HTTP/2 200
< content-type: text/html; charset=utf-8
< allow: GET, HEAD
```

### 解説

- **`>` で始まる行がリクエスト**（あなた → サーバー）、**`<` で始まる行がレスポンス**（サーバー → あなた）です
- `GET / HTTP/2`：リクエストの1行目です。**「HTTP メソッド」「パス」「プロトコル」** の3つでできています
  - **HTTP メソッド**（`GET`）：何をしたいか。`GET` は「取得したい」。他に `POST`（作成）、`PATCH`（更新）、`DELETE`（削除）などがあります。第3章で学ぶ REST は、このメソッドとパスの組み合わせで操作を表す考え方です
  - **パス**（`/`）：どのページ（リソース）が欲しいか
- `Host: example.com` などは **ヘッダー** です。リクエストの付帯情報で、第11章で学ぶ Cookie もヘッダーで送られます
- `HTTP/2 200`：レスポンスの1行目で、**ステータスコード** を表します。`200` は「成功」です
- `content-type: text/html`：「本文は HTML です」という意味です。ブラウザはこれを見て、本文を HTML として描画します

Rails アプリを作るとき、あなたが書くコードの目的は、つまるところ **「このリクエストに対して、どんなステータスコードとどんな本文を返すか」を決めること** です。

### Step 2 ステータスコードの違いを見る

存在しないページと、許可されていないメソッドを試します。`-s` は進捗表示を消すオプション、`-w "%{http_code}\n"` はステータスコードだけを表示するオプション、`-X POST` はメソッドを POST に変えるオプションです。

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://example.com/does-not-exist
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://example.com/
```

それぞれ `404` と `405` が表示されるはずです。

### 解説

- `404 Not Found`：そのパスにはリソースがない
- `405 Method Not Allowed`：そのパスは存在するが、そのメソッドは受け付けない。Step 1 のレスポンスにあった `allow: GET, HEAD` が「GET と HEAD なら受け付ける」という意味だったことと対応しています

この教材で今後よく出てくるステータスコードを、先に一覧にしておきます。

| コード | 意味 | Rails で出会う場面 |
|---|---|---|
| 200 OK | 成功 | ページの表示 |
| 302 Found | 別の URL へ移動してほしい（リダイレクト） | 登録やログインの成功後に、別のページへ移動させる（第10章） |
| 303 See Other | 302 と同様のリダイレクト。次は GET で取りに来てほしいと明示する | 削除後のリダイレクト（第10・13章） |
| 404 Not Found | リソースがない | 存在しない ID のユーザーを表示しようとしたとき |
| 422 Unprocessable Content | 送られた内容に問題があって処理できない | 入力エラーのあるフォームを送信したとき（第10章） |
| 500 Internal Server Error | サーバー内部のエラー | あなたのコードにバグがあったとき |

### Step 3 Rails の書き方が「ただの Ruby」であることを確かめる

Rails のコードには、`resources :users` や `has_many :posts` のような、一見すると特別な構文に見える書き方がたくさん出てきます。**これらはすべて、Ruby の普通のメソッド呼び出しです**。それを `irb`（Ruby を対話的に実行するツール）で確かめます。

ターミナルで `irb` を起動します。Part 1 ではいま入っている Ruby 3.3.5 で構いません。

```bash
irb
```

`irb(main):001>` のようなプロンプトが出たら、1行ずつ入力して Enter を押してください。

```ruby
def resources(name, **options) = puts("resources が呼ばれました: #{name.inspect} #{options.inspect}")
resources :users
resources :posts, only: [:create, :destroy]
resources(:posts, { only: [:create, :destroy] })
```

### 解説

- 1行目は、`resources` という名前の **自作のメソッド** を定義しています
  - `def メソッド名(引数) = 処理` は、1行で書けるメソッド定義です（Ruby 3.0 以降）
  - `**options` は「名前付きの引数をまとめてハッシュとして受け取る」という意味です
  - `#{...}` は文字列の中に式の値を埋め込む書き方、`inspect` は値を「Ruby のコードとしての見た目」で文字列にするメソッドです
- 2行目の `resources :users` は、**括弧を省略したメソッド呼び出し** です。Ruby では、意味が曖昧にならない限りメソッド呼び出しの `()` を省略できます
- `:users` は **シンボル** です。「名前」を表すための軽量な値で、Rails では「何かの名前」を渡すときによく使います（第5章で詳しく扱います）
- 3行目の `only: [:create, :destroy]` は、**末尾のハッシュの `{}` を省略した書き方** です。4行目は、括弧も `{}` も省略せずに書いたもので、3行目とまったく同じ意味になります

Rails の `config/routes.rb` に書く `resources :users` も、仕組みはこれと同じです。違うのは、Rails の `resources` が `puts` する代わりに「7つのルーティングを登録する」処理をしていることだけです。**Rails の記法に出会ったら、「これはどのオブジェクトの、何というメソッドを、どんな引数で呼んでいるのか」と考える癖** をつけると、ブラックボックスがなくなっていきます。

続けて、Ruby では **すべてが「オブジェクト」で、メソッドを持っている** ことも確かめます。

```ruby
:users.class
1.class
"user".class
nil.class
"user".upcase
"user".methods.size
```

`nil` にもクラス（`NilClass`）があることに注目してください。これが次の「よくあるエラー」につながります。

`irb` は `exit` で終了します。

---

## Rails 内部では何が起きているか

Part 1 の Step 1 で見た通信と、Rails の部品の対応を整理します。あなたが `GET /users/1` を送ったとき、Rails の中では次の順で処理が進みます。

```
① リクエスト到着  GET /users/1 HTTP/2
        │
        ▼
② Router         config/routes.rb の定義を上から順に照合する
        │         "/users/:id" に一致 → :id に "1" が入る
        │         → UsersController の show アクションを呼ぶと決める
        ▼
③ Controller     UsersController の新しいインスタンスを作り、show メソッドを実行する
        │         params[:id] には、② で取り出した "1" が入っている
        ▼
④ Model          User.find("1")
        │         → Active Record が SQL を組み立てる
        ▼
⑤ Database       SELECT `users`.* FROM `users` WHERE `users`.`id` = 1 LIMIT 1
        │         → 行が返る（見つからなければ例外 ActiveRecord::RecordNotFound → 404）
        ▼
⑥ Model          行を User オブジェクトに変換する
        ▼
⑦ Controller     @user に代入して show メソッドが終わる
        │         render の指示がない → 規約により users/show.html.erb を描画すると決める
        ▼
⑧ View           ERB を実行して HTML を作る。@user はビューから参照できる
        ▼
⑨ レスポンス     HTTP/2 200 / content-type: text/html / 本文は HTML
```

ポイントは次の3つです。

- **URL の一部（`:id`）は、Router によって `params` に入れられ、Controller に渡る**
- **Model のメソッド呼び出しは、最終的に SQL になる**（第8章で、実際に出力される SQL をログで確認します）
- **Controller が終わったあとのビューの選択は、規約で決まる**

第2章でアプリを作ったら、サーバーのログにこの流れがそのまま表示されることを確認します。

## Rails console で確認

Rails console は、Rails アプリを作ったあとで使えるツールなので、第2章から登場します。Part 1 では、その土台である `irb` を使いました。Rails console は「アプリのモデルなどを読み込んだ状態の irb」です。irb の操作に慣れておけば、そのまま使えます。

## テスト

Part 1 ではテストを書きません。ここでは、この教材でテストをどう扱うかの見通しだけ示します。

| テストの種類 | 確かめること | 先ほどの地図でいうと | 初登場 |
|---|---|---|---|
| Request spec | あるリクエストに対して、正しいステータスコードや内容が返るか | Router → Controller → View を、HTTP のレベルで外から確かめる | 第4章 |
| Model spec | データのルール（バリデーションなど）が正しく働くか | Model 単体 | 第9章 |
| System spec | ブラウザで操作したとき、画面が期待どおりに動くか | Browser から全体を通して確かめる | 第6章 |

Step 1・2 で `curl` を使ってステータスコードを確かめたことは、実は **Request spec が自動でやることを手でやった** ということです。第4章では、これをコードで書いて自動化します。

## よくあるエラー

### NoMethodError —— 「そのオブジェクトは、そのメソッドを持っていない」

`irb` で次を試してください。

```ruby
nil.upcase
```

Ruby 3.3.5 では次のように表示されます。

```
undefined method `upcase' for nil (NoMethodError)
```

**読み方**：「`nil` に対して `upcase` というメソッドは定義されていない」という意味です。`(NoMethodError)` がエラーの種類（例外クラス）です。

**原因の推測**：`nil` に `upcase` を呼ぶ人はいません。実際には、**「文字列が入っているはずの変数に、なぜか `nil` が入っていた」** ときに起きます。Rails では、たとえば次のような場面で頻出します。

```ruby
@user = User.find_by(email: "typo@example.com")  # 見つからないと nil を返す
@user.name                                        # => NoMethodError: undefined method 'name' for nil
```

**直し方の考え方**：エラーが出た行の **メソッドそのもの** ではなく、**「なぜその変数が nil だったのか」を遡って調べる** のが基本です。この調べ方は、第2章以降で Rails console とログを使って練習します。

**バージョンによる違い**：Ruby 3.4 以降では、メッセージの引用符がバッククォートからシングルクォートに変わり、`undefined method 'upcase' for nil` となります。Part 2 で Ruby 4.0 に切り替えると、こちらの表示になります。同様に、Step 3 の `options.inspect` の表示も、Ruby 3.4 以降は `{only: [:create, :destroy]}` という新しい形式に変わります。

もう1つ試してください。

```ruby
"user".foo
```

```
undefined method `foo' for an instance of String (NoMethodError)
```

「String クラスのインスタンス（文字列）には `foo` というメソッドはない」という意味です。**メソッド名の打ち間違い** の典型的なエラーです。

## Git コミット

このリポジトリには、まだ1つもコミットがありません。ここまでに作った「学習の計画」を、最初のコミットとして記録します。

```bash
git status
git add CLAUDE.md docs/
git commit -m "Add tutorial plan and chapter 1 part 1"
```

**なぜこの単位でコミットするのか**：

- コミットは「意味のあるひとまとまりの変更」を記録するものです。今回は「学習の計画を立てた」という、ひとまとまりになっています
- 第2章でアプリのファイルが大量に生成されます。その前に計画のファイルだけをコミットしておけば、「計画」と「アプリの雛形」が別々の履歴として残り、後から追いやすくなります
- `git add .`（すべて追加）ではなく、ファイルを指定して追加しています。**意図しないファイルをコミットしないため** です。第2章で `.gitignore` を学んだあとは、`git add .` を使う場面も出てきます

Part 1 はここまでです。

---

# Part 2 開発環境を整える

（Part 2 を開始するときに追記します）
