#!/bin/bash

# Prerequires
yum -y install docker
sed -i -e "s/OPTIONS='--selinux-enabled'/OPTIONS='--insecure-registry=172.30.0.0\/16 --selinux-enabled'/" /etc/sysconfig/docker
systemctl restart docker


# Master setup
yum -y install openshift-master


# FIrewall setup

sed -i -e '/^\:OUTPUT ACCEPT/a\:OS_FIREWALL_ALLOW \- \[0\:0\]'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 4001 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 8443 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 53 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 24224 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p udp -m state --state NEW -m udp --dport 24224 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p udp -m state --state NEW -m udp --dport 5404 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p udp -m state --state NEW -m udp --dport 5405 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 8444 -j ACCEPT'   /etc/sysconfig/iptables
sed -i -e '/^COMMIT$/i -A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 7001 -j ACCEPT'   /etc/sysconfig/iptables

systemctl restart iptables


# Create a key and server certificate

oadm ca create-master-certs \
      --hostnames=ose3-master.example.com,$MASTER_IP,localhost,127.0.0.1 \
      --master=https://ose3-master.example.com:8443 \
      --public-master=https://ose3-master.example.com:8443 \
      --cert-dir=/etc/openshift/master \
      --overwrite=false


# Create OpenShift Master configuration files to start

oadm create-bootstrap-policy-file --filename=/etc/openshift/master/policy.json
cat <<EOF > /etc/openshift/master/scheduler.json
{
  "predicates": [
    {"name": "MatchNodeSelector"},
    {"name": "PodFitsResources"},
    {"name": "PodFitsPorts"},
    {"name": "NoDiskConflict"},
    {"name": "Region", "argument": {"serviceAffinity" : {"labels" : ["region"]}}}
  ],"priorities": [
    {"name": "LeastRequestedPriority", "weight": 1},
    {"name": "ServiceSpreadingPriority", "weight": 1},
    {"name": "Zone", "weight" : 2, "argument": {"serviceAntiAffinity" : {"label": "zone"}}}
  ]
}
EOF


# master-config.yaml

OPENSHIFT_MASTER_PUBLIC_API_URL="https://ose3-master.example.com:8443"
OPENSHIFT_MASTER_PUBLIC_CONSOLE_URL="https://ose3-master.example.com:8443/console/"
OPENSHIFT_MASTER_BIND_ADDR="0.0.0.0"
OPENSHIFT_MASTER_CONSOLE_PORT="8443"
OPENSHIFT_COMMON_HOSTNAME="ose3-master.example.com"
OPENSHIFT_COMMON_IP="192.168.133.2"
OPENSHIFT_COMMON_PUBLIC_HOSTNAME="ose3-master.example.com"
OPENSHIFT_COMMON_PUBLIC_IP="192.168.133.2"
OPENSHIFT_MASTER_DNS_PORT="53"
OPENSHIFT_MASTER_ETCD_URLS="https://ose3-master.example.com:4001"
OPENSHIFT_MASTER_ETCD_PORT="4001"
OPENSHIFT_MASTER_SDN_CLUSTER_NETWORK_CIDR="10.1.0.0/16"
OPENSHIFT_MASTER_SDN_HOST_SUBNET_LENGTH="8"
OPENSHIFT_MASTER_PORTAL_NET="172.30.0.0/16"
OPENSHIFT_MASTER_URL="https://ose3-master.example.com:8443"
OPENSHIFT_MASTER_DEFAULT_NODE_SELECTOR='""'
OPENSHIFT_MASTER_DEFAULT_SUBDOMAIN='""'
OPENSHIFT_MASTER_API_PORT="8443"
OPENSHIFT_MASTER_REGISTRY_URL='openshift3/ose-${component}:${version}'

cat <<EOF > /etc/openshift/master/master-config.yaml
apiLevels:
- v1beta3
- v1
apiVersion: v1
assetConfig:
  logoutURL: ""
  masterPublicURL: $OPENSHIFT_MASTER_PUBLIC_API_URL
  publicURL: $OPENSHIFT_MASTER_PUBLIC_CONSOLE_URL
  servingInfo:
    bindAddress: $OPENSHIFT_MASTER_BIND_ADDR:$OPENSHIFT_MASTER_CONSOLE_PORT
    certFile: master.server.crt
    clientCA: ""
    keyFile: master.server.key
    maxRequestsInFlight: 0
    requestTimeoutSeconds: 0
corsAllowedOrigins:
  - 127.0.0.1
  - localhost
  - $OPENSHIFT_COMMON_HOSTNAME
  - $OPENSHIFT_COMMON_IP
  - $OPENSHIFT_COMMON_PUBLIC_HOSTNAME
  - $OPENSHIFT_COMMON_PUBLIC_IP
dnsConfig:
  bindAddress: $OPENSHIFT_MASTER_BIND_ADDR:$OPENSHIFT_MASTER_DNS_PORT
etcdClientInfo:
  ca: ca.crt
  certFile: master.etcd-client.crt
  keyFile: master.etcd-client.key
  urls:
    - $OPENSHIFT_MASTER_ETCD_URLS
etcdConfig:
  address: $OPENSHIFT_COMMON_HOSTNAME:$OPENSHIFT_MASTER_ETCD_PORT
  peerAddress: $OPENSHIFT_COMMON_HOSTNAME:7001
  peerServingInfo:
    bindAddress: $OPENSHIFT_MASTER_BIND_ADDR:7001
    certFile: etcd.server.crt
    clientCA: ca.crt
    keyFile: etcd.server.key
  servingInfo:
    bindAddress: $OPENSHIFT_MASTER_BIND_ADDR:$OPENSHIFT_MASTER_ETCD_PORT
    certFile: etcd.server.crt
    clientCA: ca.crt
    keyFile: etcd.server.key
  storageDirectory: /var/lib/openshift/openshift.local.etcd
