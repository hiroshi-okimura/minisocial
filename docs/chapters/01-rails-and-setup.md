# 第1章 Rails とは何か・開発環境を整える

> 対象バージョン：Ruby 3.4.x（3.4.10）/ Rails 8.1.x（8.1.4）/ MySQL 8.4 LTS（8.4.11）（2026-10-05 確認）
> Part 1 で使うのは `curl` と `irb` だけです。Rails 8.1 と MySQL 8.4 は Part 2 でインストールします。

---

## これまでの復習

第1章なので、復習する内容はまだありません。次の章からは、ここに「この章で使う、前の章までの知識」をまとめます。

## この章でできるようになること

- Web アプリケーションが「HTTP リクエストを受け取り、HTTP レスポンスを返すプログラム」であることを、実際の通信を見ながら説明できる
- Rails が1つのリクエストを処理する流れ（Browser → Router → Controller → Model → Database → Controller → View → Browser）を、具体例で説明できる
- Rails の設計思想（特に「設定より規約」）が、コードの書き方にどう表れるかを説明できる
- `resources :users` のような Rails 特有の書き方が、Ruby の普通のメソッド呼び出しであることを理解する
- Ruby 3.4 / Rails 8.1 / MySQL 8.4 / Git / GitHub が動く開発環境を構築できる（Part 2）

## 今回作るもの

| Part | 内容 | 成果物 |
|---|---|---|
| Part 1 | Rails の全体像をつかむ | `curl` と `irb` で行う観察と実験。リポジトリの最初のコミット |
| Part 2 | 開発環境を整える | Ruby 3.4 / Rails 8.1 / MySQL 8.4 が動く状態。MySQL に SQL を直接打って、データベースを体験する |

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

**バージョンによる違い**：Ruby 3.4 以降では、メッセージの引用符がバッククォートからシングルクォートに変わり、`undefined method 'upcase' for nil` となります。このリポジトリで使う Ruby 3.4.10 では、こちらの表示になります。同様に、Step 3 の `options.inspect` の表示も、Ruby 3.4 以降は `{only: [:create, :destroy]}` という新しい形式に変わります。

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

> 確認日：2026-10-05。Ruby 3.4.10 / Rails 8.1.4 / MySQL 8.4.11 / mise 2026.9.0 / Homebrew 6.0.21
> SQL の実行結果とエラーメッセージは、MySQL 8.4.11 で実際に実行して確認したものです。

## Part 1 の復習

- Rails は Router → Controller → Model → Database → View の順でリクエストを処理する
- Model のメソッド呼び出し（`User.find(1)` など）は、最終的に SQL になって Database に届く

Part 2 では、この地図に出てくる部品を **自分の Mac で動かす** ための道具をそろえます。特に Database（MySQL）には、Rails を通さずに直接 SQL を打って触ってみます。第8章で Active Record を学ぶとき、「Rails が裏でやっていること」を自分の手で一度やった経験が、理解の土台になるからです。

## Rails の仕組み —— 開発環境を構成するもの

これから用意するものの関係を、先に図で示します。

```
あなたの Mac
├── mise ……………………… Ruby のバージョンをプロジェクトごとに切り替える道具
│    └── Ruby 3.4.10
│         └── RubyGems（gem コマンド）……… Ruby のライブラリ（gem）を入れる道具
│              ├── rails 8.1.4 ……………… rails コマンド（第2章で rails new に使う）
│              └── bundler ………………… プロジェクトごとに gem のバージョンをそろえる道具（第2章）
│
├── Homebrew ………………… macOS 用のパッケージ管理ツール
│    └── MySQL 8.4
│         ├── mysqld（サーバー）…… 常に裏で動き、データを保存・検索する
│         └── mysql（クライアント）… mysqld に SQL を送るコマンド
│
└── Git / GitHub CLI ……… 変更の履歴管理と、GitHub との連携
```

### なぜバージョン管理ツール（mise）を使うのか

