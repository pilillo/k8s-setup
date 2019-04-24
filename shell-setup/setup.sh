#!/usr/bin/env bash

get_curr_dir(){
    echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
}

upload_file(){
    # $(upload_file $REMOTE_PWD 22 "$PWD/test.txt" $REMOTE_USER $REMOTE_HOST "/home/$REMOTE_USER/")
    #echo sshpass -p $1 scp -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -P ${2} $3 ${4}@${5}:${6}
    echo "scp -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $1 -P $2 $3 ${4}@${5}:${6}"
}

run_remote_command(){
    # e.g. echo $(run_remote_command $REMOTE_PWD 22 $REMOTE_USER $REMOTE_HOST "ls")
    #echo sshpass -p $1 ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p ${2} ${3}@${4} "${5}"
    echo "ssh -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $1 -p $2 ${3}@${4} ${5}"
}

get_pacman(){
    # one of these commands should always be available to install packages
    declare -a pacmans=("yum" "apt-get" "pacman")
    for i in "${pacmans[@]}"
    do
        command -v "$i" > /dev/null 2>&1 && {
            echo "$i"
            break
        }
    done
}

get_ip_v4(){
    # return ip v4 on specific interface
    command -v "ifconfig" > /dev/null 2>&1 && {
        echo $(sudo ifconfig "${1}" | grep 'inet ' |  awk '{print $2}')
    } || {
        echo $(sudo ip address show dev "${1}" | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")
    }
}

setup_docker(){
    # https://kubernetes.io/docs/setup/cri/
    # check if the docker command is available, but also if the daemon was started
    command -v "docker" > /dev/null 2>&1 && docker ps > /dev/null 2>&1 && {
        echo "docker is already installed"
    } || {
        case $(get_pacman) in
        yum)
            echo "Installing docker using yum"
            sudo yum install -y curl wget
            #curl -sSL get.docker.com | sh
            sudo yum install -y yum-utils device-mapper-persistent-data lvm2
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum update -y && sudo yum install docker-ce -y #docker-ce-18.06.2.ce
            sudo mkdir -p /etc/docker
            docker_config="/etc/docker/daemon.json"
            echo "{" | sudo tee $docker_config
            echo '  "exec-opts": ["native.cgroupdriver=systemd"],' | sudo tee -a $docker_config
            echo '  "log-driver": "json-file",' | sudo tee -a $docker_config
            echo '  "log-opts": {' | sudo tee -a $docker_config
            echo '    "max-size": "100m"' | sudo tee -a $docker_config
            echo '  },' | sudo tee -a $docker_config
            echo '  "storage-driver": "overlay2",' | sudo tee -a $docker_config
            echo '  "storage-opts": [' | sudo tee -a $docker_config
            echo '    "overlay2.override_kernel_check=true"' | sudo tee -a $docker_config
            echo '  ]' | sudo tee -a $docker_config
            echo '}' | sudo tee -a $docker_config
            sudo mkdir -p /etc/systemd/system/docker.service.d
            sudo systemctl daemon-reload
            ;;
        apt-get)
            echo "Installing docker using apt-get"
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update -y
            sudo apt-get install -y curl wget
            # https://tecadmin.net/install-docker-on-ubuntu/
            sudo apt-get -y install apt-transport-https ca-certificates software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update -y
            sudo apt-get install -y docker-ce
            #sudo apt-get install docker-ce docker-ce-cli containerd.io
            #curl -sSL get.docker.com | sh
            # use overlay2 as underlying storage
            sudo mkdir -p /etc/docker
            docker_config="/etc/docker/daemon.json"
            echo "{" | sudo tee $docker_config
            echo '  "exec-opts": ["native.cgroupdriver=systemd"],' | sudo tee -a $docker_config
            echo '  "log-driver": "json-file",' | sudo tee -a $docker_config
            echo '  "log-opts": {' | sudo tee -a $docker_config
            echo '    "max-size": "100m"' | sudo tee -a $docker_config
            echo '  },' | sudo tee -a $docker_config
            echo '  "storage-driver": "overlay2"' | sudo tee -a $docker_config
            echo '}' | sudo tee -a $docker_config
            sudo mkdir -p /etc/systemd/system/docker.service.d
            sudo systemctl daemon-reload
            ;;
        pacman)
            echo "Installing docker using pacman"
            sudo pacman -Syy || sudo rm /var/lib/pacman/db.lck
            sudo pacman -Sy curl wget --noconfirm
            sudo pacman -Sy docker --noconfirm
            # use overlay2 as underlying storage
            sudo mkdir -p /etc/docker
            docker_config="/etc/docker/daemon.json"
            echo "{" | sudo tee $docker_config
            #echo '  "exec-opts": ["native.cgroupdriver=systemd"],' | sudo tee -a $docker_config
            #echo '  "log-driver": "json-file",' | sudo tee -a $docker_config
            #echo '  "log-opts": {' | sudo tee -a $docker_config
            #echo '    "max-size": "100m"' | sudo tee -a $docker_config
            #echo '  },' | sudo tee -a $docker_config
            echo '  "storage-driver": "overlay2"' | sudo tee -a $docker_config
            echo '}' | sudo tee -a $docker_config
            sudo mkdir -p /etc/systemd/system/docker.service.d
            sudo systemctl daemon-reload
            ;;
        esac
        # add user to docker group
        sudo usermod -aG docker $(whoami)
        # reload group privileges
        newgrp docker
        # restart docker daemon
        sudo systemctl enable docker
        sudo systemctl restart docker
    }
}