etcdStorageConfig:
  kubernetesStoragePrefix: kubernetes.io
  kubernetesStorageVersion: v1
  openShiftStoragePrefix: openshift.io
  openShiftStorageVersion: v1
imageConfig:
  format: $OPENSHIFT_MASTER_REGISTRY_URL
  latest: false
kind: MasterConfig
kubeletClientInfo:
  ca: ca.crt
  certFile: master.kubelet-client.crt
  keyFile: master.kubelet-client.key
  port: 10250
kubernetesMasterConfig:
  apiLevels:
  - v1beta3
  - v1
  apiServerArguments: null
  controllerArguments: null
  masterCount: 1
  masterIP: ""
  podEvictionTimeout: ""
  schedulerConfigFile: /etc/openshift/master/scheduler.json
  servicesNodePortRange: ""
  servicesSubnet: $OPENSHIFT_MASTER_PORTAL_NET
  staticNodeNames: []
masterClients:
  externalKubernetesKubeConfig: ""
  openshiftLoopbackKubeConfig: openshift-master.kubeconfig
masterPublicURL: $OPENSHIFT_MASTER_PUBLIC_API_URL
networkConfig:
  clusterNetworkCIDR: $OPENSHIFT_MASTER_SDN_CLUSTER_NETWORK_CIDR
  hostSubnetLength: $OPENSHIFT_MASTER_SDN_HOST_SUBNET_LENGTH
  networkPluginName: redhat/openshift-ovs-subnet
# serviceNetworkCIDR must match kubernetesMasterConfig.servicesSubnet
  serviceNetworkCIDR: $OPENSHIFT_MASTER_PORTAL_NET
oauthConfig:
  assetPublicURL: $OPENSHIFT_MASTER_PUBLIC_CONSOLE_URL
  grantConfig:
    method: auto
  identityProviders:
  - name: deny_all
    challenge: True
    login: True
    provider:
      apiVersion: v1
      kind: DenyAllPasswordIdentityProvider
  masterPublicURL: $OPENSHIFT_MASTER_PUBLIC_API_URL
  masterURL: $OPENSHIFT_MASTER_URL
  sessionConfig:
    sessionMaxAgeSeconds: 3600
    sessionName: ssn
    sessionSecretsFile:
  tokenConfig:
    accessTokenMaxAgeSeconds: 86400
    authorizeTokenMaxAgeSeconds: 500
policyConfig:
  bootstrapPolicyFile: /etc/openshift/master/policy.json
  openshiftInfrastructureNamespace: openshift-infra
  openshiftSharedResourcesNamespace: openshift
projectConfig:
  defaultNodeSelector: ""
  projectRequestMessage: ""
  projectRequestTemplate: ""
  securityAllocator:
    mcsAllocatorRange: s0:/2
    mcsLabelsPerProject: 5
    uidAllocatorRange: 1000000000-1999999999/10000
routingConfig:
  subdomain:  $OPENSHIFT_MASTER_DEFAULT_SUBDOMAIN
serviceAccountConfig:
  managedNames:
  - default
  - builder
  - deployer
  masterCA: ca.crt
  privateKeyFile: serviceaccounts.private.key
  publicKeyFiles:
  - serviceaccounts.public.key
servingInfo:
  bindAddress: $OPENSHIFT_MASTER_BIND_ADDR:$OPENSHIFT_MASTER_API_PORT
  certFile: master.server.crt
  clientCA: ca.crt
  keyFile: master.server.key
  maxRequestsInFlight: 500
  requestTimeoutSeconds: 3600
EOF


# Modify in /etc/sysconfig/openshift-master

sed -i -e "s/OPTIONS=\"--loglevel=0\"/OPTIONS=\"--loglevel=2\"/" /etc/sysconfig/openshift-master
sed -i -e "s/CONFIG_FILE=\/etc\/openshift\/master\/master.yaml/CONFIG_FILE=\/etc\/openshift\/master\/master-config.yaml/" /etc/sysconfig/openshift-master


# openshift-master start and enable

systemctl start openshift-master
systemctl enable openshift-master


# 2. Setup OpenShift Master to use
#===============

# Copy admin.kubeconfig for root user's default config

mkdir /root/.kube
cp /etc/openshift/master/admin.kubeconfig /root/.kube/config


# Create service account for registry and router

cat <<EOF > /tmp/registry-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: registry
EOF

oc create -f /tmp/registry-serviceaccount.yaml
cat <<EOF > /tmp/router-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: router
EOF

oc create -f /tmp/router-serviceaccount.yaml
oc get scc privileged -o yaml > /tmp/scc.yaml
echo "- system:serviceaccount:default:router" >> /tmp/scc.yaml
echo "- system:serviceaccount:default:registry" >> /tmp/scc.yaml
oc replace -f /tmp/scc.yaml


# import imagestream and templates

git clone https://github.com/openshift/openshift-ansible.git
cp -r openshift-ansible/roles/openshift_examples/files/examples/ .
oc create -n openshift -f examples/image-streams/image-streams-rhel7.json
oc create -n openshift -f examples/xpaas-streams/jboss-image-streams.json
for filepath in examples/db-templates/*; do oc create -n openshift -f $filepath; done
for filepath in examples/quickstart-templates/*; do oc create -n openshift -f $filepath; done
for filepath in examples/xpaas-templates/*; do oc create -n openshift -f $filepath; done
