These are the scripts for manual-installation

**Need correct order**

- Run on master and Node

~~~
git clone https://github.com/nak3/openshift-manual-install.git
cd openshift-manual-install/test
~~~

- Run on master

  1. `# bash 00-install-pacakges.sh`
  2. `# bash 01-master-setup.sh`
  3. `# bash 02-master-as-node-setup.sh`

- Run on node

  4. `# bash 03-node-setup.sh`

- Run on master

  5. `# bash 04-master-final-setup.sh`
