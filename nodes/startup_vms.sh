# ramp up vms and run provisioning via the bootup.sh script
vagrant up --provision
# we need to reload the vms to make sure modules like overlayfs are properly loaded
vagrant reload
