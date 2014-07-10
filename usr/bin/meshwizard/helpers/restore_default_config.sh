#!/bin/sh
# This will restore default "factory" settings before running the meshwizard
# and is used when cleanup=1
# Warning: This will reset network settings for wan and lan to defaults too.

echo "+ Restore default config as requested with cleanup=1"
cp -f /rom/etc/config/* $meshr/etc/config/
rm $meshr/etc/config/wireless
wifi detect > $meshr/etc/config/wireless
rm $meshr/etc/config/network
/etc/init.d/defconfig start
