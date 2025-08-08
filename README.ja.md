# Purebuilder Simply

Markdown, reStructured Text, RDocを用いて静的ウェブサイトを構築できるプログラマブルCLIツール。

## PureBuilderとは

PureBuilder Simplyはプレビルド型のウェブサイト構築ツール。 ヘッドレスCMSや、SSGとも呼ばれるものである。

構築・更新が容易で、文章を書く機能に長けており、文章中心のウェブサイトを作るのに適している。

## ACCSとは

ACCSはウェブサイト上で連載を構築するためのスクリプトである。

PureBuilder Simply ACCS はPureBuilder Simplyによって `index.html` ファイルを生成する。

## インストール

### RubyGems.orgからインストールする

`gem install pbsimply`

### 手動でRubyGemsをインストールする

* `gem build pbsimply.gemspec`
* `gem install pbsimply-$version.gem`

### 手動でインストールする

* `git clone https://github.com/reasonset/purebuilder-simply`
* `bin/`ディレクトリのファイルをPATHの通ったディレクトリにコピーする
* `lib/`ディレクトリのファイルをRubyライブラリのディレクトリにコピーする

## はじめる

* ドキュメントルートディレクトリを作成する
* ドキュメントルートディレクトリに `.pbsimply.yaml`ファイルを設置する
* ディレクトリ及びドキュメント(MarkdownまたはReST)を書く
* `pandoc -D html5 > template.html` としてテンプレートファイルを作成し、編集する

## Dependency

* Ruby >= 3.0
* Pandoc >= 2.8

## Usage

### PureBuilder

ドキュメントルートに移動してから次のように実行する。

	pbsimply directory

PureBuilder Simplyはdirectoryにあるドキュメントを構築する。

構築されるドキュメントから除外したい場合、ファイル名を`draft-`または`.`ではじまるものにするか、
frontmatterの`draft`の値を真にする。

### Options

|オプション|内容|
|------|------------------------------|
|`-f`, `--force-refresh`|すべてのドキュメントを強制的に更新する。テンプレートを更新した場合に便利|
|`-I`, `--skip-index`|`.indexes.rbm`に登録しない|
|`-A`, `--skip-accs`|ACCSの処理をしない|
|`-o FILE`, `--output`|出力ファイルをFILEに指定する|
|`-m FILE`, `--additional-metafile`|さらに追加のメタデータYAMLファイル|

### Make ACCS index

`pbsimply`は自動的にACCSドキュメントディレクトリを発見し、処理する。
あなたは`.accs.yaml`ファイルをディレクトリに配置することで、そのディレクトリがACCSドキュメントディレクトリであることを示すことができる。

ACCSプロセッサは`index.html`を生成し、配置する。

## 設定ファイルの値

## 環境変数

Pre Plugins, Post plugins, Blessing command, Hooksにおいて利用できる環境変数

|変数|Pre|Process|Delete|Post|Bless|説明|
|---------|---|---|---|---|---|--------------------|
|`pbsimply_outdir`|Yes|Yes|Yes|Yes|Yes|出力先ドキュメントルートのパス|
|`pbsimply_subdir`|Yes|Yes|Yes|Yes|Yes|ドキュメントルートからのドキュメントディレクトリのパス|
|`pbsimply_indexes`|Yes|Yes|Yes|Yes|Yes|インデックスデータベースのファイルパス|
|`pbsimply_frontmatter`|Yes|Yes|Yes|Yes|Yes|現在のドキュメントのfrontmatter(JSON)のパス|
|`pbsimply_working_dir`|Yes|Yes|Yes|Yes|Yes|処理中のファイルが置かれているディレクトリ|
|`pbsimply_currentdoc`|Yes|Yes|No|No|No|処理中のドキュメントファイルのパス|
|`pbsimply_filename`|Yes|Yes|No|No|No|元々のソースファイルのファイル名|

## Testing

ドキュメント中のリンクはローカルな場所に **すべきではなく** 、 *web上のURLでなくてはいけない* 。
そのため生成したファイルを静的にテストすることはできない。

ドキュメントルートで`pbsimply-testserver`を実行すると、テストサーバーを稼働させる。

使い方はとても簡単。

1. ドキュメントルートに移動する
2. 起動する
3. `http://localhost:port` にアクセスする

ポートは設定ファイルの`testserver_port`で設定でき、デフォルトは8000。

もし`http://example.com/site/index.html`のように本番環境がサブディレクトリにある場合、
ドキュメントをサブディレクトリ化に配置することを推奨する。

## 祝福

### Rubyで祝福する








## ファイル

### リポジトリに含まれるもの

|Filename|Description|
|--------|-------------|
|pbsimply-testserver|テスト用ウェブサーバー起動スクリプト|
|accsindex.erb|`.accsindex.erb`のサンプル。通常編集せずそのまま利用できる|

### あなたが置くか、生成されるもの

