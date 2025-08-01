#!/bin/bash

# IPv4/IPv6 forwarding有効化
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# SRv6関連のカーネルパラメータ設定（存在する場合のみ）
sysctl -w net.ipv6.seg6_flowlabel=1 2>/dev/null || echo "seg6_flowlabel not available"
sysctl -w net.ipv6.conf.all.seg6_enabled=1 2>/dev/null || echo "seg6_enabled not available"

# VRF strict mode設定（存在する場合のみ）
sysctl -w net.vrf.strict_mode=1 2>/dev/null || echo "vrf.strict_mode not available"

# FRRサービスの開始
/usr/lib/frr/frrinit.sh start

# コンテナを維持するための無限ループ
tail -f /dev/null