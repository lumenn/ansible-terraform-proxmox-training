variable "proxmox_api_token" {
  description = "Proxmox API token accordint to this schema username@realm!provider=xxxx-xxx-xxx-xxx"
  type        = string
}

variable "proxmox_endpoint" {
  description = "Full https link like https://proxmox.com:8006 with port address."
  type        = string
}

terraform {
  required_version = "1.7.2"
  required_providers {
    proxmox = {
      source  = "registry.opentofu.org/bpg/proxmox"
      version = "0.61.1"
    }
    ansible = {
      source  = "registry.opentofu.org/ansible/ansible"
      version = "1.3.0"
    }
    local = {
      source  = "registry.opentofu.org/hashicorp/local"
      version = "2.5.1"
    }
  }
}


provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent    = true
    username = "terraform"
  }

}

