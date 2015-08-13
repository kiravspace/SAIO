#!/bin/bash

echo "------------Install Swift------------"
sleep 3

# Check out the python-swiftclient repo
cd ~
git clone https://github.com/openstack/python-swiftclient.git

# Build a development installation of python-swiftclient
cd ~/python-swiftclient
python setup.py develop

# Check out the swift repo
cd ~
git clone https://github.com/openstack/swift.git

# Build a development installation of swift
cd ~/swift
pip install -r requirements.txt
python setup.py develop

# Install swift’s test dependencies
pip install -r test-requirements.txt

echo "------------Setting up rsync------------"
sleep 3

# Create /etc/rsyncd.conf
cp ~/swift/doc/saio/rsyncd.conf /etc/
sed -i "s/<your-user-name>/root/" /etc/rsyncd.conf
# On Ubuntu, edit the following line in /etc/default/rsync
sed -i "s/RSYNC_ENABLE=false/RSYNC_ENABLE=true/" /etc/default/rsync

# Start the rsync daemon
service rsync restart

# Verify rsync is accepting connections for all servers
rsync rsync://pub@localhost/

# You should see the following output from the above command
# account6012
# account6022
# account6032
# account6042
# container6011
# container6021
# container6031
# container6041
# object6010
# object6020
# object6030
# object6040

echo "------------Starting memcached------------"
sleep 3

# Install the swift rsyslogd configuration
cp ~/swift/doc/saio/rsyslog.d/10-swift.conf /etc/rsyslog.d/

# Edit /etc/rsyslog.conf and make the following change (usually in the “GLOBAL DIRECTIVES” section)
sed -i "s/\$PrivDropToGroup syslog/\$PrivDropToGroup adm/" /etc/rsyslog.conf

# Store log
mkdir -p /var/log/swift

# Setup the logging directory and start syslog
chown -R syslog.adm /var/log/swift
chmod -R g+w /var/log/swift
service rsyslog restart

echo "------------Configuring each node------------"
sleep 3

# Optionally remove an existing swift directory
rm -rf /etc/swift

# Populate the /etc/swift directory itself
cp -r ~/swift/doc/saio/swift /etc/swift

# Update <your-user-name> references in the Swift config files
find /etc/swift/ -name \*.conf | xargs sudo sed -i "s/<your-user-name>/root/"

echo "------------Setting up scripts for running Swift------------"
sleep 3

# Copy the SAIO scripts for resetting the environment
mkdir -p ~/bin
cp ~/swift/doc/saio/bin/* ~/bin
chmod +x ~/bin/*

# Edit the $HOME/bin/resetswift script
sed -i "s/\${USER}:\${USER}/root/" ~/bin/resetswift

# Install the sample configuration file for running tests
cp ~/swift/test/sample.conf /etc/swift/test.conf

# Add an environment variable for running tests below
echo "export SWIFT_TEST_CONFIG_FILE=/etc/swift/test.conf" >> ~/.bashrc

# Be sure that your PATH includes the bin directory
echo "export PATH=${PATH}:/root/bin" >> ~/.bashrc

# Source the above environment variables into your current environment
source ~/.bashrc

# Construct the initial rings using the provided script
~/bin/remakerings

# You can expect the output from this command to produce the following.
# Note that 3 object rings are created in order to test storage policies and EC in the SAIO environment.
# The EC ring is the only one with all 8 devices.
# There are also two replication rings, one for 3x replication and another for 2x replication,
# but those rings only use 4 devices:
#
# Device d0r1z1-127.0.0.1:6010R127.0.0.1:6010/sdb1_"" with 1.0 weight got id 0
# Device d1r1z2-127.0.0.1:6020R127.0.0.1:6020/sdb2_"" with 1.0 weight got id 1
# Device d2r1z3-127.0.0.1:6030R127.0.0.1:6030/sdb3_"" with 1.0 weight got id 2
# Device d3r1z4-127.0.0.1:6040R127.0.0.1:6040/sdb4_"" with 1.0 weight got id 3
# Reassigned 1024 (100.00%) partitions. Balance is now 0.00.  Dispersion is now 0.00
# Device d0r1z1-127.0.0.1:6010R127.0.0.1:6010/sdb1_"" with 1.0 weight got id 0
# Device d1r1z2-127.0.0.1:6020R127.0.0.1:6020/sdb2_"" with 1.0 weight got id 1
# Device d2r1z3-127.0.0.1:6030R127.0.0.1:6030/sdb3_"" with 1.0 weight got id 2
# Device d3r1z4-127.0.0.1:6040R127.0.0.1:6040/sdb4_"" with 1.0 weight got id 3
# Reassigned 1024 (100.00%) partitions. Balance is now 0.00.  Dispersion is now 0.00
# Device d0r1z1-127.0.0.1:6010R127.0.0.1:6010/sdb1_"" with 1.0 weight got id 0
# Device d1r1z1-127.0.0.1:6010R127.0.0.1:6010/sdb5_"" with 1.0 weight got id 1
# Device d2r1z2-127.0.0.1:6020R127.0.0.1:6020/sdb2_"" with 1.0 weight got id 2
# Device d3r1z2-127.0.0.1:6020R127.0.0.1:6020/sdb6_"" with 1.0 weight got id 3
# Device d4r1z3-127.0.0.1:6030R127.0.0.1:6030/sdb3_"" with 1.0 weight got id 4
# Device d5r1z3-127.0.0.1:6030R127.0.0.1:6030/sdb7_"" with 1.0 weight got id 5
# Device d6r1z4-127.0.0.1:6040R127.0.0.1:6040/sdb4_"" with 1.0 weight got id 6
# Device d7r1z4-127.0.0.1:6040R127.0.0.1:6040/sdb8_"" with 1.0 weight got id 7
# Reassigned 1024 (100.00%) partitions. Balance is now 0.00.  Dispersion is now 0.00
# Device d0r1z1-127.0.0.1:6011R127.0.0.1:6011/sdb1_"" with 1.0 weight got id 0
# Device d1r1z2-127.0.0.1:6021R127.0.0.1:6021/sdb2_"" with 1.0 weight got id 1
# Device d2r1z3-127.0.0.1:6031R127.0.0.1:6031/sdb3_"" with 1.0 weight got id 2
# Device d3r1z4-127.0.0.1:6041R127.0.0.1:6041/sdb4_"" with 1.0 weight got id 3
# Reassigned 1024 (100.00%) partitions. Balance is now 0.00.  Dispersion is now 0.00
# Device d0r1z1-127.0.0.1:6012R127.0.0.1:6012/sdb1_"" with 1.0 weight got id 0
# Device d1r1z2-127.0.0.1:6022R127.0.0.1:6022/sdb2_"" with 1.0 weight got id 1
# Device d2r1z3-127.0.0.1:6032R127.0.0.1:6032/sdb3_"" with 1.0 weight got id 2
# Device d3r1z4-127.0.0.1:6042R127.0.0.1:6042/sdb4_"" with 1.0 weight got id 3
# Reassigned 1024 (100.00%) partitions. Balance is now 0.00.  Dispersion is now 0.00#

sleep 3

# Verify the unit tests run
~/swift/.unittests

sleep 3

~/bin/startmain

sleep 3

# Get an X-Storage-Url and X-Auth-Token
curl -v -H 'X-Storage-User: test:tester' -H 'X-Storage-Pass: testing' http://127.0.0.1:8080/auth/v1.0

# Check that swift command provided by the python-swiftclient package works
swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K testing stat

# Verify the functional tests run
~/swift/.functests

# Verify the probe tests run
~/swift/.probetests
