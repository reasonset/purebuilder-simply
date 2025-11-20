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

## Dependency

* Ruby >= 3.0
* Pandoc >= 2.8 (任意)
* Docutils (任意)
* redcarpet Gem (任意)
* kramdown Gem (任意)
* commonmarker Gem (任意)

## Usage

### プロジェクトを作る

`pbsimply-init`を使ってプロジェクトディレクトリ(ドキュメントソースルート `Source`, ドキュメントビルドルート `Build`)を生成する。

```bash
pbsimply-init
```

引数としてディレクトリを与えることができる。
省略した場合はカレントディレクトリが使われる。
ディレクトリは空でなくてはならない。

`-t`オプションを使って初期化に使用するテーマを指定することもできる。

### 生成する

ドキュメントソースルートに移動してから次のように実行する。

```bash
pbsimply directory
```

PureBuilder Simplyはdirectoryにあるドキュメントを処理し、HTMLファイルを出力する。

## 詳しいドキュメント

[プロジェクトホームページ](https://purebuilder.app/)に詳しいドキュメントが掲載されている。
