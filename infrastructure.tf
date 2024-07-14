data "local_file" "ssh_public_key" {
  filename = "./key.pub"
}

variable "username" {
  type = string
}

resource "proxmox_virtual_environment_vm" "ansible-target" {
  node_name = "thor"
  name      = "ansible-target"

  reboot = true

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.debian-image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 32
  }

  initialization {
    datastore_id = "local-zfs"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud-config.id
  }

  network_device {
    bridge = "vmbr0"
  }

  serial_device {
    device = "socket"
  }
}

resource "proxmox_virtual_environment_file" "cloud-config" {
  datastore_id = "media"
  content_type = "snippets"
  node_name    = "thor"


  source_raw {
    data      = <<-EOF
    #cloud-config
    fqdn: ansible-target
    users:
      - default
      - name: ${var.username}
        groups :
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    runcmd:
      - apt update
      - apt install -y qemu-guest-agent net-tools
      - timedatectl set timezone Europe/Warsaw
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
      EOF
    file_name = "cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_download_file" "debian-image" {
  content_type = "iso"
  datastore_id = "media"
  node_name    = "thor"
  file_name    = "debian-12-generic-amd64.img"
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"

}

resource "ansible_playbook" "ensure-packages-installed" {
  playbook   = "./playbooks/ensure_packages_installed.yml"
  name       = proxmox_virtual_environment_vm.ansible-target.name
  replayable = true
}