Ruby は、macOS に最初から入っているものもあります。しかし、それを使わずに mise を使う理由は次の2つです。

1. **プロジェクトごとに必要なバージョンが違う**：古いプロジェクトは Ruby 3.3、新しいプロジェクトは Ruby 3.4、というのは実務では普通です。mise は、ディレクトリに置いた `mise.toml` を見て、使う Ruby を自動で切り替えます
2. **macOS 標準の Ruby は、システムが使うためのもの**：そこに gem を入れようとすると権限エラーになったり、OS のアップデートで消えたりします

あなたはすでに、このリポジトリに次の `mise.toml` を作っています。

```toml
[tools]
ruby = "3.4.10"
```

この1行があるおかげで、**このディレクトリの中にいるときだけ** Ruby 3.4.10 が使われます。リポジトリの外では、グローバル設定の 3.3.5 のままです。

### なぜ MySQL は「サーバー」と「クライアント」に分かれているのか

MySQL は、Excel のファイルのように「開いて使う」ものではありません。**データを管理する専用のプログラム（サーバー：`mysqld`）が常に裏で動いていて、そこに SQL を送って仕事を頼む** という形で使います。

```
 mysql コマンド（あなた） ──┐
                          ├──  SQL  ──>  mysqld（MySQL サーバー）──> データファイル
 Rails アプリ             ──┘   <── 結果 ──
```

- Part 2 では、`mysql` コマンドから SQL を送ります
- 第2章以降は、**Rails アプリも mysqld に SQL を送るクライアントの1つ** になります。Active Record は、Ruby のメソッド呼び出しを SQL に翻訳して mysqld に送る「通訳」です

つまり、Part 2 であなたが手で打つ SQL は、第8章以降で Rails が代わりに打ってくれるものと **同じもの** です。

---

## 実装

### Step 1 Ruby 3.4.10 が使われていることを確かめる

ターミナルで、このリポジトリのディレクトリに移動してから実行します。

```bash
cd ~/Documents/toy/minisocial
ruby -v
which ruby
```

```bash
cd ~
ruby -v
cd ~/Documents/toy/minisocial
```

### 解説

- リポジトリ内では `ruby 3.4.10 ...`、ホームディレクトリでは `ruby 3.3.5 ...` と表示されれば成功です
- `which ruby` は「今 `ruby` と打ったとき、どこにあるプログラムが実行されるか」を表示します。mise が管理するディレクトリ（`~/.local/share/mise/installs/ruby/3.4.10/...`）が表示されるはずです
- この切り替えは、`~/.zshrc` にある `eval "$(mise activate zsh)"` によって実現されています。ディレクトリを移動するたびに mise が `mise.toml` を探し、環境変数 `PATH`（コマンドを探す場所の一覧）を書き換えています

### Step 2 Rails 8.1.4 をインストールする

**必ずリポジトリのディレクトリの中で** 実行してください（Ruby 3.4.10 側に入れるためです）。

```bash
cd ~/Documents/toy/minisocial
gem install rails -v 8.1.4
rails -v
```

`Rails 8.1.4` と表示されれば成功です。インストールには数分かかることがあります。

### 解説

- `gem install` は、RubyGems（Ruby のライブラリ配布の仕組み）から gem をダウンロードしてインストールするコマンドです。`-v 8.1.4` でバージョンを指定しています
- Rails 本体は1つの gem ではなく、Part 1 で紹介した Active Record や Action Pack などの gem の集まりです。`rails` gem をインストールすると、それらが **依存関係** としてまとめてインストールされます
- gem は **Ruby のバージョンごとに別々の場所** に入ります。次のコマンドで確かめられます

```bash
gem env gemdir
```

`.../ruby/3.4.10/lib/ruby/gems/3.4.0` のように表示されます。そのため、Ruby 3.3.5 側に入っている Rails 7.1.5 とは、互いに影響しません

