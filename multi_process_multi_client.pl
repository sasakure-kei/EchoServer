#!/opt/local/bin//perl

use strict;
use warnings;

use Socket;

my $port = 5000;
# ソケットの生成
socket(CLIENT_WAITING, PF_INET, SOCK_STREAM, 0) or die $!;

# オプションの指定
setsockopt(CLIENT_WAITING, SOL_SOCKET, SO_REUSEADDR, 1) or die $!;

# bindは「ソケット」と「ボートとIPアドレス」を紐づける
# 複数IP割当られてるサーバーを利用するときは INADDR_ANYの代わりに
# inet_aton("192.168.0.1"); というようにすればいいっぽい。
bind(CLIENT_WAITING, pack_sockaddr_in($port, INADDR_ANY)) or die $!;

# listenはOSへの指示
# コネクションを成立させ待たせる数を指定する
listen(CLIENT_WAITING, SOMAXCONN) or die $!;

print "echoサーバーに挑戦\n";
print "ポート $port を使用します。\n";

while (1) {
  # acceptで行列の先頭のお客様をご案内する
  my $paddr = accept(CLIENT, CLIENT_WAITING);

  # クライアントの情報を取得する
  # pack_sockaddr_inとは逆で、アドレス情報をunpackすると
  # 「ポートとinet_atonで作ったようなIPアドレス?」が取得出来る
  my ($client_port, $client_iaddr) = unpack_sockaddr_in($paddr);
  my $client_hostname = gethostbyaddr($client_iaddr, AF_INET);
  my $client_ip = inet_ntoa($client_iaddr);

  print "接続: $client_hostname ($client_ip) ポート $client_port\n";

  # fork()でクローン(子プロセス)を生成し、
  # ここから同じ処理が同じ状態で動き出すことになる。
  # 違いとしては親プロセスにはforkの返り値として
  # 子プロセスIDが取得出来る。
  if (my $pid = fork()) {
    # 親プロセス処理
    print "親プロセス処理を実行します。: $$\n";

    close(CLIENT);
    next;
  } else {
    # 子プロセス処理
    print "子プロセス処理を実行します。: $$\n";

    # CLIENTに対する出力はバッファリングしないように
    select (CLIENT); $|=1; select (STDOUT);

    while (<CLIENT>) {
      print "メッセージ: $_";
      print CLIENT $_;
    }

    close(CLIENT);
    print "クライアントの接続が切れました。\n";

    # 子プロセスは終了
    exit;
  }
}
