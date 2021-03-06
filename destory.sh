#!/bin/bash

rm -rf /etc/hostapd
rm -rf /etc/tor
rm -rf /etc/iptables

apt remove --purge tor -y
apt remove --purge dnsmasq -y
apt remove --purge hostapd -y
apt remove --purge netfileter-persistent -y
apt remove --purge iptables-persistent -y

apt autoremove -y
