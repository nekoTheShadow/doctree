= class IO < Object

include Enumerable
#@if (version >="1.8.0")
include File::Constants
#@end

IO クラスは基本的な入出力機能を実装します。

  * [[unknown:Traps: IO ポートのオープンに関わる問題|trap::IO]]

#@if (version >="1.8.0")
File::Constants は、[[c:File]] から移動しました。
#@end

== class methods

--- new(fd[, mode])
#@if (version >="1.8.0")
--- for_fd(fd[, mode])
--- open(fd[, mode])
--- open(fd[, mode]) {|io| ... }
#@end

オープン済みのファイルディスクリプタ fd に対する新しい
IO オブジェクトを生成して返します。IO オブジェクトの生
成に失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

mode には、[[m:File.open]] と同じ形式で IO のモードを指
定します(ただし、文字列形式のみ)。詳細は組み込み関数[[m:Kernel#open]]
を参照してください。
mode のデフォルト値は "r" です。

#@if (version >="1.8.0")
IO.for_fd は、IO.new と同じです。IO.open はブロックを持てる
点だけが異なります(ブロックの終了とともに fd はクローズされます)。

ブロックつき IO.open は、ブロックの結果を返します。それ以外は生成
した IO オブジェクトを返します。
#@end

#@if (version >="1.8.0")
mode の指定は完全に [[m:Kernel#open]],
[[m:File.open]] と同じです。(つまり、1.8 からは File::RDONLY
などの定数(数値)でモードを指定できます)
#@end

--- foreach(path[, rs]) {|line| ... }

path で指定されたファイルの各行に対して繰り返します
([[m:Kernel#open]] と同様 path の先頭が "|" ならば、コマ
ンドの出力を読み取ります)。ちょうど以下のような働きをします。

  port = open(path)
  begin
    port.each_line {|line|
       ...
    }
  ensure
    port.close
  end

path のオープンに成功すれば nil を返します。
失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

行の区切りは引数 rs で指定した文字列になります。rs の
デフォルト値は組み込み変数 [[m:$/]] の値です。

rs に nil を指定すると行区切りなしとみなします。
空文字列 "" を指定すると連続する改行を行の区切りとみなします
(パラグラフモード)。

--- pipe

[[man:pipe(2)]] を実行して、相互につながった2つの
[[c:IO]] オブジェクトを要素とする配列を返します。IO オブジェ
クトの作成に失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

戻り値の配列は最初の要素が読み込み側で、次の要素が書き込み側です。

例:

  p pipe = IO.pipe    # => [#<IO:0x401b90f8>, #<IO:0x401b7718>]
  pipe[1].puts "foo"
  p pipe[0].gets      # => "foo\n"

--- popen(command [, mode])
--- popen(command [, mode]) {|io| ... }

command をサブプロセスとして実行し、そのプロセスの標準入出力
との間にパイプラインを確立します。mode はオープンする IO ポー
トのモードを指定します(mode の詳細は [[m:Kernel#open]]
参照)。省略されたときのデフォルトは "r" です。

生成したパイプ([[c:IO]] オブジェクト)を返します。

例:

  p io = IO.popen("cat", "r+")  # => #<IO:0x401b75c8>
  io.puts "foo"
  p io.gets  # => "foo\n"

ブロックが与えられた場合は生成した IO オブジェクトを引数にブ
ロックを実行し、その結果を返します。ブロックの実行後、生成したパイ
プは自動的にクローズされます。

例:

  p IO.popen("cat", "r+") {|io|
    io.puts "foo"
    io.gets
  }
  # => "foo\n"

コマンド名が "-" の時、Ruby は [[man:fork(2)]] を
行い子プロセスの標準入出力との間にパイプラインを確立します。このと
きの戻りは、親プロセスは IO オブジェクトを返し、子プロセスは
nil を返します。ブロックがあれば、親プロセスは生成した
IO オブジェクトを引数にブロックを実行しその結果を返します。
(パイプはクローズされます)
子プロセスは nil を引数にブロックを実行し終了します。

例:

  # ブロックなしの例
  
  io = IO.popen("-", "r+")
  if io.nil?
    # child
    s = gets
    print "child output: " + s
    exit
  end
  
  # parent
  io.puts "foo"
  p io.gets                   # => "child output: foo\n"
  io.close
  
  # ブロックありの例
  
  p IO.popen("-", "r+") {|io|
    if io
      # parent
      io.puts "foo"
      io.gets
    else
      # child
      s = gets
      puts "child output: " + s
    end
  }
  # => "child output: foo\n"

パイプ、あるいは子プロセスの生成に失敗した場合は例外
[[c:Errno::EXXX]] が発生します。

#@if (version >="1.9.0")
command が配列の場合は、シェルを経由せずに子プロセスを実行し
ます。
#@end

#@if (version >="1.8.0")
--- read(path,[length,[offset]])

path で指定されたファイルを offset 位置から
length バイト分読み込んで返します。ちょうど以下のような働き
をします。

  port = open(path)
  port.pos = offset if offset
  begin
    port.read length
  ensure
    port.close
  end

length が nil であるか省略した場合には、EOF まで読み込
みますが、IO が既に EOF に達していれば "" を返します。
したがって、IO.read(空ファイル) は "" となります。

length に具体的な長さを指定した場合には、その長さを読み込みますが、
IO が既に EOF に達していれば nil を返します。

path のオープン、offset 位置への設定、ファイルの読み込
みに失敗した場合は例外 [[c:Errno::EXXX]] が発生します。
length が負の場合、例外 [[c:ArgumentError]] が発生します。
#@end

--- readlines(path[, rs])

path で指定されたファイルを全て読み込んで、その各行を要素と
してもつ配列を返します。
IO が既に EOF に達していれば空配列 [] を返します。

ちょうど以下のような働きをします。

  port = open(path)
  begin
    port.readlines
  ensure
    port.close
  end

行の区切りは引数 rs で指定した文字列になります。rs の
デフォルト値は組み込み変数 [[m:$/]] の値です。

rs に nil を指定すると行区切りなしとみなします。
空文字列 "" を指定すると連続する改行を行の区切りとみなします
    (パラグラフモード)。

path のオープン、ファイルの読み込みに失敗した場合は例外
[[c:Errno::EXXX]] が発生します。

--- select(reads[, writes[, excepts[, timeout]]])

[[man:select(2)]] を実行します。
reads/writes/exceptsには、入力待ちする
[[c:IO]] (またはそのサブクラス)のインスタンスの配列を渡します。

timeout は整数、[[c:Float]] または nil(省略
時のデフォルト値)を指定します。nil を指定した時に
は IO がレディ状態になるまで待ち続けます。
整数、[[c:Float]]で指定したときは単位は秒です。

戻り値は、timeout した時には nil を、そうで
ないときは 3 要素の配列を返し、その各要素が入力/出力/例外
待ちのオブジェクトの配列です(指定した配列のサブセット)。

[[m:Kernel#select]] と同じです。

#@if (version >="1.8.0")
--- sysopen(path[, mode [, perm]])

pathで指定されるファイルをオープンし、ファイル記述子を返しま
す。ファイルのオープンに失敗した場合は例外 [[c:Errno::EXXX]] が発
生します。

引数 mode, perm については 組み込み関数
[[m:Kernel#open]] と同じです。

[[m:IO.for_fd]] などで IO オブジェクトにしない限り、このメソッ
ドでオープンしたファイルをクローズする手段はありません。
#@# あらい 2002-08-03 たぶん
#@end

== Instance Methods

--- <<(object)

object を出力します。object が文字列でない時にはメソッ
ド to_s を用いて文字列に変換します。self を戻り値とす
るので、以下のような << の連鎖を使うことができます。

  STDOUT << 1 << " is a " << Fixnum << "\n"

出力に失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

--- binmode

ストリームをバイナリモードにします。MSDOS などバイナリモードの存在
する OS でのみ有効です(そうでない場合このメソッドは何もしません)。
バイナリモードから通常のモードに戻す方法は再オープンしかありません。

self を返します。

--- clone
--- dup

レシーバと同じ IO を参照する新しい IO オブジェクトを返します。
(参照しているファイル記述子は [[man:dup(2)]] されます)
clone の際に self は一旦 [[m:IO#flush]] されます。

フリーズした IO の clone は同様にフリーズされた IO を返しますが、
dup は内容の等しいフリーズされていない IO を返します。

--- close

入出力ポートをクローズします。

以後このポートに対して入出力を行うと例外 [[c:IOError]] が発生しま
す。ガーベージコレクトの際にはクローズされていない IO ポートはクロー
ズされます。[[unknown:Traps:closeをGCにまかせる|trap::IO]]

close に失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

self がパイプでプロセスにつながっていれば、そのプロセスの終
了を待ち合わせます。

nil を返します。

--- close_read

読み込み用の IO を close します。主にパイプや読み書き両用に作成し
た IO オブジェクトで使用します。

self が読み込み用にオープンされていなければ、例外
[[c:IOError]] が発生します。

close に失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

nil を返します。

--- close_write

書き込み用の IO を close します。

self が書き込み用にオープンされていなければ、例外
[[c:IOError]] が発生します。

close に失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

nil を返します。

--- closed?

ポートがクローズされている時に真を返します。

--- each([rs]) {|line| ... }
--- each_line([rs]) {|line| ... }

IO ポートから 1 行ずつ読み込んで繰り返すイテレータ。IO ポートはリー
ドモードでオープンされている必要があります
([[m:Kernel#open]] 参照)。

行の区切りは引数 rs で指定した文字列になります。rs の
デフォルト値は組み込み変数 [[m:$/]] の値です。

rs に nil を指定すると行区切りなしとみなします。
空文字列 "" を指定すると連続する改行を行の区切りとみなします
(パラグラフモード)。

self を返します。

--- each_byte {|ch| ... }

IO ポートから 1 バイトずつ読み込みます。IO ポートはリードモードで
オープンされている必要があります([[m:Kernel#open]]参照)。

self を返します。

--- eof
--- eof?

ストリームがファイルの終端に達した場合真を返します。

--- fcntl(cmd[, arg])

IOに対してシステムコール fcntl を実行します。
機能の詳細は [[man:fcntl(2)]] を参照してください。

arg が整数の時にはその値を、true または false の場合はそれぞ
れ 1 または 0 を、文字列の場合には pack した構造体だとみなしてその
まま [[man:fcntl(2)]] に渡します。arg の省略時の値
は 0 です。

cmd に対して指定できる定数は、添付ライブラリ [[lib:fcntl]] が提供しています。

fcntl(2) が返した数値を返します。fcntl(2) の実行に失敗
した場合は例外 [[c:Errno::EXXX]] が発生します。

#@if (version >= "1.8.0")
--- fsync

書き込み用の IO に対して、システムコール [[man:fsync(2)]]
を実行します。[[m:IO#flush]]を行ったあと(OSレベルで)まだディスクに
書き込まれていないメモリ上にあるデータをディスクに書き出します。

成功すれば 0 を返します。失敗した場合は例外 [[c:Errno::EXXX]] が発
生します。self が書き込み用でなければ例外 [[c:IOError]] が発
生します。
#@end

--- fileno
--- to_i

ファイル記述子の番号を返します。

--- flush

IO ポートの内部バッファをフラッシュします。
self が書き込み用でなければ例外 [[c:IOError]] が発
生します。

self を返します。

--- getc

IO ポートから 1 文字読み込んで、その文字に対応する [[c:Fixnum]] を
返します。EOF に到達した時には nil を返します。

--- gets([rs])

一行読み込んで、読み込みに成功した時にはその文字列を返します。
ファイルの終りに到達した時には nil を返します。
[[m:IO#each]] と同じように動作します
が、こちらは 1 行返すだけで繰り返しません。

行の区切りは引数 rs で指定した文字列になります。rs の
デフォルト値は組み込み変数 [[m:$/]] の値です。

rs に nil を指定すると行区切りなしとみなします。
空文字列 "" を指定すると連続する改行を行の区切りとみなします
(パラグラフモード)。

IO#gets は[[m:Kernel#gets]] 同様、読み込んだ文字列を変数
$_ にセットします。

--- ioctl(cmd[, arg])

IO に対してシステムコール ioctl を実行し、その結果を返します。
機能の詳細は [[man:ioctl(2)]] を参照してください。

arg が整数の時にはその値を、文字列の場合には
[[m:Array#pack]] した構造体だとみなしてioctl に渡します。
arg が省略されたときや、nil, false のときは 0、
true に対しては 1 を ioctl に渡します。

--- isatty
--- tty?

入出力ポートがttyに結合している時、真を返します。

--- lineno

現在の行番号を返します。

--- lineno=(number)

行番号をセットします。

--- pid

[[m:IO.popen]] で作られたIOポートなら、子プロセスのプロセス ID を
返します。それ以外は nil を返します。

--- pos
--- tell

ファイルポインタの現在の位置を返します。

--- pos=(n)

ファイルポインタを指定位置に移動します。
io.seek(pos, IO::SEEK_SET)と同じです。

--- print([arg[, ...]])

引数を IO ポートに順に出力します。引数を省略した場合は、
[[m:$_]] を出力します。
引数の扱いは [[m:Kernel#print]] と同じです(詳細はこちらを参照
してください)。

nil を返します。

--- printf(format[, arg[, ...]])

C 言語の printf と同じように、format に従い引数
を文字列に変換して、self に出力します。

第一引数に IO を指定できないこと、引数を省略できないことを除
けば [[m:Kernel#printf]] と同じです。
引数の扱いの詳細については [[unknown:sprintfフォーマット]] を参照してください。

nil を返します。

--- putc(ch)

文字 ch を self に出力します。
引数の扱いは [[m:Kernel#putc]] と同じです(詳細はこちらを参照し
てください)。

ch を返します。

--- puts([obj[, ...]])

各 obj を self に出力した後、改行します。
引数の扱いは [[m:Kernel#puts]] と同じです(詳細はこちらを参照し
てください)。

nil を返します。

--- read([length])
#@if (version >= "1.8.0")
--- read([length[, outbuf]])
#@end

length が指定された場合、
length バイト読み込んで、その文字列を返します。
IO が既に EOF に達していれば nil を返します。

length が省略された時には、EOF までの全てのデータを読み込みます。
IO が既に EOF に達している場合 "" を返します。
したがって、open(空ファイル) {|f| f.read } は "" となります。

データの読み込みに失敗した場合は例外 [[c:Errno::EXXX]] が発生しま
す。length が負の場合、例外 [[c:ArgumentError]] が発生します。

#@if (version >= "1.8.0")
第二引数として文字列を指定すると、読み込ん
だデータをその文字列オブジェクトに上書きして返します。指定した文字
列オブジェクトがあらかじめ length 長の領域であれば、余計なメ
モリの割当てが行われません。指定した文字列の長さが length と
異なる場合、その文字列は一旦 length 長に拡張(あるいは縮小)さ
れます(そして、実際に読み込んだデータのサイズになります)。

第二引数を指定した read の呼び出しでデータが空であった場合
(read がnil を返す場合)、outbuf は空文字列になりま
す。

例:

  outbuf = "x" * 20;
  io = File.open("/dev/null")
  p io.read(10,outbuf)
  p outbuf
  => nil
     ""
#@end

#@if (version >= "1.9.0")
read(0) は常に "" を返します。
#@end

--- readchar

[[m:IO#getc]] と同様に 1 文字読み込んで、その文字に対応す
る [[c:Fixnum]] を返しますが、EOF に到達した時に例外
[[c:EOFError]] を発生させます。

--- readline([rs])

[[m:IO#gets]] と同様に 1 行読み込みその文字列を返しますが、
EOF に到達した時に例外 [[c:EOFError]] を発生させます。

行の区切りは引数 rs で指定した文字列になります。rs の
デフォルト値は組み込み変数 [[m:$/]] の値です。

rs に nil を指定すると行区切りなしとみなします。
空文字列 "" を指定すると連続する改行を行の区切りとみなします
    (パラグラフモード)。

readline は gets 同様読み込んだ文字列を変数 $_
にセットします。

--- readlines([rs])

データを全て読み込んで、その各行を要素としてもつ配列を返します。
IO が既に EOF に達していれば空配列 [] を返します。

行の区切りは引数 rs で指定した文字列になります。rs の
デフォルト値は組み込み変数 [[m:$/]] の値です。

rs に nil を指定すると行区切りなしとみなします。
空文字列 "" を指定すると連続する改行を行の区切りとみなします
(パラグラフモード)。

#@if (version >= "1.8.5")
--- read_nonblock(maxlen[, outbuf])

IO をノンブロッキングモードに設定し、
その後で read(2) システムコールにより
長さ maxlen を上限として読み込み、文字列として返します。

文字列 outbuf が指定された場合、
読み込んだデータを outbuf に破壊的に格納し、
返り値は outbuf となります。

read_nonblock は read(2) システムコールを呼びます。
その結果として起きたエラーは EAGAIN, EINTR などをふくめ、
すべてが [[c:Errno::EXXX]] 例外として呼出元に報告されます。

read(2) システムコールが 0 を返した場合は
EOFError となります。

なお、バッファが空でない場合は、
read_nonblock はバッファから読み込みます。
この場合、read(2) システムコールは呼ばれません。
#@end

#@if (version >= "1.8.3")
--- readpartial(maxlen[, outbuf])

IO から長さ maxlen を上限として読み込み、文字列として返します。
ここで、即座に得られるデータが存在しないときにはブロックしてデータの到着を待ちますが、
即座に得られるデータが 1byte でも存在すればブロックしません。
第二引数 outbuf として文字列を指定すると、
読み込んだデータを outbuf に上書きして返します。
IO が既に EOF に達していれば例外 [[c:EOFError]] を発生させます。

readpartial はブロックを最小限に抑えることによって、
パイプ、ソケット、端末などのストリームに対して適切に動作するよう設計されています。
readpartial がブロックするのは次の全ての条件が満たされたときだけです。
  * IO オブジェクト内のバッファが空
  * ストリームにデータが到着していない
  * ストリームが EOF になっていない
これらの条件が満たされる場合、何らかのデータが到着するか EOF になるまで readpartial はブロックします。

readpartial の結果は以下のようになります。
  (1) バッファが空でなければ、そのバッファのデータを読み込んで返します。
  (2) ストリームにデータがあれば、ストリームからデータを読み込んで返します。
  (3) ストリームが EOF になっていれば、例外 [[c:EOFError]] を発生させます。

例えば、パイプに対しては次のように動作します。

  r, w = IO.pipe           #               buffer          pipe content
  w << "abc"               #               ""              "abc".
  r.readpartial(4096)      #=> "abc"       ""              ""
  r.readpartial(4096)      # バッファにもパイプにもデータがないのでブロックする
  
  r, w = IO.pipe           #               buffer          pipe content
  w << "abc"               #               ""              "abc"
  w.close                  #               ""              "abc" EOF
  r.readpartial(4096)      #=> "abc"       ""              EOF
  r.readpartial(4096)      # 例外 EOFError 発生
  
  r, w = IO.pipe           #               buffer          pipe content
  w << "abc\ndef\n"        #               ""              "abc\ndef\n"
  r.gets                   #=> "abc\n"     "def\n"         ""
  w << "ghi\n"             #               "def\n"         "ghi\n"
  r.readpartial(4096)      #=> "def\n"     ""              "ghi\n"
  r.readpartial(4096)      #=> "ghi\n"     ""              ""

なお、readpartial は nonblock フラグに影響されません。
つまり、nonblock フラグが設定されていて sysread であれば Errno::EAGAIN になる場合でもブロックします。

また、readpartial の挙動は sysread によく似ています。
とくに、バッファが空の場合には同じ挙動を示します。
ただし、EAGAIN および EINTR エラーは内部で発生したとしても通知されず、データが到着するまでブロックし続けます。
#@end

--- reopen(io)
--- reopen(name[, mode])

自身を io に繋ぎ換えます。クラスも io に等しくなります
(注意)。

第一引数が文字列の時、name で指定されたファイルにストリーム
を繋ぎ換えます。

第二引数のデフォルト値は "r" です。
#@if (version >= "1.8.0")
第二引数を省略したとき self のモード
をそのまま引き継ぎます。
#@end

self を返します。

--- rewind

ファイルポインタを先頭に移動します。IO#lineno は 0 になります。

--- seek(offset[, whence])

ファイルポインタを whence の位置から offset だけ移動させます。
whence の値は以下のいずれかです。

  * IO::SEEK_SET: ファイルの先頭から (デフォルト)
  * IO::SEEK_CUR: 現在のファイルポインタから
  * IO::SEEK_END: ファイルの末尾から

whence の省略値は IO::SEEK_SET です。

offset 位置への移動が成功すれば 0 を返します。
失敗した場合は例外 [[c:Errno::EXXX]] が発生します。

--- stat

ファイルのステータスを含む [[c:File::Stat]] オブジェクトを生成して
返します。

ステータスの読み込みに失敗した場合は例外 [[c:Errno::EXXX]] が発生
します。

[[m:File#lstat]],
[[m:File.stat]],
[[m:File.lstat]] も参照してください。

--- sync

現在の出力同期モードを真偽値で返します。同期モードが真の時は
出力関数の呼出毎にバッファがフラッシュされます。

--- sync=(newstate)

出力同期モードを設定します。
newstate が真なら同期モード、偽なら非同期モードになります。
newstate を返します。

--- sysread(maxlen)
#@if (version >= "1.8.0")
--- sysread(maxlen[, outbuf])
#@end

[[man:read(2)]] を用いて入力を行ない、入力されたデータを
含む文字列を返します。ファイルの終りに到達した時には例外
[[c:EOFError]] を発生させます。stdio を経由しないので
gets や getc や eof? などと混用すると思わぬ動作
をすることがあります。

データの読み込みに失敗した場合は例外 [[c:Errno::EXXX]] が発生しま
す。

#@if (version >= "1.8.0")
第二引数として文字列を指定すると、読み込ん
だデータをその文字列オブジェクトに上書きして返します。指定した文字
列オブジェクトがあらかじめ maxlen 長の領域であれば、余計なメ
モリの割当てが行われません。指定した文字列の長さが maxlen と
異なる場合、その文字列は一旦 maxlen 長に拡張(あるいは縮小)さ
れます(そして、実際に読み込んだデータのサイズになります)。

第二引数を指定した sysread の呼び出しでデータが空であった場
合(sysread が例外 [[c:EOFError]] を発生させる場合)、
outbuf は空文字列になります。

例:

  outbuf = "x" * 20;
  io = File.open("/dev/null")
  p((io.sysread(10,outbuf) rescue nil))
  p outbuf
  => nil
     ""
#@end

#@if (version >="1.8.0")
--- sysseek(offset[, whence])

[[man:lseek(2)]] と同じです。[[m:IO#seek]] では、
[[m:IO#sysread]], [[m:IO#syswrite]] と併用すると正しく動作しないの
で代わりにこのメソッドを使います。

読み込み用にバッファリングされた IO に対して実行すると例外
[[c:IOError]] が発生します。
書き込み用にバッファリングされた IO に対して実行すると警告が出ます。

  File.open("/dev/zero") {|f|
    buf = f.read(3)
    f.sysseek(0)
  }
  # => -:3:in `sysseek': sysseek for buffered IO (IOError)
  
  File.open("/dev/null", "w") {|f|
    f.print "foo"
    f.sysseek(0)
  }
  # => -:3: warning: sysseek for buffered IO

引数は [[m:IO#seek]] と同じです。

offset 位置への移動が成功すれば移動した位置(ファイル先頭から
の位置)を返します。移動に失敗した場合は例外 [[c:Errno::EXXX]] が発
生します。
#@end

--- syswrite(string)

[[man:write(2)]] を用いて string を出力します。
string が文字列でなければ to_s による文字列化を試みます。
stdio を経由しないので他の出力メソッドと混用すると思わぬ動作
をすることがあります。

実際に出力できたバイト数を返します。出力に失敗した場合は例外
[[c:Errno::EXXX]] が発生します。

--- to_io

self を返します。

--- ungetc(char)

char を読み戻します。2バイト以上の読み戻しは保証されません。

nil を返します。

--- write(str)

IOポートに対して str を出力します。str が文字列でなけ
れば to_s による文字列化を試みます。

[[m:IO#syswrite]] を除く全ての出力メソッドは、最終的に
"write" という名のメソッドを呼び出すので、このメソッドを置き換える
ことで出力関数の挙動を変更することができます。
#@if (version >= "1.8.0")
以前は[[m:Kernel#putc]],
[[m:IO#putc]] に対してだけこのことは適用されませんでした
[[unknown:ruby-dev:16305]]が、修正されました[[unknown:ruby-dev:18038]]-))
#@end

実際に出力できたバイト数を返します。出力に失敗した場合は例外
[[c:Errno::EXXX]] が発生します。

#@if (version >= "1.8.5")
--- write_nonblock(string)

IO をノンブロッキングモードに設定し、
その後で string を write(2) システムコールで書き出します。

write(2) が成功した場合、返り値は書き込んだ長さとなります。

write(2) が失敗した場合、例外 [[c:Errno::EXXX]] が発生します。
ここで、EAGAIN, EINTR なども単に例外として呼出元に報告されます。
#@end

#@since 1.9.0
#@# bc-rdoc: detected missing name: bytes
--- bytes   
#@#=> anEnumerator

Returns an enumerator that gives each byte in the string.

   "hello".bytes.to_a        #=> [104, 101, 108, 108, 111]

#@# bc-rdoc: detected missing name: lines
--- lines(separator=$/)   
#@#=> anEnumerator

Returns an enumerator that gives each line in the string.

   "foo\nbar\n".lines.to_a   #=> ["foo\n", "bar\n"]
   "foo\nb ar".lines.sort    #=> ["b ar", "foo\n"]
#@end

== Constants

--- SEEK_CUR

--- SEEK_END

--- SEEK_SET

[[m:IO#seek]] を参照してください。
