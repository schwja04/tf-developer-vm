provider "azurerm" {
  features {}
  subscription_id = var.resource_group_config.subscription_id
}