disable_swap(){
    # to determine whether we have any swap
    if [ $(cat /proc/swaps | wc -l) -gt 1 ]; then
        # disable already mounted swap
        sudo swapoff -a
        # sed to comment out swap partition at /etc/fstab
        sudo sed -i '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab
    else
        echo "No Swap partition to disable"
    fi
}

install_kubeadm(){
    # https://kubernetes.io/docs/setup/independent/install-kubeadm/
    command -v "kubectl" > /dev/null 2>&1 && {
        echo "kubernetes packages are already installed"
    } || {
        case $(get_pacman) in
        yum)
            echo "Installing using yum"
            # append repo to /etc/yum.repos.d/kubernetes.repo
            yum_repos="/etc/yum.repos.d/kubernetes.repo"
            sudo touch $yum_repos && cat $yum_repos | grep "kubernetes" || {
                echo "" | sudo tee -a $yum_repos && \
                echo '[kubernetes]' | sudo tee -a $yum_repos && \
                echo 'name=Kubernetes' | sudo tee -a $yum_repos && \
                echo 'baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64' | sudo tee -a $yum_repos && \
                echo 'enabled=1' | sudo tee -a $yum_repos && \
                echo 'gpgcheck=1' | sudo tee -a $yum_repos && \
                echo 'repo_gpgcheck=1' | sudo tee -a $yum_repos && \
                echo 'gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' | sudo tee -a $yum_repos && \
                echo 'exclude=kube*' | sudo tee -a $yum_repos
            }
            #lsmod | grep br_netfilter || sudo modprobe br_netfilter
            sudo setenforce 0
            # set SELinux in permissive mode to allow containers to access the host filesystem, which is needed by pod networks for example
            sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
            sudo yum install -y kubernetes-cni kubeadm kubelet kubectl --disableexcludes=kubernetes
            ;;
        apt-get)
            echo "Installing using apt-get"
            # create the file if not existing and append the repo to it
            sudo touch /etc/apt/sources.list.d/kubernetes.list && cat /etc/apt/sources.list.d/kubernetes.list | grep "kubernetes" || {
                curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
                #echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
                # not all ubuntu versions have a repo, so we got to hard code it to the latest based on k8s website
                echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
            }
            # install
            sudo apt-get update -q && \
            sudo apt-get install -qy kubernetes-cni kubeadm kubelet kubectl
            ;;
        pacman)
            echo "Installing from AUR"
            command -v git > /dev/null 2>&1 || sudo pacman -Sy git --noconfirm
            # some dependencies are needed to package
            pacman -Qs binutils > /dev/null 2>&1 || sudo pacman -Sy binutils --noconfirm
            pacman -Qs fakeroot || sudo pacman -Sy fakeroot --noconfirm
            # cloning packages from AUR to HOME
            CURR_DIR=$(get_curr_dir)
            echo "CURR DIR is: "$CURR_DIR
            cd $HOME
            git clone https://aur.archlinux.org/kubernetes-cni-bin.git && cd kubernetes-cni-bin && makepkg -si --noconfirm
            cd $HOME
            git clone https://aur.archlinux.org/kubelet-bin.git && cd kubelet-bin && makepkg -si --noconfirm
            cd $HOME
            git clone https://aur.archlinux.org/kubeadm-bin.git && cd kubeadm-bin && makepkg -si --noconfirm
            cd $HOME
            git clone https://aur.archlinux.org/kubectl-bin.git && cd kubectl-bin && makepkg -si --noconfirm
            cd $CURR_DIR
            ;;
        esac
        sudo systemctl enable --now kubelet
    }
}

