locals {
  cloudinit_userdata = {
    groups = [
      "ansible",
      "admins"
    ],
    users = [
      {
        name = "ansible",
        primary_group = "ansible",
        shell = "/bin/bash",
        ssh-authorized-keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICjOFPiVr+kTJtqYU+TQs9XH+2Qdo2KqCV+8sEnOOLZA ansible@domain.com",
        sudo = "ALL=(ALL) NOPASSWD:ALL"
      }
    ]
  }
}

output "cloudinit_userdata" {
  value = templatefile("../templates/bastion-host-cloudinit.yaml.tftpl", { cloudinit_userdata = local.cloudinit_userdata})
}
