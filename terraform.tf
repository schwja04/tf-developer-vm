terraform {
  required_providers {
    assert = {
      source  = "hashicorp/assert"
      version = "0.15.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.15.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.5"
    }
  }
  required_version = "~> 1.10.4"
}