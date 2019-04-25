#!/usr/bin/env bash

# install sshpass which is needed by ansible to pass over the passwords to our VMs
command -v sshpass || {
    echo "sshpass not found. Installing latest version from sourceforge"
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    wget http://sourceforge.net/projects/sshpass/files/latest/download --directory-prefix=$SCRIPT_DIR -O sshpass.tar.gz
    CUR_DIR=$PWD
    cd $SCRIPT_DIR && tar -xvf sshpass.tar.gz && cd sshpass-* && ./configure && sudo make install
    cd $SCRIPT_DIR && rm sshpass.tar.gz && cd $CUR_DIR
}


get_pacman(){
    # one of these commands should always be available to install packages
    pacmans=( yum apt-get pacman pip )

    for i in "${pacmans[@]}"
    do
        command -v $i > /dev/null 2>&1 && {
            echo $i
            break
        }
    done
}

# install ansible
command -v ansible > /dev/null 2>&1 || {
    echo "Ansible is not installed!"

    case $(get_pacman) in
        yum)
            "Installing using yum"
            sudo yum install ansible
            ;;
        apt-get)
            echo "Installing using apt-get"
            sudo apt-get install software-properties-common
            sudo apt-add-repository ppa:ansible/ansible
            sudo apt-get update
            sudo apt-get install ansible
            ;;
        pacman)
            echo "Installing using pacman"
            sudo pacman -Sy ansible --noconfirm
            ;;
        pip)
            echo "Installing using pip"
            pip install -U ansible
            ;;
    esac
} && {
    # if ansible was correctly installed instruct deployment of K8s using the Ansible playbook
    echo "K8s Cluster setup"
    ansible all -i hosts -m ping
}
