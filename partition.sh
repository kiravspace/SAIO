#!/bin/bash

echo "------------Install dependencies------------"

apt-get update
apt-get install curl gcc memcached rsync sqlite3 xfsprogs git-core libffi-dev python-setuptools -y
apt-get install python-coverage python-dev python-nose python-simplejson python-xattr python-eventlet python-greenlet python-pastedeploy python-netifaces python-pip python-dnspython python-mock -y

echo "------------Prepare Partition------------"

# Set up a single partition
cat << EOF | fdisk /dev/sdb
n
p
1

+100G
w
EOF

mkfs.xfs /dev/sdb1 -f

# Edit /etc/fstab and add
echo "/dev/sdb1 /mnt/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab

# Create the mount point and the individualized links
mkdir /mnt/sdb1
mount /mnt/sdb1
mkdir /mnt/sdb1/1 /mnt/sdb1/2 /mnt/sdb1/3 /mnt/sdb1/4
chown root /mnt/sdb1/*
mkdir /srv
for x in {1..4}; do ln -s /mnt/sdb1/$x /srv/$x; done
mkdir -p /srv/1/node/sdb1 /srv/1/node/sdb5 /srv/2/node/sdb2 /srv/2/node/sdb6 /srv/3/node/sdb3 /srv/3/node/sdb7 /srv/4/node/sdb4 /srv/4/node/sdb8 /var/run/swift
chown -R root /var/run/swift
# **Make sure to include the trailing slash after /srv/$x/**
for x in {1..4}; do chown -R root /srv/$x/; done

# Add the following lines to /etc/rc.local (before the exit 0)
sed '/exit 0/i\mkdir -p /var/cache/swift /var/cache/swift2 /var/cache/swift3 /var/cache/swift4' -i /etc/rc.local
sed '/exit 0/i\chown root /var/cache/swift*' -i /etc/rc.local
sed '/exit 0/i\mkdir -p /var/run/swift' -i /etc/rc.local
sed '/exit 0/i\chown root /var/run/swift\n' -i /etc/rc.local
