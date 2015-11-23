#!/bin/bash

if [ "$1" == "" ];then
	echo "請輸入VPN介面卡名稱"
	exit 1
else
	if ! ip addr show dev "$1" > /dev/null; then
		echo  "VPN介面卡不存在"
		exit 1
	fi
fi

if [ "$2" == "" ];then
	echo 請輸入VPN的IP位置
	exit 2
else
	if echo "$2" | grep "[[:alpha:]]\.[[:alpha:]]"; then
		IP=`nslookup $2 | grep Address | sed -n '2,2p' | sed s/Address:\ //g`
	else
		if [[ "$2" =~ [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\. ]]
		then
			IP=$2
		else
			echo IP輸入不正確
			exit 3
		fi
		
	fi
fi

echo 清除現有的dhcpcd
dhcpcd -k

## 抓出優先權最高的預設路由
deGW=`ip route show  | grep default  | sed -n "1,1p" | cut -d ' ' -f 3`
deGWIF=`ip route show  | grep default  | sed -n "1,1p" | cut -d ' ' -f 5`

dhcpcd -m 30 vpn_vpn
ip route add $IP via $deGW dev $deGWIF  metric 29

echo '#!/bin/bash' > /tmp/vpnstop
echo "dhcpcd -k $1 " >> /tmp/vpnstop
echo "ip route del $IP via $deGW dev $deGWIF  metric 29" >> /tmp/vpnstop
chmod 755 /tmp/vpnstop

echo "vpn斷線後，請執行 /tmp/vpnstop 清除用不到的路由設定，雖然不清理也不會怎樣:D"
