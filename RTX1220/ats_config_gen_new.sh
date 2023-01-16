#!/bin/sh

#
# 参考: ルーター 複数のL2TPクライアント(アドレス不定)の接続を受け付ける場合
# https://network.yamaha.com/setting/router_firewall/vpn/vpn_client/vpn-smartphone-setup_rtx1200
#

# 引数チェック

if [ $# != 2 ]; then
  echo "Usage: ./ats_config_gen.sh [user name] [tunnel number]" 1>&2
  exit 1
fi

USER_NAME=$1
PASSWORD="${USER_NAME}_`head -c 10 /dev/random | base64 | tr -dc 'a-zA-Z0-9' | cut -c 1-6`"

TUNNEL_NUMBER=$2

DATE=`date "+%Y-%m-%d %H:%M:%S %Z"`
FILEDATE=`date "+%Y%m%d%H%M%S"`

CONFIG_FILE_NAME="${FILEDATE}_ats_config"
ACCESS_INFO_FILE_NAME="${FILEDATE}_ats_access_info"

echo "##
## This is a-tune tunneling service (ats) configuration file.
## generated by ats_config_gen.sh in $DATE
##
" > $CONFIG_FILE_NAME

echo "##
## This is a-tune tunneling service (ats) access information file.
## generated by ats_config_gen.sh in $DATE
##
" > $ACCESS_INFO_FILE_NAME

echo "#
# 参考: ルーター 複数のL2TPクライアント(アドレス不定)の接続を受け付ける場合
# https://network.yamaha.com/setting/router_firewall/vpn/vpn_client/vpn-smartphone-setup_rtx1200
#" >> $CONFIG_FILE_NAME

echo "
console character ja.utf8" >> $CONFIG_FILE_NAME

echo "
#
# ゲートウェイの設定
#
ip route default gateway 133.1.244.30" >> $CONFIG_FILE_NAME

echo "
#
# LANインターフェースの設定
#
ip lan1 address 192.168.14.103/24
ip lan1 proxyarp on" >> $CONFIG_FILE_NAME

echo "
# WAN in ODINS

ip lan2 address 133.1.244.21/27" >> $CONFIG_FILE_NAME

echo "
#
# NATの設定
#

ip lan2 nat descriptor 1
nat descriptor type 1 masquerade
nat descriptor address outer 1 primary
nat descriptor masquerade static 1 1 192.168.100.1 esp
nat descriptor masquerade static 1 2 192.168.100.1 udp 500
nat descriptor masquerade static 1 3 192.168.100.1 udp 4500" >> $CONFIG_FILE_NAME

echo "
#dhcp scope 1 192.168.100.10-192.168.100.100/24" >> $CONFIG_FILE_NAME

ARG=""
for i in `seq $TUNNEL_NUMBER`
do
  ARG="${ARG}tunnel$i "
done
ARG=`echo $ARG | sed "s/ $//"` # 末尾の空白を削除しているだけ、あまり意味はない

echo "
#
# L2TP接続を受け入れるための設定
#
pp select anonymous
pp bind $ARG
pp auth request chap-pap
pp auth username $USER_NAME $PASSWORD
ppp ipcp ipaddress on
ppp ipcp msext on
ip pp remote address pool 192.168.14.64-192.168.14.95
ip pp mtu 1258
pp enable anonymous" >> $CONFIG_FILE_NAME

echo "user_name: $USER_NAME
password: $PASSWORD" >> $ACCESS_INFO_FILE_NAME

for i in `seq $TUNNEL_NUMBER`
do

  PRE_SHARED_KEY=`head -c 32 /dev/random | base64 | tr -dc 'a-zA-Z0-9' | cut -c 1-32`

  echo "
#
# tunnel $i
#
tunnel select $i
tunnel encapsulation l2tp
ipsec tunnel $((100 + $i))
ipsec sa policy $((100 + $i)) $i esp aes-cbc sha-hmac
ipsec ike keepalive use $i off
ipsec ike local address $i 192.168.14.103
ipsec ike nat-traversal $i on
ipsec ike pre-shared-key $i text $PRE_SHARED_KEY
ipsec ike remote address $i any
l2tp tunnel disconnect time off
l2tp keepalive use on 10 3
l2tp keepalive log on
l2tp syslog on
ip tunnel tcp mss limit auto
tunnel enable $i" >> $CONFIG_FILE_NAME

  echo "%%
tunnel$i preshared: $PRE_SHARED_KEY" >> $ACCESS_INFO_FILE_NAME
done

echo "
#
# IPsecのトランスポートモード設定
#" >> $CONFIG_FILE_NAME

for i in `seq $TUNNEL_NUMBER`
do
  echo "ipsec transport $i $(($i + 100)) udp 1701" >> $CONFIG_FILE_NAME
done

echo "ipsec auto refresh on" >> $CONFIG_FILE_NAME

echo "
#
# L2TPの設定
#
l2tp service on" >> $CONFIG_FILE_NAME

echo "
#
# DNSの設定
#
dns server 192.168.14.51 192.168.14.53
dns private address spoof on" >> $CONFIG_FILE_NAME

echo "
#
# NTPの設定
#
schedule at 1 */* 18:00 * ntpdate ntp-s.odins.osaka-u.ac.jp" >> $CONFIG_FILE_NAME