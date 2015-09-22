#!/bin/bash

# setup on Master
yum -y install docker openshift-master openshift-node
sed -i -e "s/OPTIONS='--selinux-enabled'/OPTIONS='--insecure-registry=172.30.0.0\/16 --selinux-enabled'/" /etc/sysconfig/docker
systemctl restart docker


# setup on Node (ose3-node1.example.com)
ssh root@ose3-node1.example.com yum -y install docker openshift-node
ssh root@ose3-node1.example.com sed -i -e "s/OPTIONS='--selinux-enabled'/OPTIONS='--insecure-registry=172.30.0.0\/16 --selinux-enabled'/" /etc/sysconfig/docker
ssh root@ose3-node1.example.com systemctl restart docker
