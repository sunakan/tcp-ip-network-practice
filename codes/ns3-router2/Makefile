##################################################################################
# Network Namespace3個、Router2個
################################################################################
# ns1-veth0(192.0.2.1)____________________
#                                |
#                             gw1-veth0(192.0.2.254)
#                             router1
#                             gw1-veth1(203.0.113.1)
#________________________________|________
#    |
# gw2-veth0(203.0.113.2)
# router2
# gw2-veth1(198.51.100.254)
# ___|__________________________ns2-veth0(198.51.100.1)
################################################################################
export NS_1=ns1
export NS_2=ns2
export ROUTER_1=router1
export ROUTER_2=router2
export NS_1_VETH=ns1-veth0
export NS_2_VETH=ns2-veth0
export ROUTER_1_VETH_0=gw1-veth0
export ROUTER_1_VETH_1=gw1-veth1
export ROUTER_2_VETH_0=gw2-veth0
export ROUTER_2_VETH_1=gw2-veth1
export NS_1_VETH_IP=192.0.2.1
export NS_2_VETH_IP=198.51.100.1
export ROUTER_1_VETH_0_IP=192.0.2.254
export ROUTER_1_VETH_1_IP=203.0.113.1
export ROUTER_2_VETH_0_IP=203.0.113.2
export ROUTER_2_VETH_1_IP=198.51.100.254
export NS_1_NETWORK_CIDR=192.0.2.0/24
export NS_2_NETWORK_CIDR=198.51.100.0/24

all:
	make add-netns        # NetworkNamespaceを作成
	ip netns list         # NetworkNamespaceを一覧
	make add-veth-peer    # vethインターフェースのpeeringを追加
	make set-veth         # vethインターフェースを対応するNetworkNamespaceにセット
	make up-veth          # vethインターフェースを有効化
	make set-ipaddr       # vethインターフェースにIPアドレスを付与
	make enable-ipforward # routerのip_forwardを有効化する
	make add-route        # NetworkNamespaceのルーティングテーブルに、別NetworkNamespaceへのルーティングエントリを追加
	make ping             # 接続確認ping

# 存在するなら作成しない
# $1：作りたいNetworkNamespace名
define add-netns
	( ip netns list | grep $1 ) \
		|| sudo ip netns add $1
endef
add-netns:
	$(call add-netns, ${NS_1})
	$(call add-netns, ${NS_2})
	$(call add-netns, ${ROUTER_1})
	$(call add-netns, ${ROUTER_2})

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
	$(call add-veth-peer, ${NS_1}, ${NS_1_VETH}, ${ROUTER_1_VETH_0})
	$(call add-veth-peer, ${NS_2}, ${NS_2_VETH}, ${ROUTER_2_VETH_1})
	$(call add-veth-peer, ${ROUTER_1}, ${ROUTER_1_VETH_1}, ${ROUTER_2_VETH_0})

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
	$(call set-veth, ${ROUTER_1}, ${ROUTER_1_VETH_0})
	$(call set-veth, ${ROUTER_1}, ${ROUTER_1_VETH_1})
	$(call set-veth, ${ROUTER_2}, ${ROUTER_2_VETH_0})
	$(call set-veth, ${ROUTER_2}, ${ROUTER_2_VETH_1})

# UP済みでも全く問題ない（冪等性OK）
# $1：有効化したいvethインターフェースがあるNetworkName名
# $2：有効化したいvethインターフェース名
define up-veth
	sudo ip netns exec $1 ip link set $2 up
endef
up-veth:
	$(call up-veth, ${NS_1}, ${NS_1_VETH})
	$(call up-veth, ${NS_2}, ${NS_2_VETH})
	$(call up-veth, ${ROUTER_1}, ${ROUTER_1_VETH_0})
	$(call up-veth, ${ROUTER_1}, ${ROUTER_1_VETH_1})
	$(call up-veth, ${ROUTER_2}, ${ROUTER_2_VETH_0})
	$(call up-veth, ${ROUTER_2}, ${ROUTER_2_VETH_1})

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
	$(call set-ipaddr, ${ROUTER_1}, ${ROUTER_1_VETH_0}, ${ROUTER_1_VETH_0_IP})
	$(call set-ipaddr, ${ROUTER_1}, ${ROUTER_1_VETH_1}, ${ROUTER_1_VETH_1_IP})
	$(call set-ipaddr, ${ROUTER_2}, ${ROUTER_2_VETH_0}, ${ROUTER_2_VETH_0_IP})
	$(call set-ipaddr, ${ROUTER_2}, ${ROUTER_2_VETH_1}, ${ROUTER_2_VETH_1_IP})

enable-ipforward:
	sudo ip netns exec ${ROUTER_1} sysctl net.ipv4.ip_forward=1
	sudo ip netns exec ${ROUTER_2} sysctl net.ipv4.ip_forward=1

# 追加済みなら追加しない
# $1：対象となるNetworkNamespace
# $2：送信元CIDR(or default)
# $3：宛先IPアドレス
define add-route
	( sudo sudo ip netns exec $1 ip route list | grep $3 ) \
		|| sudo ip netns exec $1 ip route add $2 via $3
endef
add-route:
	$(call add-route, ${NS_1}, default, ${ROUTER_1_VETH_0_IP})
	$(call add-route, ${NS_2}, default, ${ROUTER_2_VETH_1_IP})
	$(call add-route, ${ROUTER_1}, ${NS_2_NETWORK_CIDR}, ${ROUTER_2_VETH_0_IP})
	$(call add-route, ${ROUTER_2}, ${NS_1_NETWORK_CIDR}, ${ROUTER_1_VETH_1_IP})

# $1：利用するNetworkNamespace名
# $2：ping送信先IPアドレス
# $3：ping送信元IPアドレス
define ping
	sudo ip netns exec $1 ping -c 2 $2 -I $3
endef
ping:
#	$(call ping, ${NS_1}, ${ROUTER_1_VETH_0_IP}, ${NS_1_VETH_IP})
#	$(call ping, ${NS_2}, ${ROUTER_2_VETH_1_IP}, ${NS_2_VETH_IP})
	$(call ping, ${NS_1}, ${NS_2_VETH_IP}, ${NS_1_VETH_IP})

clean:
	sudo ip -all netns delete
	sudo ip link delete ${NS_1_VETH} || echo OK
	sudo ip link delete ${NS_2_VETH} || echo OK
	sudo ip link delete ${ROUTER_1_VETH_1} || echo OK