|ファイル名|場所|Description|
|--------|-----------|-------------|
|.pbsimply.yaml|root|設定ファイル。ドキュメントルートに置く|
|.indexes.rbm|each|PureBuilder Simplyが生成するRuby marshalファイルのインデックスデータベース|
|.indexes.json|each|PureBuilder Simplyが生成するJSONファイルのインデックスデータベース|
|.index.md|each|ACCSが生成するインデックスページ|
|.accsindex.erb|root or each ACCS|ACCSインデックスページ用Markdown eRubyテンプレート|
|.accs.yaml|each|ACCSインデックスページ用の`@index`|
|.pbsimply-bless.rb|root|Bless用のRubyスクリプト|

# ドキュメントサンプル

## テンプレート

このテンプレートは標準的なブログをイメージしたテーマとなっている。

* ふたつのヘッダーを持つ。通常は`display: none`になっているバナーのための`#TopHeader`と、タイトルのための`#TitleHeader`
* メインセクションは`#MainContainer` sectionで囲まれる
* 記事は`#MainArticle` articleに囲まれる
* サイドバーは`#SideBar` sectionとして容易されている。include beforeを使ってサイドバーの中身を書くことができる
* 著者部分は削除された
* 埋め込みCSSは削除された
* シンタックスハイライトのテーマも削除された。必要なら[pandoc-goodies](https://github.com/tajmone/pandoc-goodies)などで入手できる。

## CSS

基本的でシンプルなCSSが用意されている。

|ファイル|内容|
|---------|----------------|
|layout.css|レイアウト|
|base.css|最小限のデザイン|
|skylightning.css|PandocデフォルトのソースコードCSS|
|lightbox.css|Lightboxプラグインのテーマ|

## Post

ACCSのベースになるディレクトリ。

## Post Generate

post-pluginsのサンプルスクリプト

## 設定ファイル

`.accsindex.rb` と `.pbsimply.yaml` のサンプルファイルが用意されている。

## JavaScript

JavaScriptプラグインファイル。

それぞれのファイルにあるREADMEを読むこと。

## テーマ

コピーしたサンプルドキュメントディレクトリにテーマディレクトリをマージすることでテーマを利用することができる。

### Base

![Default theme](img/theme-base.png)

### Warm

![ウォームカラーのテーマ](img/theme-warm.png)

### Practical

![論文などに適するテーマ](img/theme-practical.png)

### Bloggy

![よくあるブログっぽいテーマ](img/theme-bloggy.png)]

## Pandoc以外のプロセッサを使う

### 基本事項

PureBuilder SimplyはPandocを使うことで非常に強力なツールとなるが、Pandocを好まない場合、他のドキュメントプロセッサを使うこともできる。

ただし、機能的には制約を受ける。

使用するプロセッサは`.pbsimply.yaml`の`pbsimply_processor`の値を用いて指定する。

|Processor|pbsimply_processor|
|--------|-------------------|
|RDoc|`rdoc`|
|RDoc/Markdown|`rdoc_markdown`|
|Kramdown|`kramdown`|
|Redcarpet|`redcarpet`|
|CommonMarker (cmark-gfm)|`cmark`|
|Docutils (実験的)|`docutils`|



### RDoc

#### 説明

Rubyの標準ドキュメントシステムのRDocを用いる。
ソースファイルはRDocであるとして処理し、対象は`*.rdoc`ファイルに限られる。

テンプレートはeRubyテンプレートとして扱う。

#### Dependency

* rdoc library

#### 使用できない設定

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

### RDoc/Markdown

#### 説明

Rubyの標準ドキュメントシステムのRDocのMarkdownプロセッサを用いる。
ソースファイルはMarkdownであるとして処理し、対象は`*.md`ファイルに限られる。

テンプレートはeRubyテンプレートとして扱う。

#### Dependency

* rdoc library

#### 使用できない設定

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

### Kramdown

#### 説明

RubyのMarkdownライブラリ、Kramdownを用いて生成する。
ソースファイルはMarkdownであるとして処理し、対象は`*.md`ファイルに限られる。

テンプレートはeRubyテンプレートとして扱う。

#### Dependency

* kramdown library

#### 使用できない設定

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

#### 追加される設定

