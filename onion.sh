#!/bin/bash
#
# (このスクリプトの流れ)
#
# 1. 必要な設定情報を取得する
# 2. sysctlをforward=1にする
# 3. dhcpcdで、eth0とwlan0をのipを設定する
# 4. hostapdのインストールして、設定する
# 5. dnsmakqをインストールして、設定する
# 6. torをインストールして、設定する
# 7. iptablesインストールして、を設定する
# 8. rebootする


function print_setting () {
  echo "====================================="
  echo "LAN_IPADDR                  = $LAN_IPADDR"
  echo "LAN_GW_IPADDR               = $LAN_GW_IPADDR"
  echo "WLAN_IPADDR                 = $WLAN_IPADDR"
  echo "WLAN_DHCP_POOL_START_IPADDR = $WLAN_DHCP_POOL_START_IPADDR"
  echo "WLAN_DHCP_POOL_END_IPADDR   = $WLAN_DHCP_POOL_END_IPADDR"
  echo "SSID                        = $SSID"
  echo "SSID_PASSWORD               = $SSID_PASSWORD"
  echo "====================================="
}

function valid_ipaddr () {
  if [[ ${IPADDR} =~ ^[1-9][0-9]{0,2}\.[0-9]{1,3}\.[0-9]{1,3}\.[1-9][0-9]{0,2}$ ]]; then
    :
  else
    echo "[Abort] bad ip address."
    exit 1
  fi
}

function set_lan_ipaddr () {
  read -p "your eht0(lan) ip address (/24 only): " IPADDR
  valid_ipaddr
  LAN_IPADDR=$IPADDR
  print_setting
}

function set_lan_gw_ipaddr () {
  read -p "your eth0(lan) gw ip address: " IPADDR
  valid_ipaddr
  LAN_GW_IPADDR=$IPADDR
  print_setting
}

function set_wlan_ipaddr () {
  read -p "your airstation wlan0(oinon airstation) ip address (/24 only): " IPADDR
  valid_ipaddr
  WLAN_IPADDR=$IPADDR
  print_setting
}

function set_wlan_dhcp_pool_start_ipaddr () {
  read -p "your airstation wlan0(onion airstation) dhcp ip pool start address (/24 only): " IPADDR
  valid_ipaddr
  WLAN_DHCP_POOL_START_IPADDR=$IPADDR
  print_setting
}

function set_wlan_dhcp_pool_end_ipaddr () {
  read -p "your airstation wlan0(oinon airstation) dhcp ip pool end address (/24 only): " IPADDR
  valid_ipaddr
  WLAN_DHCP_POOL_END_IPADDR=$IPADDR
  print_setting
}

function set_ssid () {
  read -p "ssid: " SSID
  print_setting
}

function set_ssid_password () {
  read -p "ssid password: " SSID_PASSWORD
  print_setting
}

function set_config () {
  set_lan_ipaddr
  set_lan_gw_ipaddr
  set_wlan_ipaddr
  set_wlan_dhcp_pool_start_ipaddr
  set_wlan_dhcp_pool_end_ipaddr
  set_ssid
  set_ssid_password
}

function update_sysctl_conf () {
  cp ./etc/sysctl.conf /etc/sysctl.conf
}

function update_dhcpcd_conf () {
  echo "interface eth0"                    >> /etc/dhcpcd.conf
  echo "static ip_address=$LAN_IPADDR/24"  >> /etc/dhcpcd.conf
  echo "static routers=$LAN_GW_IPADDR"     >> /etc/dhcpcd.conf
  echo ""                                  >> /etc/dhcpcd.conf
  echo "interface wlan0"                   >> /etc/dhcpcd.conf
  echo "static ip_address=$WLAN_IPADDR/24" >> /etc/dhcpcd.conf
  echo "nohook wpa_supplicant"             >> /etc/dhcpcd.conf
}

function start_hostapd () {
  apt install hostapd -y

  cp ./etc/default/hostapd /etc/default/hostapd
  cp ./etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf
  sed -i "s/<SSID>/$SSID/"                   /etc/hostapd/hostapd.conf
  sed -i "s/<SSID-PASSWORD>/$SSID_PASSWORD/" /etc/hostapd/hostapd.conf

  systemctl unmask hostapd
  systemctl enable hostapd
  systemctl start hostapd
}

function start_dnsmasq () {
  apt install dnsmasq -y	

  echo ""                                                                                     >> /etc/dnsmasq.conf
  echo "interface=wlan0"                                                                      >> /etc/dnsmasq.conf
  echo "dhcp-range=$WLAN_DHCP_POOL_START_IPADDR,$WLAN_DHCP_POOL_END_IPADDR,255.255.255.0,24h" >> /etc/dnsmasq.conf

  systemctl enable dnsmasq
  systemctl start dnamasq
}

function start_tor () {
  apt install tor -y

  echo ""                                         >> /etc/tor/torrc
  echo "Log notice file /var/log/tor/notices.log" >> /etc/tor/torrc
  echo "VirtualAddrNetwork 10.192.0.0/10"         >> /etc/tor/torrc
  echo "AutomapHostsSuffixes .onion,.exit"        >> /etc/tor/torrc
  echo "AutomapHostsOnResolve 1"                  >> /etc/tor/torrc
  echo "TransPort $WLAN_IPADDR:9040"              >> /etc/tor/torrc
  echo "DNSPort $WLAN_IPADDR:53"                  >> /etc/tor/torrc

  systemctl enable tor
  systemctl start tor
}

function start_iptables () {
  apt install iptables-persistent -y 
  apt install netfilter-persistent -y
  mkdir /etc/iptables
  cp ./etc/iptables/rules.v4 /etc/iptables/rules.v4
  netfilter-persistent reload
}

############################
# Main Step
############################

set_config
update_sysctl_conf
update_dhcpcd_conf
start_hostapd
start_dnsmasq
start_tor
start_iptables

update_sysctl_conf

reboot

exit 0
