#!/bin/bash

# install packages

yum -y install openshift-node

# iptables setup for node

systemctl mask firewalld

sed -i -e '/^\:OUTPUT ACCEPT/a\:OS_FIREWALL_ALLOW \- \[0\:0\]'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 10250 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 10255 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p udp -m state --state NEW -m udp --dport 10255 -j ACCEPT\'   /etc/sysconfig/iptables

systemctl restart iptables


# Create node config

oadm create-node-config \
  --node-dir=/etc/openshift/node/ \
  --node=ose3-master.example.com \
  --hostnames=ose3-master.example.com,192.168.133.2 \
  --node-client-certificate-authority=/etc/openshift/master/ca.crt \
  --signer-cert=/etc/openshift/master/ca.crt \
  --signer-key=/etc/openshift/master/ca.key \
  --signer-serial=/etc/openshift/master/ca.serial.txt \
  --certificate-authority=/etc/openshift/master/ca.crt

oadm create-node-config \
  --node-dir=/etc/openshift/node/ \
  --node=ose3-node1.example.com \
  --hostnames=ose3-node1.example.com,192.168.133.3 \
  --node-client-certificate-authority=/etc/openshift/node/ca.crt \
  --signer-cert=/etc/openshift/node/ca.crt \
  --signer-key=/etc/openshift/node/ca.key \
  --signer-serial=/etc/openshift/node/ca.serial.txt
  --certificate-authority=/etc/openshift/node/ca.crt


# Modify in /etc/sysconfig/openshift-master

sed -i -e "s/CONFIG_FILE=\/etc\/openshift\/node\/node.yaml/CONFIG_FILE=\/etc\/openshift\/node\/node-config.yaml/" /etc/sysconfig/openshift-node
sed -i -e "s/OPTIONS=\"--loglevel=0\"/OPTIONS=\"--loglevel=2\"/" /etc/sysconfig/openshift-node


# Start openshift-node

systemctl start openshift-node
systemctl enable openshift-node
