#!/bin/bash

# Create a client configuration for connecting to OpenShift
# for master

oadm create-api-client-config \
      --certificate-authority=/etc/openshift/master/ca.crt \
      --client-dir=/etc/openshift/generated-configs/node-ose3-master.example.com \
      --groups=system:nodes \
      --master=https://ose3-master.example.com:8443 \
      --signer-cert=/etc/openshift/master/ca.crt \
      --signer-key=/etc/openshift/master/ca.key \
      --signer-serial=/etc/openshift/master/ca.serial.txt \
      --user=system:node:ose3-master.example.com

cd /etc/openshift/generated-configs/node-ose3-master.example.com

oadm ca create-server-cert \
    --cert=server.crt \
    --key=server.key \
    --overwrite=true \
    --hostnames=ose3-master.example.com \
    --signer-cert=/etc/openshift/master/ca.crt \
    --signer-key=/etc/openshift/master/ca.key \
    --signer-serial=/etc/openshift/master/ca.serial.txt

rsync /etc/openshift/generated-configs/node-ose3-master.example.com/* /etc/openshift/master/


# for node

oadm create-api-client-config \
      --certificate-authority=/etc/openshift/master/ca.crt \
      --client-dir=/etc/openshift/generated-configs/node-ose3-node1.example.com \
      --groups=system:nodes \
      --master=https://ose3-master.example.com:8443 \
      --signer-cert=/etc/openshift/master/ca.crt \
      --signer-key=/etc/openshift/master/ca.key \
      --signer-serial=/etc/openshift/master/ca.serial.txt \
      --user=system:node:ose3-node1.example.com

cd /etc/openshift/generated-configs/node-ose3-node1.example.com

oadm ca create-server-cert \
    --cert=server.crt \
    --key=server.key \
    --overwrite=true \
    --hostnames=ose3-master.example.com \
    --signer-cert=/etc/openshift/master/ca.crt \
    --signer-key=/etc/openshift/master/ca.key \
    --signer-serial=/etc/openshift/master/ca.serial.txt

rsync -av -e ssh . root@ose3-node1.example.com:/etc/openshift/node/


# iptables setup

systemctl mask firewalld

sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 10250 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 10255 -j ACCEPT\'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p udp -m state --state NEW -m udp --dport 10255 -j ACCEPT\'   /etc/sysconfig/iptables


# Create node config

oadm create-node-config \
  --node-dir=/etc/openshift/node/ \
  --node=ose3-master.example.com \
  --master=https://ose3-master.example.com:8443 \
  --hostnames=ose3-master.example.com,192.168.133.2 \
  --node-client-certificate-authority=/etc/openshift/master/ca.crt \
  --signer-cert=/etc/openshift/master/ca.crt \
  --signer-key=/etc/openshift/master/ca.key \
  --signer-serial=/etc/openshift/master/ca.serial.txt \
  --certificate-authority=/etc/openshift/master/ca.crt \
  --volume-dir=/var/lib/openshift/openshift.local.volumes

oadm create-node-config \
  --node-dir=/tmp/node-config \
  --node=ose3-node1.example.com \
  --hostnames=ose3-node1.example.com,192.168.133.3 \
  --master=https://ose3-master.example.com:8443 \
  --node-client-certificate-authority=/etc/openshift/master/ca.crt \
  --signer-cert=/etc/openshift/master/ca.crt \
  --signer-key=/etc/openshift/master/ca.key \
  --signer-serial=/etc/openshift/master/ca.serial.txt \
  --certificate-authority=/etc/openshift/master/ca.crt \
  --volume-dir=/var/lib/openshift/openshift.local.volumes

rsync -av -e ssh /tmp/node-config/*  root@ose3-node1.example.com:/etc/openshift/node/


# Modify in /etc/sysconfig/openshift-master

sed -i -e "s/CONFIG_FILE=\/etc\/openshift\/node\/node.yaml/CONFIG_FILE=\/etc\/openshift\/node\/node-config.yaml/" /etc/sysconfig/openshift-node
sed -i -e "s/OPTIONS=\"--loglevel=0\"/OPTIONS=\"--loglevel=2\"/" /etc/sysconfig/openshift-node

# Start openshift-node

systemctl start openshift-node
systemctl enable openshift-node
