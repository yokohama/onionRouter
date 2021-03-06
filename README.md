### このスクリプトは以下のファイルを上書き（初期化）します。すでにネットワークの設定をしている場合は、実行しないでください。

```
/etc/dhcpcd.conf

/etc/default/hostapd
/etc/hostapd/hostapd.conf

/etc/dnsmasq.conf

/etc/tor/torrc
/etc/default/tor

/etc/iptables/rules.v4
```

### Instaration

```
git clone https://github.com/yokohama/onionRouter.git
cd onionRouter
./onion.sh
```
