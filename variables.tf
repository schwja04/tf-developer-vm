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

  validation {
    condition = can(regex(
      "^[\\dA-Fa-f]{8}-[\\dA-Fa-f]{4}-[\\dA-Fa-f]{4}-[\\dA-Fa-f]{4}-[\\dA-Fa-f]{12}$",
      var.resource_group_config.subscription_id
    ))
    error_message = "The subscription_id must be a valid guid"
  }

  validation {
    condition     = length(var.resource_group_config.prefix) > 0
    error_message = "The prefix must be a non-empty string"
  }

  validation {
    condition     = length(var.resource_group_config.location) > 0
    error_message = "The location must be a valid Azure region and a non-empty string"
  }
}

variable "vm_auth_config" {
  sensitive = true

  type = object({
    admin_username     = string
    admin_ssh_key_path = string
  })
  description = "Authentication configuration for the virtual machine"
  default = {
    admin_username     = "serveradmin"
    admin_ssh_key_path = "~/.ssh/id_rsa.pub"
  }

  validation {
    condition     = length(var.vm_auth_config.admin_username) > 0
    error_message = "The admin_username must be a non-empty string"
  }

  validation {
    condition     = can(file(var.vm_auth_config.admin_ssh_key_path))
    error_message = "The admin_ssh_key_path must be a valid file path"
  }
}

variable "vm_config" {
  type = object({
    size = string
    os_image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  })
  description = "Inputs for the virtual machine"
  default = {
    size = "Standard_B2ats_v2"
    os_image = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = null
    }
  }

  validation {
    condition     = length(var.vm_config.size) > 0
    error_message = "The size must be a non-empty string"
  }
}

variable "vnet_address_space" {
  type        = set(string)
  description = "Address space for the virtual network"
  default     = ["10.123.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "The address space must be a non-empty set"
  }

  validation {
    condition     = alltrue([for ip in var.vnet_address_space : provider::assert::cidr(ip)])
    error_message = "The address space must be a valid CIDR block"
  }
}
