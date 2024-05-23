# cloud-config

groups:
  - ansible

users:
  - default:
  - name: ansible
    primary_group: ansible
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICjOFPiVr+kTJtqYU+TQs9XH+2Qdo2KqCV+8sEnOOLZA ansible@talkscriber.com
