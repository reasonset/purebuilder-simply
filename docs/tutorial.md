# How to begin PureBuilder Simply

## Quick start

1. Copy `docbase` directory to your source document root.
2. Merge directory under `themes` which you choose into your source documents root.
3. Edit `.pbsimply.yaml` file.
4. Write `index.md` on your document root.
5. Write Markdown or ReST documents on `post` directory.

## Manual minimal

1. Make your source document root. I recommend that it is `sitename/Sources`.
2. Make your build document root. I recommend that it is `sitename/Build`.
3. Write `.pbsimply.yaml` on source document root. You must write `outdir` for build document root. If you follow my recommendation, write `outdir: ../Build`.
4. If your site root path has sub-directory (for example, your site root is `http://example.com/yourname/`), set your sub-directory to `self_url_prefix`. It replace heading `/`, so begin with `/` and end with `/` (e.g. `self_url_prefix: /yourname/`.)
5. Generate base template with `pandoc -D html5 > temaplte.html`.
6. Make you ACCS directory and write `.accs.yaml` into the directory if you need. write `title: "<Your Series Title>"` at `.accs.yaml`.
7. Write documents.

## Make up your site

If you know about HTML, edit [Pandoc template](https://pandoc.org/MANUAL.html#templates).

CSS files loaded by `css` options on configuration root or under `pandoc_additional_options` by default template, but I recommend to hard code into template.

CSS files path are *Internet address*, so you should express with absolute URL.
It means if you write

```yaml
css:
  - abc.css
```

template system replaces it to

```html
  <link rel="stylesheet" href="abc.css" />
```

## ACCS article list

You can control how to list article with `accs_*` paramater.
Read README.

If you write eRuby, you can edit `.accsindex.erb` file.