variable "resource_group_config" {
  type = object({
    subscription_id = string
    prefix          = string
    location        = string
    tags            = map(string)
  })
  description = "Base configuration for the resource group"
  default = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    prefix          = "unknown"
    location        = "Central US"
    tags = {
      environment = "dev"
    }
  }
}

variable "vm_config" {
  type = object({
    admin_username     = string
    admin_ssh_key_path = string
    size               = string
    os_image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    accessing_ips = set(string)
  })
  description = "Inputs for the virtual machine"
  default = {
    admin_username     = "serveradmin"
    admin_ssh_key_path = "~/.ssh/id_rsa.pub"
    size               = "Standard_B2ats_v2"
    os_image = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = null
    }
    accessing_ips = []
  }
}

variable "vnet_address_space" {
  type        = set(string)
  description = "Address space for the virtual network"
  default     = ["10.123.0.0/16"]
}