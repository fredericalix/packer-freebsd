#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin
export PATH

#ZFS RESIZE
echo resize
sudo gpart recover da0
sudo gpart resize -i 2 /dev/da0
sudo zpool set autoexpand=on zroot
sudo zpool online -e zroot gpt/zfs0
echo resize OK

#BUILD KERNEL
echo build
cd /usr/src
sudo git clone https://github.com/freebsd/freebsd.git ./
cd /usr/src/sys/amd64/conf
sudo sh -c "echo 'device          pf' >> GENERIC"
sudo sh -c "echo 'device          pflog' >> GENERIC"
sudo sh -c "echo 'device          pfsync' >> GENERIC"
cd /usr/src
sudo sh -c "echo 'MALLOC_PRODUCTION=YES' > /etc/src.conf"
sudo sh -c "echo 'WITHOUT_SENDMAIL=YES' >> /etc/src.conf"
mkdir /var/tmp/log
sudo make -DMALLOC_PRODUCTION -j2 buildworld 1>/var/tmp/log/buildworld-CURR-$(date +%F).log
sudo make -DMALLOC_PRODUCTION -j2 buildkernel KERNCONF=GENERIC-NODEBUG 1>/var/tmp/log/buildkernel-CURR-$(date +%F).log
sudo make -j2 installkernel KERNCONF=GENERIC-NODEBUG 1>/var/tmp/log/install-kernel-CURR-$(date +%F).log
sudo make -j2 installworld KERNCONF=GENERIC-NODEBUG 1>/var/tmp/log/install-world-CURR-$(date +%F).log

#PURGE
cd /
sudo zfs destroy -f zroot/usr/src

#UPDATE PKG
sudo pkg update
sudo pkg upgrade -y