|Key|Type|Description|
|-------|-----|-----------------------|
|`kramdown_features`|Hash|`Kramdown::Document.new`の第2引数として渡される連想配列。詳細は[APIドキュメントを参照すること。](https://kramdown.gettalong.org/rdoc/Kramdown/Options.html)|

### Redcarpet

#### 説明

RubyのMarkdownライブラリ、Redcarpetを用いて生成する。
ソースファイルはMarkdownであるとして処理し、対象は`*.md`ファイルに限られる。

テンプレートはeRubyテンプレートとして扱う。

#### Dependency

* redcarpet library

#### 使用できない設定

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

#### 追加される設定

|Key|Type|Description|
|-------|-----|-----------------------|
|`redcarpet_extensions`|Hash|Redcarpetの拡張を示す連想配列。詳細は[Redcarpetのページ](https://github.com/vmg/redcarpet)を参照|

### CommonMarker

#### 説明

`libcmark-gfm`のRubyラッパーであるCommonMarkerを用いて生成する。
ソースファイルはMarkdownであるとして処理し、対象は`*.md`ファイルに限られる。

`table`及び`strikethrough`拡張が有効になる。

テンプレートはeRubyテンプレートとして扱う。

#### Dependency

* libcmark-gfm
* commonmarker library

#### 使用できない設定

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

### Docutils

#### 説明

Pythonで書かれたReSTructured Textプロセッサ、Docutilsを用いて生成する。
ソースファイルはReSTructured Textであるとして処理し、対象は`*.rst`ファイルに限られる。

#### Dependency

* Docutils (`rst2html5`)

#### 使用できない設定

* `toc`
* `pandoc_additional_options`

#### 追加される設定

|Key|Type|Description|
|-------|-----|-----------------------|
|`docutils_options`|Array|`rst2html5`コマンドに渡されるコマンドラインオプション引数|

# Hooks

## 概要

Hooksを使うことで、PureBuilder Simplyの処理に追加の挙動を加えることができる。

Hooksを定義するには、ドキュメントルートディレクトリに`.pbsimply-hooks.rb`を置く。
このスクリプトでは、`PBSimply::Hooks.load_hooks`を定義する必要がある。

このメソッドには`PBSimply::Hooks`オブジェクトが引数として渡される。
`PBSimply::Hooks`オブジェクトはタイミングをメソッドとして持っており、それぞれのタイミングオブジェクトの`<<`メソッドに`Proc`オブジェクトを渡すことで、hookに処理を追加することができる。

```ruby
#!/bin/ruby

def (PBSimply::Hooks).load_hooks h
  h.process << ->(v) {
    db[v["normalized_docpath"]] = v
  }

  h.post << ->(v) {
    db.delete_if do |dbk, dbv|
      not File.exist? dbv["dest_path"]
    end
  }
end
```

hookには必ず1つの引数(通常はHash)が渡されるが、その中身はタイミングによって異なる。

## タイミングメソッド

`PBSimply::Hooks#load_hooks`の引数オブジェクトのメソッド。

### `#add {|arg| ... }`

ブロックをタイミングオブジェクトに追加する。

### `#<< proc`

Procオブジェクトをタイミングオブジェクトに追加する。

### `#cmd(*cmdarg)`

`system(*cmdarg)` 形式でコマンドを実行する。

`pre`では`$pbsimply_currentdoc`の内容を更新して反映させることができる。

### `#filter(*cmdarg)`

`IO.popen(cmdarg, "w+")` 形式でコマンドを実行する。

コマンドは標準入力からドキュメントの内容が与えられ、ドキュメントの内容はコマンドの出力で置き換えられる。

このコマンドは`pre`においてのみ利用可能。

## タイミングオブジェクト

### pre

`PBSimply::Hooks#pre`はドキュメント処理の直前に呼ばれる。

引数は`frontmatter`と`procdoc`.

`frontmatter`はこのタイミングでのfrontmatterが入っている。
`pre`が呼ばれるのはBLESSよりも後である。

`procdoc`には処理中のドキュメントの一時ファイルのパスが入っている。
この時点では、このファイルの中身はソースドキュメントからfrontmatterを除いたものに過ぎない。

### process

`PBSimply::Hooks#process`はドキュメントの一連の処理を行い、最後の生成を行った直後に呼ばれる。

引数は`frontmatter`, `procdoc`, `outpath`である。

`frontmatter`および`procdoc`は`#pre`と同様だが、生成前の処理はすべて終わった状態になっている。
`outpath`は出力予定されたドキュメントのパス。

### delete

`PBSimply::Hooks#delete`は、ドキュメントが「なくなった」場合に呼ばれる。
これは、ドキュメントがdraftに変更された場合を含む。

引数は`target_file_path`と`source_file_path`である。

`target_file_path`はこのドキュメントが生成される場合の出力ファイルパスである。
このファイルは存在する場合もあれば、存在しないこともある。

`source_file_path`はソースドキュメントのパスである。
存在することもあれば、存在しないこともある。

### post

`PBsimply::Hooks#post`はすべてのドキュメントの生成が終わったタイミングで呼ばれる。

引数は`this_time_processed`である。
これは、`Hash`の配列で、実際にPureBuilder Simplyが今回の処理したドキュメントが入っている。
中身は`source`(オリジナルのソースファイルのパス), `dest`(出力ファイルのパス), `frontmatter`である。

### accs

`PBSimply::Hooks#accs`はACCSインデックスを生成するときに呼ばれる。

引数として`index`と`indexes`が渡される。
これは、`.accsindex.erb`で認識される`@index`および`@indexes`と同じものである。
