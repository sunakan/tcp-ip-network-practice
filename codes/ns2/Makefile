#ping:
#	ping -c 3 8.8.8.8
ipaddressshow:
	ip address show
tcpdump-icmp:
	sudo tcpdump -tn --interface any icmp
traceroute-google:
	traceroute -n 8.8.8.8
iprouteshow:
	ip route show

################################################################################
# Network Namespace2個
################################################################################
# ns1-veth0(192.0.2.1)____________________ns2-veth0(192.0.2.2)
################################################################################
export NS_1=ns1
export NS_2=ns2
export NS_1_VETH=ns1-veth0
export NS_2_VETH=ns2-veth0
export NS_1_VETH_IP=192.0.2.1
export NS_2_VETH_IP=192.0.2.2
export NS_1_VETH_MACADDR=00:00:5E:00:53:01
export NS_2_VETH_MACADDR=00:00:5E:00:53:02

all:
	make add-netns        # NetworkNamespaceを作成
	ip netns list         # NetworkNamespaceを一覧
	make add-veth-peer    # vethインターフェースのpeeringを追加
	make set-veth         # vethインターフェースを対応するNetworkNamespaceにセット
	make up-veth          # vethインターフェースを有効化
	make set-ipaddr       # vethインターフェースにIPアドレスを付与
	make set-macaddr      # vethインターフェースにMACアドレスをセット
	make ping             # 接続確認ping

# 別shellでパケットキャプチャ
# 最初でMACアドレスのキャッシュをクリア（ARPによるアドレス解決を観察したい）
tcpdump:
	sudo ip netns exec ${NS_1} ip neigh flush all
	sudo ip netns exec ${NS_1} tcpdump -tnel -i ${NS_1_VETH} icmp or arp

# 存在するなら作成しない
# $1：作りたいNetworkNamespace名
define add-netns
	( ip netns list | grep $1 ) \
		|| sudo ip netns add $1
endef
add-netns:
	$(call add-netns, ${NS_1})
	$(call add-netns, ${NS_2})

# 存在するなら作成しない
# $1：VETHペアを入れる予定のNetworkNamespace名
# $2：VETHペアの片方
# $3：VETHペアの片方（ルータ側）
define add-veth-peer
	( ip link show type veth | grep $2 ) \
		|| sudo ip netns exec $1 ip link show $2 \
		|| sudo ip link add $2 type veth peer name $3
endef
add-veth-peer:
	$(call add-veth-peer, ${NS_1}, ${NS_1_VETH}, ${NS_2_VETH})

# セット済みなら、セットしない
# $1：セットしたい先
# $2：セットしたいvethインターフェース名
define set-veth
	sudo ip netns exec $1 ip link show $2 \
		|| sudo ip link set $2 netns $1
endef
set-veth:
	$(call set-veth, ${NS_1}, ${NS_1_VETH})
	$(call set-veth, ${NS_2}, ${NS_2_VETH})

# UP済みでも全く問題ない（冪等性OK）
# $1：有効化したいvethインターフェースがあるNetworkName名
# $2：有効化したいvethインターフェース名
define up-veth
	sudo ip netns exec $1 ip link set $2 up
endef
up-veth:
	$(call up-veth, ${NS_1}, ${NS_1_VETH})
	$(call up-veth, ${NS_2}, ${NS_2_VETH})

# セット済みならセットしない
# $1：IPアドレスをセットしたいvethインターフェースがあるNamespace名
# $2：IPアドレスをセットしたいvethインターフェース名
# $3：IPアドレス
define set-ipaddr
	( sudo ip netns exec $1 ip address show $2 | grep $3 ) \
		|| sudo ip netns exec $1 ip address add $3/24 dev $2
endef
set-ipaddr:
	$(call set-ipaddr, ${NS_1}, ${NS_1_VETH}, ${NS_1_VETH_IP})
	$(call set-ipaddr, ${NS_2}, ${NS_2_VETH}, ${NS_2_VETH_IP})

# 上書きなので冪等性OK
# $1：MACアドレスをセットしたいvethインターフェースがあるNamespace名
# $2：MACアドレスをセットしたいvethインターフェース名
# $3：MACアドレス
define set-macaddr
	sudo ip netns exec $1 ip link set dev $2 address $3
endef
set-macaddr:
	$(call set-macaddr, ${NS_1}, ${NS_1_VETH}, ${NS_1_VETH_MACADDR})
	$(call set-macaddr, ${NS_2}, ${NS_2_VETH}, ${NS_2_VETH_MACADDR})

define ping
	sudo ip netns exec $1 ping -c 2 $2 -I $3
endef
ping:
	$(call ping, ${NS_1}, ${NS_2_VETH_IP}, ${NS_1_VETH_IP})

clean:
	sudo ip -all netns delete
	sudo ip link delete ${MY_NETWORK_VETH_NAME_1} || echo OK
