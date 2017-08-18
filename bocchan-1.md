[はてなブログの記事](http://sksat.hatenablog.com/entry/2017/08/07/203615)のMarkdown


はてブ書いてなさすぎて広告表示されちゃいましたよ


ということで、何を書こうかなあと思ったのですが、最近弄っているBoCCHAN-1 OBC(On Board Computer)のことをメモ代わりに書いておこうと思います。

# BoCCHAN-1 is 何


[http://www.kimura-lab.net/2013/06/21/%E8%B6%85%E5%B0%8F%E5%9E%8B%E8%A1%9B%E6%98%9F%E7%94%A8%E6%A8%99%E6%BA%96%E6%90%AD%E8%BC%89%E8%A8%88%E7%AE%97%E6%A9%9F%E3%83%9C%E3%83%BC%E3%83%89/:title]


```
木村研究室が開発した技術を使った小型高性能な衛星用計算機ボードで、6cm四方の大きさでありながら従来の超小型衛星のOBCとは一線を画す性能を発揮します。
```

こういうやつです。

大学発の小型人工衛星、「ほどよし」の主計算機として使われていたりする、けっこうすごいやつです。

え？なんでそんな特殊なコンピュータ使ってんのかって？
実は今年、東京理科大学がやっている宇宙教育プログラムというものに参加していまして、

[https://www.tus.ac.jp/uc/:embed:cite]

そこでやるCanSat実験用に使っています（贅沢すぎでは）。

# 機能とか
なんとこいつLinuxが動きます。第１回CHD(CanSat Hands-on Discussion)のときこれを聞いて、静かに興奮しておりました。
アーキテクチャは[SH4](https://ja.wikipedia.org/wiki/SuperH)((SH4ってなんか聞いたことがあるようなって思ってたけど、OSECPUのhh4と名前が似てる。関係ないけど。))。組み込みってかんじですね。

インターフェースについては、I2CとかUARTとかGPIOとかイケるみたいで中々良い。

Xbeeで通信もできるし。

# チュートリアルやってみた

宇宙教育プログラムLETUS((理科大の教育用のなんかの宇宙教育PG用鯖。掲示板とかファイルアップロード出来るのはいいなと思うけど通知とか遅らせられないんですかね。頻繁に見に行くというのは地味にめんどい。調べてみたらmoodleっていうOSS使ってるっぽくて、Rubyで書かれたAPIラッパーがあったから試してみようとしたのだけれど、管理者権限が無いといけないみたいで諦めた。仕方ないからBeautifulSoupからログインするスクリプト書いたけど、めんどくさくなってそれで終わってる。新規投稿が来たらSlackに流すみたいなのが出来れば便利なんだけど。))にアップロードされたクイックスタートガイドやユーザーズマニュアルとかを見ながらチュートリアルとかをやってみました。

そこに書いてあった開発手順を簡単に紹介すると、

* 開発環境一式が入っている仮想マシンイメージをダウンロード
* 仮想マシン内の、"ほどよしSDK"が導入されたEclipseを起動して、"Executable with HODOYOSHI SDK"プロジェクトを選択して作成
* C/C++でコード書いてビルド
* Eclipseの中にいる"BoCCHAN-1 ttyConsole"からBoCCHAN-1にシリアル接続
* バイナリを"BoCCHAN-1 ttyConsole"にD&Dして転送
* ttyConsoleから実行してみる

みたいなかんじでした。

# 開発環境の自作
というわけで、チュートリアルは出来たのですが、ここでいくつか問題が発生しました。
問題とは何かというと、

* 僕のマシンが非力すぎて長時間仮想マシン(しかもUbuntu)で作業とかちょっとツライさん
* EclipseというかIDEﾁｮｯﾄ..vimでやりたい

はい。開発環境自作のお時間です。

まずはEclipseどうなってんのかなと思ったので、適当な"Executable with HODOYOSHI SDK"プロジェクトを作って、Makefileを見てみました。
IDEが生成したMakefileとかクソ長いんじゃないの・・・とか思ったものの、かなり短かったのでやってることはすぐわかりました(Releaseだけだったし)。
主要な部分を抜き出すと、

subdir.mk(コンパイル部分)
```
%o:../%.cpp
    @echo 'Building file: $<'
    @echo 'Invoking: SH4-Linux G++ Compiler'
    sh4-linux-g++ -I/home/shdevelop/hodosdk/include/ -O0 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
    @echo 'Finished Building: $<'
```

makefile(リンク部分)
```
hoge: $(OBJS) $(USER_OBJS)
    @echo 'Building target: $@'
    @echo 'Invoking: SH4-Linux G++ Linker'
    sh4-linux-g++ -L/home/shdevelop/hodosdk/lib -o "hoge" $(OBJS) $(USER_OBJS) $(LIBS)
    @echo 'Finished building target: $@'
```

こんなかんじです。

ちなみに$(LIBS)は、objects.mkにて、
```
LIBS := -lpthread -lm -lhodoyoshi -lrt
```
となっていました。

ようするに、SuperH向けのg++でコンパイルして、ほどよしSDK内のライブラリをリンクしてるだけです。
なんだこれならホスト環境でも全然出来そうじゃん。

なんかpacmanでそれっぽいのが見つからなかったのと、ほどよしSDKとかが結構古いバージョンのもので構成されてたので、Ubuntu環境に移動してSH4向けのgcc,g++を探してみると、ありました。

[https://wiki.debian.org/SH4:title]

```
# apt-get install gcc-sh4-linux-gnu g++-sh4-linux-gnu
```

よーし、これでいけるでしょう、ということで、

```
$ vim hello.c
$ sh4-linux-gnu-gc hello.c -o hello
$ file hello
hello: ELF 32-bit LSB executable, Renesas SH, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, BuildID[sha1]=..., for GNU/Linux 3.2.0, not stripped
$ qemu-sh4 -L /usr/sh4-linux-gnu/ ./hello
Hello, World!
```

うん、いいかんじ。じゃあこれをBoCCHAN-1に転送して・・・あれ？転送ってどうやってやってるんだ？
シリアル接続してコンソールにD&Dってあれなにやってんの？

クイックスタートガイドだけではよく分からなかったので、ユーザーズマニュアルを見てみると、EclipseのttyConsoleの代わりにTera Term((そういえば作者の方がFF内...ひょええ))を使ったファイルのアップロード・ダウンロード方法が書いてありました。
読んでみると、Tera Termというより、それに付属しているZMODEMとかいうものでバイナリをやり取りしているみたいです。ZMODEMってなんぞ？

[https://ja.wikipedia.org/wiki/ZMODEM:title]

YMODEMというバイナリ転送プロトコルを改善したものらしい。1986年...生まれてねえ...

じゃあYMODEMってなんなの？

[https://ja.wikipedia.org/wiki/YMODEM:title]

ZMODEMよりは説明が詳しい。これは1985年。１年で名前変えたのか...

これはこれでXMODEMとかいうのを発展させたものらしいので、それも見てみる

[https://ja.wikipedia.org/wiki/XMODEM:title]

パソコン通信で広く使われてたそうな（こいつは何年なんだ...）。

さて、wikiだとあんまり使い方とかが分からなかったので色々と調べてみると、シリアル接続やtelnet接続、SSHなどでリモートにログインしている時に、受信側でrz、送信側でszを実行すると(速度は遅いが)バイナリが双方向に転送できるらしい。なるほど。

でもLinuxでTera Termとかは使えないし、出来れば端末内で済ませたいなあって思ったら、screenコマンドなるものがあったので使ってみた。
BoCCHAN-1をPCにつなぐと/dev/ttyUSB0が生えるので、screenコマンドを使って、ボードレート115200で接続する。

```
$ screen /dev/ttyUSB0 115200
```

BoCCHAN-1は電源を入れたらLinuxが起動して、自動的にログインまで済ましてくれているので、あとはZMODEMを使ってバイナリを転送する。

具体的には、BoCCHAN-1側でrzを実行したらCtrl+A+":exec sz hello"とかやればファイルが転送できる。

ようやくバイナリが転送出来たので、張り切ってBoCCHAN-1の上で実行してみる。

```
$ ./hello
sh: ./hello: not found
```

...は？

```
$ ls hello
hello
```

は？？？

なんでえええええええ（泣）

これ、１週間ぐらい理由が分かりませんでした。

最初は転送がうまく行かなかったのかとか色々考えて、配布された仮想環境でビルドしてできたバイナリを同じ方法で転送してみたりしたのですが、これはうまくいくんですよねえ・・・

原因は、うまく行く方とうまく行かない方のバイナリをfileコマンドにかけてみたら分かりました。CTFかよ。

うまく行かない方
```
$ file hello
hello: ELF 32-bit LSB executable, Renesas SH, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, BuildID[sha1]=..., for GNU/Linux 3.2.0, not stripped
```

うまく行く方
```
$ file hello
hello: ELF 32-bit LSB executable, Renesas SH, version 1 (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, not stripped
```

どうやら、インタプリタ(?)が違うようです。このインタプリタってなんぞ？
調べてみたら、ELFの共用ライブラリをmmapに配置するあいつでした。確かにそれ違ったら動かないよね
じゃあうまく行く方のELFインタプリタ、/lib/ld-uClibc.so.0ってなんなんだ・・・なんかlibcっぽい名前だな・・・

これも調べてみたら、uClibcという組み込み向けのlibc用のインタプリタ、みたいなかんじでした。
心の奥底で、「libcってglibcでしょ？」みたいな先入観が抜け切れていませんでしたね。

ということで、どうやらuClibcを使わなきゃいけないみたいですが、使用するlibcを変更するとかやろうとすると、gccの設定ファイル弄ったり色々しないといけないらしく、どうも面倒です。

でも、そういえば仮想環境の方では普通にsh4用のg++を使っているだけでした。つまり何らかの方法があるはずです。

ここで、ユーザーズマニュアルを眺めていたら、buildrootという文字列を見つけました。BoCCHAN-1で動いているLinuxはこいつを使ってビルドした、ということでbuildrootについて調べてみると、

[https://buildroot.org/:title]

```
Buildroot is a simple, efficient and easy-to-use tool to generate embedded Linux systems through cross-compilation.
```

組み込みLinux向けのクロスコンパイル用のツールを簡単に作る・・・？どういうことだ・・・？

[http://www.ne.jp/asahi/it/life/it/embedded/buildroot/buildroot_mips.html:embed:cite]

なるほど。組み込みLinux向けのクロスコンパイラやリンカ、さらにLinuxイメージまで作ってくれるものらしい。

```
$ make menuconfig
```

でTUIの分かりやすい画面で細かいところまで設定出来る。これは良い。ちょっとcrosstool-ngっぽい。

TOOLCHAINの"C library"を見てみたら、もうデフォルトでuClibcが選択されていた。これはいけそうだ。

本当は仮想環境のbuildrootとgccを同じバージョン、にしたり、色々と設定を合わせたりした方がいいのだろうが、面倒だったので、とりあえずTARGET ArchitectureをSuperH、Target Architecture Variantをsh4(SH4 Little Endian)に設定した。

ついでに、C++を使いたいので"GCC Options"の"Enable C++ support"にもチェックを入れておく((最初気づかなくてビルドし直した))。

これで.configに設定が保存されるので、makeして数時間ほど待つと、buildroot/output/host/usr/bin下にクロスコンパイラやリンカが大量に生える。

```
$ ls output/host/usr/bin
...
sh4-buildroot-linux-uclibc-g++
...
```

このコンパイラでビルドして、ZMODEMでBoCCHAN-1に転送すると...

```
$ ./hello
Hello, BoCCHAN-1!
```

ｷﾀｱｱｱｱｱ!!!

いやー時間かかりました。宇宙教育プログラム受講生でここまでしたの僕ぐらいでしょ（謎のイキリ）（無駄な努力）（素直に配布された環境使え）

今回作った開発環境もどきはGitHubに置いときました。

[https://github.com/sk2sat/BoCCHAN-1:embed:cite]

なんか間違ってるとことかあったらPRなりIssueなり頂けると嬉しいです（BoCCHAN-1ユーザーそんなにいないだろ

# 余談

[http://www.hodoyoshi.org/:title]

このサイト落ちてる（数年前は割と活動してたっぽい）し、色々とBoCCHAN-1とかほどよしSDKの情報少なすぎでは・・・

もっと情報がオープンになったらいいなーと思うので、CanSat合宿の時にでも木村教授に話してみたいです。

