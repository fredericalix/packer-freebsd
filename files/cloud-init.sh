#!/usr/local/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin
export PATH

#ZFS RESIZE
gpart recover da0
gpart resize -i 2 /dev/da0
zpool set autoexpand=on zroot
zpool online -e zroot da0p2

#set_key
fetch http://169.254.169.254/openstack/latest/meta_data.json -q -o - | jq -r '.keys[] |.data' > /home/freebsd/.ssh/authorized_keys

#set_hostname
FQDN=`fetch http://169.254.169.254/openstack/latest/meta_data.json -q -o - | jq '.hostname' | sed 's/.novalocal//g'`
export FQDN
sed -i "" "s/hostname.*/hostname=$FQDN/g" /etc/rc.conf
hostname `echo $FQDN | tr -d '"'`

#set root passwd
pw mod user root -w no > /dev/null

#run userdata
fetch http://169.254.169.254/latest/user-data -q -o - | sh

#ssh host key
rm /etc/ssh/ssh_host*
ssh-keygen -A

# Generate new hostid
od -x /dev/random | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}' > /etc/hostid

#the end
mv /etc/rc.local /etc/rc.local.AFTERBOOT