**なぜバージョンを指定するのか**：指定しなければ、その時点の最新版が入ります。教材と同じバージョンにそろえておけば、生成されるファイルやエラーメッセージが教材と一致します。なお、ここで入れた Rails は、第2章の `rails new`（アプリの雛形を作るコマンド）を実行するためだけに使います。アプリができたあとは、アプリの `Gemfile` で指定したバージョンを Bundler が使うようになります（第2章で説明します）。

### Step 3 MySQL 8.4 をインストールして起動する

```bash
brew install mysql@8.4
```

インストールが終わると、注意事項（Caveats）が表示されます。その中に **keg-only** という言葉が出てきます。これは「他のバージョンとぶつからないように、`mysql` コマンドを自動では使える状態にしていない」という意味です。そのため、自分でパスを通します。

```bash
echo 'export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
mysql --version
```

`mysql  Ver 8.4.11 ...` のように表示されれば、クライアントが使えます。次に、サーバーを起動します。

```bash
brew services start mysql@8.4
brew services list
```

`mysql@8.4` の行が `started` になっていれば、サーバーが動いています。

### 解説

- `@8.4` は「8.4 系を指定する」という意味です。Homebrew で単に `mysql` と指定すると、8.4 LTS とは別系列の新しいバージョン（2026-10-05 時点では 26.7.0）が入ります。この教材では、長期サポート版（LTS）の 8.4 を使います
- `echo '...' >> ~/.zshrc` は、`~/.zshrc`（ターミナル起動時に読まれる設定ファイル）の末尾に1行追記するコマンドです。`source ~/.zshrc` で、その設定を今のターミナルに反映します
- `brew services start` は、mysqld を **バックグラウンドのサービス** として起動します。Mac を再起動しても自動で起動します。止めたいときは `brew services stop mysql@8.4` を実行します

### Step 4 MySQL に接続して、データベースを体験する

```bash
mysql -u root
```

`mysql>` というプロンプトが出れば接続成功です。`-u root` は「root（管理者）ユーザーとして接続する」という意味です。

> **root にパスワードがないことについて**：Homebrew の MySQL は、root ユーザーにパスワードを設定しない状態でインストールされます。ただし、**接続できるのは自分の Mac の中（localhost）からだけ** です。Rails が生成する設定ファイル（`config/database.yml`）も、開発環境では「root ユーザー・パスワードなし」で接続する前提になっています。そのため、この教材ではこのまま進めます。実務では、アプリごとに権限を絞った専用ユーザーを作るのが普通です（「実務ではどう使われるか」で触れます）。

ここからは `mysql>` のプロンプトで、1つずつ入力して Enter を押してください。**SQL は `;`（セミコロン）で終わります**。`;` を忘れると `->` というプロンプトが出て入力の続きを待つので、そのときは `;` だけ打って Enter を押してください。

#### 4-1 データベースとテーブルを作る

```sql
CREATE DATABASE sandbox;
SHOW DATABASES;
USE sandbox;

CREATE TABLE users (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL
);

SHOW TABLES;
DESCRIBE users;
```

`DESCRIBE users;` の結果は次のようになります。

```
+------------+--------------+------+-----+---------+----------------+
| Field      | Type         | Null | Key | Default | Extra          |
+------------+--------------+------+-----+---------+----------------+
| id         | bigint       | NO   | PRI | NULL    | auto_increment |
| name       | varchar(255) | NO   |     | NULL    |                |
| email      | varchar(255) | NO   |     | NULL    |                |
| created_at | datetime(6)  | NO   |     | NULL    |                |
| updated_at | datetime(6)  | NO   |     | NULL    |                |
+------------+--------------+------+-----+---------+----------------+
```

#### 解説

- **データベース**（`sandbox`）は、テーブルを入れておく箱です。Rails アプリは、通常、開発用（`minisocial_development`）とテスト用（`minisocial_test`）の2つのデータベースを使います（第2章）
- **テーブル**（`users`）は、同じ形のデータを行（レコード）として並べる表です。列（カラム）ごとに型と制約を決めます
- `id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY`
  - `BIGINT`：大きな整数
  - `AUTO_INCREMENT`：行を追加するたびに、MySQL が自動で 1, 2, 3... と番号を振る
  - `PRIMARY KEY`（主キー）：行を一意に特定するための列。`User.find(1)` の `1` は、この列の値です
