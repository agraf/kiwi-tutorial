#!/bin/bash
# Copyright (c) 2015 SUSE LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

mkdir /var/lib/misc/reconfig_system

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$name]..."

#======================================
# add missing fonts
#--------------------------------------
CONSOLE_FONT="lat9w-16.psfu"

#======================================
# prepare for setting root pw, timezone
#--------------------------------------
echo ** "reset machine settings"
rm /etc/machine-id
rm /etc/localtime
rm /var/lib/zypp/AnonymousUniqueId
rm /var/lib/systemd/random-seed

#======================================
# SuSEconfig
#--------------------------------------
echo "** Running suseConfig..."
suseConfig

echo "** Running ldconfig..."
/sbin/ldconfig

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Specify default runlevel
#--------------------------------------
baseSetRunlevel 3

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey

#======================================
# Enable DHCP on eth0
#--------------------------------------
cat >/etc/sysconfig/network/ifcfg-eth0 <<EOF
BOOTPROTO='dhcp'
MTU=''
REMOTE_IPADDR=''
STARTMODE='auto'
ETHTOOL_OPTIONS=''
USERCONTROL='no'
EOF

#======================================
# Enable sshd
#--------------------------------------
chkconfig sshd on

#======================================
# Enablei cloud-init 
#--------------------------------------
suseInsertService cloud-init-local
suseInsertService cloud-init
suseInsertService cloud-config
suseInsertService cloud-final

#======================================
# Remove doc files
#--------------------------------------
baseStripDocs

#======================================
# remove rpms defined in config.xml in the image type=delete section 
#--------------------------------------
baseStripRPM

#======================================
# Sysconfig Update
#--------------------------------------
echo '** Update sysconfig entries...'
baseUpdateSysConfig /etc/sysconfig/console CONSOLE_FONT "$CONSOLE_FONT"
baseUpdateSysConfig /etc/sysconfig/network/dhcp DHCLIENT_SET_HOSTNAME yes

#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
update-ca-certificates

if [ ! -s /var/log/zypper.log ]; then
	> /var/log/zypper.log
fi

# only for debugging
#systemctl enable debug-shell.service

#======================================
# Prevent interactive systemd-firstboot
#--------------------------------------
echo "LANG=en_US.UTF-8" > /etc/locale.conf

baseCleanMount

exit 0

