Create an ssh key to use to connect to the nodes:  
``ssh-keygen -t rsa -b 4096 -f key -N ""``
The key is automatically loaded by the provisioner, and added to `~/.ssh/authorized_keys`.

To start the nodes:  
``vagrant up``
``vagrant up <host-name>``

To show the status:  
``vagrant global-status``

To run the provision on running nodes:  
``vagrant provision``

To run the provision on a stopped machine:  
``vagrant up --provision``

To reboot a machine and run the provisioner:  
``vagrant reload --provision``  

To test if Ansible can correctly reach the nodes:
``ansible all -i <host-inventory-file> -m ping``

To ssh on a node:  
``vagrant ssh <node-name>`` or ``ssh vagrant@192.168.50.xx``

To stop the nodes:  
``vagrant halt``

To destroy the node:  
``vagrant destroy``
