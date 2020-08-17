# WindowsでのPureBuilder Simplyの利用

## 注意

サポートされているのはWindows 10及びWindows PowerShell環境のみである。

## 準備

### Pandocのインストール

[Pandocの公式サイトからinstallのページにいき](https://pandoc.org/installing.html){rel="external"}、インストーラを入手し、インストールする。

一見単純そうであるが注意が必要な点がある。
それは、 *Pandoc 2.10.1 Windows Installerによってインストールされるのが Pandoc 2.4であるということである。*

PureBuilder Simplyは新しいテンプレートシステムなどを利用するため、Pandoc2.4では *動作しない。*
幸いにもWindowsの[ダウンロードページ](https://github.com/jgm/pandoc/releases/latest){rel="external"}にあるZIPのPandocは2.10である。
そこで、インストーラでPandocを導入したあと、ZIPをダウンロードし、ZIPにあるファイルで`C:\Program Files\Pandoc`以下のファイルを上書きする。

これで、PandocにPATHの通った状態でPandoc 2.10をインストールできる。

### Rubyのインストール

[RubyInstaller](https://github.com/jgm/pandoc/releases/latest){rel="external"}を使って最新版を普通に導入すれば良い。

このとき、 PATHを通すための設定があるので、有効になっていることを確認すること。

### Git for Windowsのインストール

[Git for Windows](https://gitforwindows.org/){rel="external"} をインストールする。

### Windows Terminalのインストール (オプション)

Windows上でPureBuilder Simplyを動作させるにはWindows PowerShellを必要とする。

普通にPowershellを起動してもいいのだが、Windows Terminalを使えばより便利に感じられるかもしれない。

Windows TerminalはMicrosoftストア上にある。

### エディタのインストール (オプション)

ドキュメントや設定ファイルを記述するのに適したエディタがあると良いだろう。

Visual Studio CodeやAtomがおすすめだ。

### PureBuilder Simplyのインストール

PowerShellで次のようにする。 (`.ps1`スクリプトとして実行しても良い)

```powershell
cd $Env:LocalAppData
git clone 'git://github.com/reasonset/purebuilder-simply.git'
```

### PowerShellエイリアスの設定

PureBuilder Simplyは *Windows 10をサポートし、PowerShell上で動作する。*

ここの作業はまずまず複雑だ。

#### まだプロファイルの設定をしたことがない場合

まず、PowerShellを **管理者権限で** 起動し、次のコマンドを実行する

```powershell
Set-ExecutionPolicy RemoteSigned
```

*管理者権限のPowerShellを閉じ、ユーザーとしてPowerShellを開いて、* 次のコマンドでプロファイルを作成する。

```powershell
New-Item -type file -force $profile
```

あるいは「PowerShell の開発者向け設定」から設定しても構わない。

#### 共通の作業

プロファイルにPureBuilder Simplyを起動するための関数を書いておく。
次のようにして編集する。

```powershell
notepad $Profile
```

```powershell
function PureBuilder-Simply { ruby $Env:LocalAppData/pbsimply-pandoc.rb $Args }
function PureBuilder-Server { ruby $Env:LocalAppData/pbsimply-testserver.rb $Args }
```

これでコマンドとして`PureBuilder-Simply`及び`PureBuilder-Server`が使えるようになった。
もちろん、ここではPowerShellっぽい名前にしたが、もっと短い名前にしても構わない。

### Open PowerShell Here (オプション)

Windows Terminalを入れた場合、エクスプローラのアドレスバーに`wt -d .`と打てばそこでWindows Terminalを開けるのだが、PowerShellの場合は引数がかなり長いので、次のようにして右クリックで開けるようにしてあげると良いだろう。
(`.reg`としてレジストリエディタで実行すれば良い)

```
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\shell\powershell_here]
@="Open PowerShell Here"

[HKEY_CLASSES_ROOT\Directory\shell\powershell_here\command]
@="C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%L'"

[HKEY_CLASSES_ROOT\Directory\Background\shell\powershell_here]
@="Open PowerShell Here"

[HKEY_CLASSES_ROOT\Directory\Background\shell\powershell_here\command]
@="C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%V'"
```

### Ruby, PandocにPATHが通っていない場合

インストールしたにも関わらず`ruby --version`及び`pandoc --version`が通らない場合、`PATH`が通っていない可能性がある。
Windowsの検索から「環境変数」を探し、`ruby.exe`と`pandoc.exe`があるフォルダを追加する。

## Unix環境との違い

### `dbstyle`の設定

PureBuilder SimplyはデフォルトでファイルデータをRuby Marshal形式で保存するが、これはWindows上ではうまく動作しない。

そのため、設定ファイルの`dbstyle`の項目を設定する必要がある。

値は`yaml`が推奨されるが、`json`あるいは(`Oj`をインストールしているならば)`oj`でも構わない。

### 端末を開く

ソースディレクトリ上で端末を開くことが望ましいが、それを行うには、Windows Terminalを使う場合、Explorerのアドレスバーに`wt -d .`と打ち込めば良い。

また、PowerShellを使う場合は、上記登録によって右クリックから行えるだろう。

### コマンド

PureBuilder Simplyのコマンドは、準備の項目で設定した関数の名前に従うことになる。

### plugins

pluginsは、

* PureBuilder Simplyでサポートされている拡張子
* 単純なコマンド名でインタープリターを起動できる

を満たされなければ動作しない。

## もうひとつの方法: WSLを使う

WSLを使う場合より簡単だ。
Windows固有の問題もなく利用できる。

### WSLを用意する

"Windows Subsystem for Linux" を検索し、Microsoft Docsを読むと良いだろう。

なお、検証はopenSUSE Leapを利用しているが、お好みのディストリビューションでも構わない。
セットアップまで済ませておくこと。

### Windows Terminalを導入する

Microsoft StoreでWindows Terminalを導入する

### Pandoc, Rubyを導入する

RubyはWSL上のものを使用することを推奨する。

WSL上で

```bash
type ruby
```

と入力してnot foundと言われるならば、Rubyをインストールしよう。
openSUSEの場合

```bash
zypper install ruby
```

とする。また、Gitも導入されていることを確認しよう。
ないのならばインストールする。

Pandocに関してはWindowsのものを使うほうがパフォーマンスが良いし、導入が楽である(もちろん、Pandocがコミュニティパッケージにあるようなディストリビューションを使っているのであればWSL上で導入しても良い)。

そして、`$PATH`の通った場所(例えば`/usr/local/bin`)に実行可能なパーミッションを持つファイルとして次のように記述する。

```
#!/bin/bash

"/mnt/c/Program Files/Pandoc/pandoc.exe" $@
```

ここではPandocのWindows上のパスが`C:\Program Files\Pandoc\pandoc.exe`であると仮定している。ファイル名は`pandoc`でなければならない。

Linuxに慣れていない人のために説明しよう。

WSL上のファイルは`%LocalAppData%\Packages\*\LocalState\rootfs`以下にある。
`Packages`の下のディレクトリはディストリビューションによって異なるので探す必要がある。

Viが使えるのならばもちろん、Viで`sudo vi /usr/local/bin/pandoc`としても良い。
openSUSE LeapならばEmacsが使える。`vi`ではなく`eamcs`とすればEmacsが立ち上がる。保存は`Ctrl+X Ctrl+S`、終了は`Ctrl+X Ctrl+C`である。こっちならまだなんとかなるだろう。

ファイルを作り終えたら次のようにしてパーミッションを設定する。

```bash
sudo chmod 755 /usr/local/bin/pandoc
```

### PureBuilder Simplyを導入する

WSL上で以下の通りにするのが早いだろう。

```bash
sudo mkdir /opt
sudo chmod 777 /opt
cd /opt
git clone 'git://github.com/reasonset/purebuilder-simply.git'
cd /usr/local/bin
sudo ln -s /opt/purebuilder-simply/*.rb .
```

### ドキュメント作成からビルド

通常どおりプロジェクトディレクトリを作ってWindows上でファイルを編集していけば良い。

ビルド時はドキュメントソースディレクトリルート上でExplorerのアドレスバーに`wt -d .`と入力しWindows Terminalを起動、タブの右のアイコンからLinuxディストリビューションを選択しWSLを起動する。

あとは通常通り、`pbsimply-pandoc.rb`コマンドを打ってビルドすれば良い。