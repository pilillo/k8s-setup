#!/usr/bin/env bash

get_pacman(){
    # one of these commands should always be available to install packages
    pacmans=( yum apt-get pacman )

    for i in "${pacmans[@]}"
    do
        command -v $i > /dev/null 2>&1 && {
            echo $i
            break
        }
    done
}

if [[ $(cat ~/.ssh/authorized_keys | wc -l) -lt 2 ]]; then
    cat ~/.ssh/authorized_keys__ | tee -a ~/.ssh/authorized_keys
    rm ~/.ssh/authorized_keys__
fi


#command -v python > /dev/null 2>&1 || {
   case $(get_pacman) in
        yum)
            "Installing using yum"
            sudo yum -y install python curl wget
            # installing docker
            sudo yum install -y yum-utils device-mapper-persistent-data lvm2
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum update -y && sudo yum install docker-ce -y

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

            sudo usermod -aG docker $(whoami)
            sudo systemctl enable docker
            sudo systemctl restart docker
            ;;
        apt-get)
            echo "Installing using apt-get"
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update -y
            sudo apt-get -y install python curl wget

            echo "Installing docker using apt-get"
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update -y
            # https://tecadmin.net/install-docker-on-ubuntu/
            sudo apt-get -y install apt-transport-https ca-certificates software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update -y
            sudo apt-get install -y docker-ce
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
            sudo usermod -aG docker $(whoami)
            sudo systemctl enable docker
            sudo systemctl restart docker
            ;;
        pacman)
            echo "Installing using pacman"
            sudo pacman -Syyu --noconfirm
            sudo pacman -Sy python curl wget --noconfirm
            sudo pacman -Sy docker --noconfirm
            sudo usermod -aG docker $(whoami)
            # use overlay2 as underlying storage
            sudo mkdir -p /etc/docker
            docker_config="/etc/docker/daemon.json"
            echo "{" | sudo tee $docker_config
            echo '  "storage-driver": "overlay2"' | sudo tee -a $docker_config
            echo '}' | sudo tee -a $docker_config
            sudo mkdir -p /etc/systemd/system/docker.service.d
            sudo systemctl daemon-reload
            sudo systemctl enable docker
            sudo systemctl restart docker
            ;;
    esac

#}
