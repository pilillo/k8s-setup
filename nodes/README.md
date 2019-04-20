To start the nodes:  
``vagrant up``

To show the status:  
``vagrant global-status``

To run the provision on the nodes:  
``vagrant provision``

To test if Ansible can correctly reach the nodes:
``ansible all -i <host-inventory-file> -m ping``

To ssh on a node:  
``vagrant ssh <node-name>`` or ``ssh vagrant@192.168.50.xx``

To stop the nodes:  
``vagrant halt``

To destroy the node:  
``vagrant destroy``