- `VARCHAR(255)`：最大 255 文字の文字列。`NOT NULL`：空（NULL）を許さない
- `DATETIME(6)`：日時。`(6)` はマイクロ秒（小数点以下6桁）まで保存するという意味です

**実は、このテーブル定義は Rails が作るものとほぼ同じです**。Rails では、第8章で学ぶ **マイグレーション** という Ruby のファイルにこう書きます（今は読むだけで構いません）。

```ruby
create_table :users do |t|
  t.string :name, null: false
  t.string :email, null: false
  t.timestamps
end
```

`id` 列は書かなくても自動で作られ、`t.timestamps` の1行で `created_at` と `updated_at` が作られます。これも「設定より規約」の一例です。

#### 4-2 データを追加する（INSERT）・取り出す（SELECT）

```sql
INSERT INTO users (name, email, created_at, updated_at) VALUES ('Alice', 'alice@example.com', NOW(6), NOW(6));
INSERT INTO users (name, email, created_at, updated_at) VALUES ('Bob', 'bob@example.com', NOW(6), NOW(6));

SELECT * FROM users;
SELECT id, name FROM users WHERE id = 1;
SELECT * FROM users WHERE name = 'Carol';
```

```
+----+-------+-------------------+----------------------------+----------------------------+
| id | name  | email             | created_at                 | updated_at                 |
+----+-------+-------------------+----------------------------+----------------------------+
|  1 | Alice | alice@example.com | 2026-10-05 12:04:54.595840 | 2026-10-05 12:04:54.595840 |
|  2 | Bob   | bob@example.com   | 2026-10-05 12:04:54.597830 | 2026-10-05 12:04:54.597830 |
+----+-------+-------------------+----------------------------+----------------------------+
```

最後の `WHERE name = 'Carol'` の結果は `Empty set` です。

#### 解説

- `INSERT INTO テーブル (列, ...) VALUES (値, ...)`：行を1つ追加します。`id` は指定していませんが、`AUTO_INCREMENT` によって自動で振られています
- `NOW(6)`：現在日時（マイクロ秒まで）。Rails では、`created_at` と `updated_at` を Active Record が自動で入れてくれます
- `SELECT 列 FROM テーブル WHERE 条件`：条件に合う行を取り出します。`*` は「すべての列」という意味です
- 条件に合う行がないとき、SQL はエラーにはならず、**0行の結果（`Empty set`）を返す** だけです。Rails では、この「見つからない」をどう扱うかがメソッドによって違います
  - `User.find(3)`：見つからないと **例外 `ActiveRecord::RecordNotFound`** を発生させる（画面では 404 になる）
  - `User.find_by(name: "Carol")`：見つからないと **`nil` を返す**（Part 1 の NoMethodError の原因になりがちなもの）

#### 4-3 データを更新する（UPDATE）・削除する（DELETE）

```sql
UPDATE users SET name = 'Alice Smith', updated_at = NOW(6) WHERE id = 1;
SELECT id, name FROM users;

DELETE FROM users WHERE id = 2;
SELECT id, name FROM users;
```

#### 解説

- `UPDATE テーブル SET 列 = 値 WHERE 条件`：条件に合う行を書き換えます。`Rows matched: 1  Changed: 1` は「1行が条件に合い、1行が変更された」という意味です
- `DELETE FROM テーブル WHERE 条件`：条件に合う行を削除します
- **`WHERE` を付け忘れると、すべての行が対象になります**。`DELETE FROM users;` は全員を削除します。Rails では `User.delete_all` がこれに相当します。SQL を直接打つときに最も注意すべき点です

#### 4-4 UNIQUE 制約で、重複をデータベースに防がせる