init_cluster(){
    # use kubeadm to start a k8s master node
    # https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
    # 1: --apiserver-advertise-address, the IP address K8s should advertise his API server on
    # 2: --pod-network-cidr, is used for networking, an address space is to be specified for the containers
    # 3: --kubernetes-version, is used to select a K8s version
    # : --apiserver-cert-extra-sans
    # : --skip-preflight-checks, checks for the host kernel to make sure required features are available
    # e.g. sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.50.10 --kubernetes-version stable-1.8
    # run init iff we did not already do it, i.e. there is no connection token available
    # --
    # issue: failed to load admin kubeconfig: open /etc/kubernetes/admin.conf: permission denied
    # returned on a fresh system: https://github.com/kubernetes/kubeadm/issues/303
    # we add > /dev/null 2>&1, as we only want to know the number of tokens and not this spammy message
    if [[ $(kubeadm token list > /dev/null 2>&1 | awk 'FNR > 1 { print $1 }' | wc -l) -eq 0 ]]; then
        echo "Running kubeadm init on master node"
        sudo kubeadm init --pod-network-cidr=${1} --apiserver-advertise-address=${2} --kubernetes-version=${3} --ignore-preflight-errors=all
    else
        echo "Init on master was already ran"
    fi
}

get_tokens(){
    # get token created during the init phase
    if [[ $(sudo kubeadm token list | awk 'FNR > 1 { print $1 }' | wc -l) -gt 0 ]]; then
        token=$(sudo kubeadm token list | awk 'FNR > 1 { print $1 }')
        sudo kubeadm token delete $token
    fi
    # creating a new join command to be used on the workers
    sudo kubeadm token create --print-join-command > ~/worker_init.sh
}

join_cluster(){
    # use kubeadm to join the cluster
    # e.g. sudo kubeadm join --token TOKEN 192.168.1.100:6443 --discovery-token-ca-cert-hash HASH
    #sudo kubeadm join --token ${1} ${2} --discovery-token-ca-cert-hash ${3}
    sudo chmod +x ~/worker_init.sh
    sudo ~/worker_init.sh
}

get_filename(){
    # returns the last substring based on the char / or the input string otherwise
    echo "${1##*/}"
}

