#!/system/bin/sh
# For android 16 decrypt（X100 同款：挂 persist，通知 crypto ready）
mkdir -p /mnt/vendor/persist
mount -t ext4 /dev/block/by-name/persist /mnt/vendor/persist
sleep 0.5
setprop crypto.ready 1
echo done