まず、同じメールアドレスのユーザーを追加してみます。

```sql
INSERT INTO users (name, email, created_at, updated_at) VALUES ('Alice2', 'alice@example.com', NOW(6), NOW(6));
SELECT id, name, email FROM users;
```

**追加できてしまいます**。今のテーブルには「メールアドレスは重複してはいけない」というルールがないからです。この行を消してから、ルールを追加します。

```sql
DELETE FROM users WHERE name = 'Alice2';
CREATE UNIQUE INDEX index_users_on_email ON users (email);
```

もう一度、同じメールアドレスで追加してみます。

```sql
INSERT INTO users (name, email, created_at, updated_at) VALUES ('Alice3', 'alice@example.com', NOW(6), NOW(6));
```

```
ERROR 1062 (23000): Duplicate entry 'alice@example.com' for key 'users.index_users_on_email'
```

今度は、データベース自身が拒否しました。

#### 解説

- **INDEX（インデックス）** は、本の索引のようなものです。`email` 列の索引を作っておくと、「このメールアドレスの人」を探すときに、全行を順に見なくても素早く見つけられます
- **UNIQUE INDEX** は、索引を作るのと同時に「同じ値は2つ登録できない」という制約を課します
- インデックス名の `index_users_on_email` は、Rails がマイグレーションで自動的に付ける名前の規約（`index_テーブル名_on_列名`）に合わせました
- この節の要点は、**ルールを「アプリ側」に書くだけでなく、「データベース側」にも持たせることには意味がある** ということです。なぜ両方が必要なのかは、理解確認の問題で考えてもらいます（第9章で本格的に扱います）

#### 4-5 後片付け

```sql
DROP DATABASE sandbox;
exit
```

`DROP DATABASE` は、データベースを中のテーブルごと削除します。**元に戻せない操作** なので、名前をよく確認してから実行する習慣をつけてください。演習問題で再び `sandbox` を使うので、そのときにまた作り直します。

### Step 5 Git と GitHub の設定を確認する

```bash
git config --global init.defaultBranch main
git config --global --list
gh auth status
```

### 解説

- `init.defaultBranch main`：今後 `git init` で新しいリポジトリを作ったとき、最初のブランチ名を `main` にする設定です。GitHub の標準に合わせています。このリポジトリはすでに `main` なので影響はありません
- `git config --global --list` で、`user.name` と `user.email` が設定されていることを確認してください。コミットに記録される作者情報です
- `gh auth status` で `Logged in to github.com` と表示されれば、GitHub CLI が使えます。GitHub にリポジトリを作ってプッシュするのは、第2章で行います

---

## Rails 内部では何が起きているか（Part 2）

Part 2 で打った SQL と、第8章以降で書く Active Record のコードを対応させると、次のようになります。

| Part 2 で打った SQL | Active Record（第8章以降） |
|---|---|
| `CREATE TABLE users (...)` | マイグレーションの `create_table :users` |
| `CREATE UNIQUE INDEX ... ON users (email)` | マイグレーションの `add_index :users, :email, unique: true` |
| `INSERT INTO users (...) VALUES (...)` | `User.create(name: "Alice", email: "alice@example.com")` |
| `SELECT * FROM users WHERE id = 1` | `User.find(1)` |
| `SELECT * FROM users WHERE name = 'Carol'` | `User.where(name: "Carol")` / `User.find_by(name: "Carol")` |
| `UPDATE users SET name = '...' WHERE id = 1` | `user.update(name: "Alice Smith")` |
| `DELETE FROM users WHERE id = 2` | `user.destroy` |

Rails を使っても、**データベースに届くのは SQL** です。Active Record は、Ruby のコードを SQL に変換し、返ってきた結果を Ruby のオブジェクトに変換する「通訳」にすぎません。第8章では、Rails のログに出る SQL を見て、この表のとおりになっていることを確かめます。

## Rails console で確認

Rails console はまだ使えません。代わりに、今日使った `mysql` コマンドが「データベース用のコンソール」にあたります。

