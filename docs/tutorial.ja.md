# PureBuilder Simplyのはじめかた

## 迅速にはじめる

1. `docbase`ディレクトリをあなたのソースドキュメントルートとしてコピーする
2. `themes`の下にある、お好きなテーマディレクトリをソースドキュメントルートディレクトリにマージする
3. `.pbsimply.yaml`を編集する
4. ソースドキュメントルート下の`index.md`を書く
5. `post`の下にMarkdown、またはReSTでドキュメントを書く

## 手動で、最小限にはじめる

1. ソースドキュメントルートディレクトリを作る。`sitename/Sources`を推奨する
2. ビルドドキュメントルートディレクトリを作る。`sitename/Build`を推奨する
3. `.pbsimply.yaml`をソースドキュメントルート直下に書く。`outdir`はビルドドキュメントルートディレクトリを指す必須の値である。推奨に従っている場合、`outdir: ../Build`と書く
4. もしあなたのサイトのルートパスがサブディレクトリを持っている場合(例: `http://example.com/yourname/`)サブディレクトリを`self_url_prefix`にセットする。これは先頭の`/`を置き換えるもので`/`で始まり`/`で終わる (例: `self_url_prefix: /yourname/`)
5. `pandoc -D html5 > temaplte.html`としてテンプレートファイルを生成する
6. ACCSを必要とする場合、ACCSドキュメントディレクトリを作り、`.accs.yaml`を書く。このファイルには`title: "<Your Series Title>"`と最低限書いておく
7. ドキュメントを書く

## サイトに化粧をする

もしあなたがHTMLを理解するならば、[Pandocテンプレート](https://pandoc.org/MANUAL.html#templates)を編集すれば良い。

CSSは設定ファイルのルート直下の`css`オプション、あるいは`pandoc_additional_options`下の`css`が、デフォルトテンプレートによってロードされる。ただし、私はテンプレートにハードコーディングすることを推奨する。

このCSSファイルは *インターネットアドレスである*。だから、絶対URLであるはずだ。
これは

```yaml
css:
  - abc.css
```

と書いた場合、テンプレートシステムは

```html
  <link rel="stylesheet" href="abc.css" />
```

と置き換えるということを意味する。

## ACCS article list

ACCSの記事リストをどのようにリストするかは`accs_*`設定値によって設定できる。
READMEを見よ。

あなたがeRubyを書くことができるならば、`.accsindex.erb`ファイルを編集する方法もある。
