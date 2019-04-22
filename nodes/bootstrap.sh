#!/usr/bin/env bash

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

if [[ $(cat ~/.ssh/authorized_keys | wc -l) -lt 2 ]]; then
    cat ~/.ssh/authorized_keys__ | tee -a ~/.ssh/authorized_keys
    rm ~/.ssh/authorized_keys__
fi


command -v python > /dev/null 2>&1 || {
   case $(get_pacman) in
        yum)
            "Installing using yum"
            sudo yum -y install python
            ;;
        apt-get)
            echo "Installing using apt-get"
            sudo apt-get -y install python
            ;;
        pacman)
            echo "Installing using pacman"
            sudo pacman -Sy python --noconfirm
            ;;
    esac

}