第2章でアプリを作ると、次の2つのコンソールを使い分けるようになります。

| コンソール | 起動方法 | 話す言葉 | 使う場面 |
|---|---|---|---|
| Rails console | `bin/rails console` | Ruby | モデルを操作する。Active Record の動きを確かめる |
| データベースコンソール | `bin/rails dbconsole`（中身は今日の `mysql` コマンド） | SQL | Rails を通さずに、テーブルの中身を直接見る |

## テスト

アプリのテストはまだ書けません。その代わりに、**環境が整ったことを確かめるチェックリスト** を実行してください。すべて期待どおりなら、第2章に進む準備は完了です。

```bash
cd ~/Documents/toy/minisocial
ruby -v                       # ruby 3.4.10 ...
rails -v                      # Rails 8.1.4
mysql --version               # mysql  Ver 8.4.11 ...
brew services list            # mysql@8.4 が started
mysql -u root -e "SELECT VERSION();"   # 8.4.11
git config --global init.defaultBranch # main
gh auth status                # Logged in to github.com
```

最後から3行目の `mysql -u root -e "SQL"` は、対話モードに入らずに SQL を1つだけ実行するオプションです。

「期待した結果になるかを、コマンドで自動的に確かめる」という考え方は、第2章以降で書くテストと同じです。

## よくあるエラー

### `zsh: command not found: mysql`

**原因**：mysql@8.4 は keg-only なので、パスを通さないと `mysql` コマンドが見つかりません。

**確認と修正**：
1. `grep mysql ~/.zshrc` で、Step 3 の `export PATH=...` の行があるか確認する
2. ない場合は追記する。ある場合は `source ~/.zshrc` を実行するか、ターミナルを開き直す

### `ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/tmp/mysql.sock' (2)`

**読み方**：「ローカルの MySQL サーバーに、`/tmp/mysql.sock` を通じて接続できない」という意味です。クライアント（`mysql`）は動いていますが、接続先のサーバー（`mysqld`）が見つかりません。

**原因の推測**：MySQL サーバーが起動していない可能性が最も高いです。

**確認と修正**：
1. `brew services list` で `mysql@8.4` の状態を見る
2. `started` でなければ、`brew services start mysql@8.4` を実行する
3. それでも起動しない場合は、ログを確認する。ログは `/opt/homebrew/var/mysql/` の中の、`.err` で終わるファイルです

このエラーは、第2章以降も「Mac を再起動したあと」などに出会う可能性があります。Rails から見ると、`ActiveRecord::ConnectionNotEstablished` というエラーとして現れます。

### `ruby -v` が 3.3.5 のまま

**原因**：リポジトリの外にいるか、mise が有効になっていません。

**確認と修正**：
1. `pwd` で、今いるディレクトリが `~/Documents/toy/minisocial` か確認する
2. `mise current ruby` で、mise が 3.4.10 を選んでいるか確認する
3. 選んでいるのに `ruby -v` が違う場合は、ターミナルを開き直す（`~/.zshrc` の `mise activate` が読み込まれていない）

### SQL のエラー（MySQL 8.4.11 で確認済み）

| エラー | 原因 | Rails ではどう現れるか |
|---|---|---|
| `ERROR 1146 (42S02): Table 'sandbox.userss' doesn't exist` | テーブル名の打ち間違い、またはテーブルを作っていない | マイグレーションを実行し忘れたときなど（第8章） |
| `ERROR 1062 (23000): Duplicate entry '...' for key '...'` | UNIQUE 制約に違反した | `ActiveRecord::RecordNotUnique`（第9章） |
| `ERROR 1364 (HY000): Field 'name' doesn't have a default value` | `NOT NULL` の列に値を入れなかった | `ActiveRecord::NotNullViolation`（第8章） |

## Git コミット

Part 2 では、リポジトリのファイルは変わっていません（MySQL や Rails は Mac 全体にインストールしたもので、リポジトリの外にあります）。`mise.toml` は、あなたがすでにコミットしています。

