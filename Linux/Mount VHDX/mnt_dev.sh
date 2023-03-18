#sudo mount -L yaap ~/android_dev/yaap
#sudo mount -L yaap_out ~/android_dev/yaap_out
#sudo mount -L out2 ~/android_dev/yaap_out2
sudo zpool import -a
sudo mount -t drvfs '\\homeassistant\wd500\syncthing\Phone Share' /mnt/phone_share

sudo lsblk
sudo zpool list
sudo zfs list

echo ""
echo Setting up zram

sudo sysctl vm.swappiness=160
sudo sysctl vm.page-cluster=1

sudo swapoff /dev/sdb

#sudo zramctl -s 19327352832 /dev/zram0
#sudo zramctl -s 25769803776 /dev/zram0
sudo zramctl -s 34359738368 /dev/zram0

sudo mkswap /dev/zram0
sudo swapon /dev/zram0
