### Resource Group - Begin ###
resource "azurerm_resource_group" "developer-rg" {
  name     = "${var.resource_group_config.prefix}-rg"
  location = var.resource_group_config.location

  tags = var.resource_group_config.tags
}
### Resource Group - End ###

### Network - Begin ###
resource "azurerm_virtual_network" "developer-vnet" {
  name                = "${var.resource_group_config.prefix}-vnet"
  resource_group_name = azurerm_resource_group.developer-rg.name
  location            = azurerm_resource_group.developer-rg.location
  address_space       = var.vnet_address_space

  tags = var.resource_group_config.tags
}

resource "azurerm_subnet" "developer-subnet" {
  name                 = "${var.resource_group_config.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.developer-rg.name
  virtual_network_name = azurerm_virtual_network.developer-vnet.name
  address_prefixes     = [for each in var.vnet_address_space : cidrsubnet(each, 8, 2)]
}
### Network - End ###

### Virtual Machine - Resources - Begin ###
#### Virtual Machine NIC - Begin ####
resource "azurerm_network_interface" "developer-nic" {
  name                = "${var.resource_group_config.prefix}-nic"
  location            = azurerm_resource_group.developer-rg.location
  resource_group_name = azurerm_resource_group.developer-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.developer-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.resource_group_config.tags
}
#### Virtual Machine NIC - End ####

#### Cloud Init - Begin ####
data "cloudinit_config" "vm-init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = file("scripts/init.yaml")
  }
}
#### Cloud Init - End ####

#### Source Image Reference - Begin ####
data "azurerm_platform_image" "developer-vm-image" {
  location  = azurerm_resource_group.developer-rg.location
  publisher = var.vm_config.os_image.publisher
  offer     = var.vm_config.os_image.offer
  sku       = var.vm_config.os_image.sku
  version   = var.vm_config.os_image.version
}
#### Source Image Reference - End ####

#### Virtual Machine - Begin ####
resource "azurerm_linux_virtual_machine" "developer-vm" {
  name                  = "${var.resource_group_config.prefix}-linux-vm"
  location              = azurerm_resource_group.developer-rg.location
  resource_group_name   = azurerm_resource_group.developer-rg.name
  size                  = var.vm_config.size
  admin_username        = var.vm_auth_config.admin_username
  network_interface_ids = [azurerm_network_interface.developer-nic.id]

  custom_data = data.cloudinit_config.vm-init.rendered

  disable_password_authentication = true
  admin_ssh_key {
    username   = var.vm_auth_config.admin_username
    public_key = file(var.vm_auth_config.admin_ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = data.azurerm_platform_image.developer-vm-image.publisher
    offer     = data.azurerm_platform_image.developer-vm-image.offer
    sku       = data.azurerm_platform_image.developer-vm-image.sku
    version   = data.azurerm_platform_image.developer-vm-image.version
  }

  tags = var.resource_group_config.tags
}
#### Virtual Machine - End ####
### Virtual Machine - Resources - End ###