```bash
git status
```

`nothing to commit, working tree clean` と表示されるはずです。ただし、Claude が教材と進捗ファイル（`docs/` の下）を更新しています。その差分が表示された場合は、次のようにコミットしてください。

```bash
git add docs/
git commit -m "Add chapter 1 part 2"
```

**なぜ環境構築そのものはコミットされないのか**：Git が管理するのは、リポジトリの中のファイルだけです。しかし `mise.toml` のように **「このプロジェクトはこの環境で動く」という情報をファイルとして残す** ことはできます。チームで開発するとき、他のメンバーが同じ環境を再現できるようにするためです。第2章では、`Gemfile` と `Gemfile.lock` が同じ役割を gem について果たすことを学びます。

Part 2 はここまでです。

---

# 第1章のまとめ

- Web アプリケーションは、HTTP リクエストを受け取り、ステータスコードと本文を含むレスポンスを返すプログラムである
- Rails は、その処理を Router / Controller / Model / View に分担させる。部品同士は **名前の規約** によって、設定を書かなくてもつながる
- `resources :users` のような Rails の書き方は、レシーバや括弧が省略された **普通の Ruby のメソッド呼び出し** である
- Rails を使っても、データベースに届くのは SQL である。Active Record は Ruby と SQL の間の通訳である
- mise で Ruby のバージョンをプロジェクトごとに固定し、Homebrew で MySQL 8.4 を動かす環境を整えた

## 理解確認問題

答えはチャットで回答してください。すぐには答えを表示しません。回答をレビューします。

**問1** ブラウザから `GET /users/5` というリクエストが送られてから、HTML が返るまでの流れを、Router / Controller / Model / Database / View がそれぞれ何をするかがわかるように、自分の言葉で説明してください。ユーザー5番が存在しない場合、どこで何が起きるかも答えてください。

**問2** `Post` というモデルと、`PostsController` の `index` アクションがあるとします。規約に従った場合、(a) テーブル名、(b) モデルのファイルのパス、(c) `index` アクションが自動で表示するビューのファイルのパスは、それぞれ何になりますか。また、何らかの事情で、テーブル名だけ `articles` にしたい場合はどうすればよいですか。

**問3** `has_many :posts` という1行を、「誰に（どのオブジェクトに）」「何を（どのメソッドを）」「何を渡して（どんな引数で）」頼んでいるのかに分解してください。わかる範囲で、省略を戻した書き方も書いてみてください。

**問4** Step 4-4 では、UNIQUE INDEX を作る前は、同じメールアドレスの行を追加できました。「同じメールアドレスは登録できない」というチェックを Rails アプリ側（Ruby のコード）に書いておけば、データベースに UNIQUE INDEX を作らなくてもよいでしょうか。そう考える理由も含めて答えてください（正解を知らなくても、推測で構いません）。

**問5** `mysqld` と `mysql` の違いを説明してください。また、第2章以降の Rails アプリは、この2つのうちどちらと同じ立場になりますか。

## コーディング演習

回答のファイルは、リポジトリの `practice/ch01/` ディレクトリに作成してください。できたら「演習ができた」と伝えてもらえれば、ファイルを読んでレビューします。コミットするかどうかはお任せします。

**演習1** Part 1 の説明で使った `FakeMapper` を改造して、`practice/ch01/fake_mapper.rb` に保存してください。次の2つの呼び出しで、それぞれのとおりに表示されるようにします。

```ruby
mapper.draw do
  resources :users                           # 7つすべてを表示する
  resources :posts, only: [:index, :show]    # index と show の2つだけを表示する
end
```

`ruby practice/ch01/fake_mapper.rb` で実行できるようにしてください。

ヒント：Part 1 の Step 3 で使った `**options`、配列に要素が含まれるかを調べる `include?` メソッド。

**演習2** `practice/ch01/posts.sql` に、次の SQL を順番に書いてください。書いたら `mysql -u root < practice/ch01/posts.sql` で実行し、期待どおりの結果になるかを確かめます。

