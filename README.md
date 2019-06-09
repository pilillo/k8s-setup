# K8s Installation on bare-metal

# 1. Vagrant Multi-machine setup

## 1.1 Create an RSA ssh key
``ssh-keygen -t rsa -b 4096 -f key -N ""``

## 1.2 Start the vagrant multi-machine
``vagrant up``

# 2. K8s Setup using Ansible
Perform a dry run before making any modification to the system:  
``ansible-playbook -i nodes/hosts master-playbook.yml --check``

# 3. K8s Setup using Shell Script
The shell script loads itself on each of the nodes, installs the k8s packages depending on the node OS, as well as uses kubeadm to init and the join the K8s cluster.
``./shell-setup/start.sh`` The installation script also exports the kube config file to the shell-setup folder. This means that upon setup completion we are able to interact with the K8s cluster simply by using `kubectl --kubeconfig shell-config/admin.conf <command>`.
