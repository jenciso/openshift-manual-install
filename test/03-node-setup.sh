#!/bin/bash

# Prerequires
yum -y install docker
sed -i -e "s/OPTIONS='--selinux-enabled'/OPTIONS='--insecure-registry=172.30.0.0\/16 --selinux-enabled'/" /etc/sysconfig/docker
systemctl restart docker

# iptables setup for node

systemctl mask firewalld

sed -i -e '/^\:OUTPUT ACCEPT/a\:OS_FIREWALL_ALLOW \- \[0\:0\]'   /etc/sysconfig/iptables
sed -i -e '/^\-A INPUT -j REJECT --reject-with icmp-host-prohibited$/i -A INPUT -j OS_FIREWALL_ALLOW'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 10250 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 10255 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p udp -m state --state NEW -m udp --dport 10255 -j ACCEPT\'   /etc/sysconfig/iptables

systemctl restart iptables

# Modify in /etc/sysconfig/openshift-master

sed -i -e "s/CONFIG_FILE=\/etc\/openshift\/node\/node.yaml/CONFIG_FILE=\/etc\/openshift\/node\/node-config.yaml/" /etc/sysconfig/openshift-node
sed -i -e "s/OPTIONS=\"--loglevel=0\"/OPTIONS=\"--loglevel=2\"/" /etc/sysconfig/openshift-node


# Start openshift-node

systemctl start openshift-node
systemctl enable openshift-node