1. `sandbox` データベースを作り、Step 4-1 と同じ `users` テーブルを作る
2. `posts` テーブルを作る。列は `id`（主キー）、`user_id`（どのユーザーの投稿か）、`content`（本文。最大 140 文字、必須）、`created_at`、`updated_at`
3. ユーザーを2人（Alice と Bob）、投稿を3件（Alice が2件、Bob が1件）追加する
4. Alice の投稿だけを取り出す `SELECT` を書く
5. 最後に `sandbox` データベースを削除する

余裕があれば、4番を「Alice の `id` の値を直接書かずに、`name = 'Alice'` という条件で取り出す」書き方にも挑戦してください（調べてもよいです。第16・19章で学ぶ内容の予習になります）。

## 実務ではどう使われるか

- **Ruby のバージョン管理**：実務のプロジェクトでは、リポジトリに `.ruby-version` や `mise.toml` などを置いて、使う Ruby のバージョンをチーム全員でそろえます。第2章で `rails new` を実行すると `.ruby-version` も生成されるので、`mise.toml` との関係を確認します
- **開発用のデータベース**：Homebrew で直接インストールするほかに、Docker で MySQL を動かすチームも多いです。データベースのバージョンを本番環境と正確にそろえやすく、プロジェクトごとに別のバージョンを使い分けられるからです
- **データベースのユーザー**：本番環境では、root ではなく、アプリ専用で権限を絞ったユーザーを使います。万が一アプリが乗っ取られても、被害を最小限にするためです
- **SQL を直接打つ場面**：普段の開発は Active Record で行いますが、データの調査や不具合の原因調査では、SQL を直接打つ場面がよくあります。SQL を読み書きできることは、Rails エンジニアにとっても重要なスキルです

## 発展知識

- **Rails Doctrine の原文**：Part 1 で紹介した9つの柱は、[The Rails Doctrine](https://rubyonrails.org/doctrine) で読めます。第20章を終えたあとに読み返すと、各章の設計判断の理由が見えてきます
- **MySQL に接続する gem**：Rails 8.1 の `rails new` では、MySQL 用に `-d mysql`（`mysql2` gem を使う）と `-d trilogy`（`trilogy` gem を使う）の2つを選べます。前者は MySQL のクライアントライブラリに依存する C 拡張、後者は GitHub が開発した、クライアントライブラリに依存しない実装です。どちらを使うかは第2章で決めます
- **このページで確認したこと**：この章の Rails 内部の説明は、Rails 8.1.4 のソースコードで確認しています（`actionpack` の `action_dispatch/routing/route_set.rb`、`action_dispatch/http/request.rb`、`railties` の `rails/generators/database.rb` など）

---

作成日：2026-10-02（Part 1）、2026-10-05（Part 2・章末）

情報源：

- [CLAUDE.md](../../CLAUDE.md)、[docs/curriculum.md](../curriculum.md)
- Rails 8.1.4 のソースコード（RubyGems から取得：`actionpack-8.1.4`、`actionview-8.1.4`、`activerecord-8.1.4`、`activesupport-8.1.4`、`railties-8.1.4`）
- [The Rails Doctrine](https://rubyonrails.org/doctrine)
- [Download Ruby — ruby-lang.org](https://www.ruby-lang.org/en/downloads/)、RubyGems.org API（rails 8.1.4）
- [mise — Ruby](https://mise.jdx.dev/lang/ruby.html)
- [Homebrew Formulae — mysql@8.4](https://formulae.brew.sh/formula/mysql@8.4)、`brew info mysql@8.4`
- SQL の実行結果とエラーメッセージ：MySQL 8.4.11 で実行して確認（2026-10-05）
- Ruby のエラーメッセージ：Ruby 3.3.5 / 3.4.10 で実行して確認
- HTTP の観察結果：`curl` 8.7.1 で `https://example.com/` に対して実行して確認（2026-10-02）
