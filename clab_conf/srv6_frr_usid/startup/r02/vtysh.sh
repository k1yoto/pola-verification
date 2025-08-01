#!/bin/bash

# FRRデーモンが起動するまで待機
sleep 5

# vtyshでintegrated-vtysh-configを有効化
vtysh -c "configure terminal" -c "service integrated-vtysh-config" -c "exit" || echo "vtysh command failed, continuing..."

# 永続的に実行（コンテナが終了しないように）
tail -f /dev/null