upload_file_on_workers(){
    # 1: key path
    # 2: port
    # 3: file path
    # 4: user
    # 5: destination folder
    # 6: command to be ran on the file (optional)
    echo "We have ${#WORKERS[@]} workers"
    for W in "${WORKERS[@]}"
    do
        filename=$(get_filename "${3}")
        echo "==> Uploading file $filename to worker at $W"
        $(upload_file "${1}" "${2}" "${3}" "${4}" "${W}" "${5}")
        # the command is optional, i.e. ran only if passed
        if [ $# -gt 5 ]; then
            echo "Running command ${6} on remote host ${W}"
            $(run_remote_command "${1}" "${2}" "${4}" "${W}" "${6}")
        fi
    done
}

set_kubectl(){
    # copies the k8s config file to the selected user HOME
    mkdir -p ~/.kube
    sudo cp -f /etc/kubernetes/admin.conf ~/.kube/admin.conf && \
    sudo chown $(id -u):$(id -g) ~/.kube/admin.conf && \
    export KUBECONFIG=~/.kube/admin.conf && {
        # append only the first time we run it
        cat ~/.bashrc | grep KUBECONFIG > /dev/null 2>&1 || echo "export KUBECONFIG=~/.kube/admin.conf" | tee -a ~/.bashrc
    } && echo "kubectl should now work correctly"
}

set_flannel(){
    # action: apply, delete
    kubectl ${1} -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
    # add flannel cfg
    #kubectl ${1} -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    #kubectl ${1} -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
}

set_dashboard(){
    kubectl ${1} -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
}

set_weave(){
    # add weave as container network manager
    kubectl ${1} -f https://cloud.weave.works/k8s/net?k8s-version="$(kubectl version | base64 | tr -d '\n')"
}

set_calico(){
    # add calico
    kubectl ${1} -f https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/calico.yaml
    # Download and install `calicoctl`
    #wget https://github.com/projectcalico/calico-containers/releases/download/v0.22.0/calicoctl
    #sudo chmod +x calicoctl
}

schedule_master(){
    # https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#control-plane-node-isolation
    kubectl taint nodes --all node-role.kubernetes.io/master-
}

add_nodeip_to_kubelet_config(){
    # needed when installing in a bunch of vagrant VMs where we got multiple network interfaces (eth0, eth1, etc.) and the wrong one may be taken
    # e.g. https://medium.com/@joatmon08/playing-with-kubeadm-in-vagrant-machines-part-2-bac431095706
    target_file = "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"

    # make sure we can access the folder
    sudo mkdir -p $(dirname "$target_file")

    # Note: This dropin only works with kubeadm and kubelet v1.11+
    echo '[Service]' | sudo tee $target_file
    echo 'Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"' | sudo tee -a $target_file
    echo 'Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"' | sudo tee -a $target_file
    echo '# This is a file that kubeadm init and kubeadm join generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically' | sudo tee -a $target_file
    echo 'EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env' | sudo tee -a $target_file
    echo '# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use' | sudo tee -a $target_file
    echo '# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.' | sudo tee -a $target_file
    echo 'EnvironmentFile=-/etc/default/kubelet' | sudo tee -a $target_file
    echo "Environment='KUBELET_EXTRA_ARGS=--node-ip="${1}"'" | sudo tee -a $target_file
    echo 'ExecStart=' | sudo tee -a $target_file
    echo 'ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS' | sudo tee -a $target_file

    # restart kubelet systemd-daemon
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
}

#################################################
# convert to array
WORKERS=($WORKERS)

# check if we run as main or as specific function
if [ $# -eq 0 ]; then
    echo "We have ${#WORKERS[@]} workers"
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    # upload whatever private ssh key we set to use to the master node, with target name key (so that we know what to expect when doing init)
    echo "Uploading ssh key file $(get_filename $SSH_KEY_PATH) to master node"
    $(upload_file "$SSH_KEY_PATH" 22 "$SSH_KEY_PATH" $CLUSTER_USER $MASTER_HOST '~/key')

    echo "Uploading setup script to master node at $MASTER_HOST"
    $(upload_file $SSH_KEY_PATH 22 "$SCRIPT_DIR/setup.sh" $CLUSTER_USER $MASTER_HOST "~/")
    $(run_remote_command $SSH_KEY_PATH 22 $CLUSTER_USER $MASTER_HOST "chmod +x ~/setup.sh; ~/setup.sh init")

    # upload setup file on each worker, run the command on the setup file
    echo "$(upload_file_on_workers ${SSH_KEY_PATH} 22 ${SCRIPT_DIR}/setup.sh ${CLUSTER_USER} '~/' 'chmod +x ~/setup.sh; ~/setup.sh add')"
else
    if [ "$1" = "init" ]; then
        echo "---- Creating K8s cluster, init on Master node! ----"
        echo $(setup_docker)
        echo $(disable_swap)
        echo $(install_kubeadm)
        echo $(init_cluster "$CIDR_NET" "$MASTER_HOST" "$KUBE_VERSION")
        # create join file
        echo $(get_tokens)
        echo "$(upload_file_on_workers ~/key 22 ~/worker_init.sh $(whoami) '~/')"
        # export kubeconfig
        echo $(set_kubectl)
        # add networking
        echo $(set_flannel "apply")
        echo $(set_dashboard "apply")
        echo "---- end master node setup ----"
    elif [ "$1" = "add" ]; then
        echo "---- Initializing setup on $(hostname) ----"
        echo $(setup_docker)
        echo $(disable_swap)
        echo $(install_kubeadm)
        echo $(join_cluster)
        # in case we use vagrant VMs to host the workers, make sure to pass --node-ip to the kubelet startup
        if [[ "$(whoami)" = "vagrant" ]]; then
            echo "eth0 has IP: $(get_ip_v4 'eth0'), eth1 has IP: $(get_ip_v4 'eth1')"
            echo $(add_nodeip_to_kubelet_config "$(get_ip_v4 'eth1')")
        fi
        echo "---- end setup on $(hostname) ----"
    else
        echo "passed parameter $1 not recognized!"
        exit 1;
    fi
fi
