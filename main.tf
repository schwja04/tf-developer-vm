### Resource Group - Begin ###
resource "azurerm_resource_group" "tf-practice-rg" {
  name     = "${var.resource_group_config.prefix}-rg"
  location = var.resource_group_config.location

  tags = var.resource_group_config.tags
}
### Resource Group - End ###

### Network - Begin ###
resource "azurerm_virtual_network" "tf-practice-vnet" {
  name                = "${var.resource_group_config.prefix}-vnet"
  resource_group_name = azurerm_resource_group.tf-practice-rg.name
  location            = azurerm_resource_group.tf-practice-rg.location
  address_space       = var.vnet_address_space

  tags = var.resource_group_config.tags
}

resource "azurerm_subnet" "tf-practice-subnet" {
  name                 = "${var.resource_group_config.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.tf-practice-rg.name
  virtual_network_name = azurerm_virtual_network.tf-practice-vnet.name
  address_prefixes     = [for each in var.vnet_address_space: cidrsubnet(each, 8, 2)]
}
### Network - End ###

### Network Security Group - Begin ###
resource "azurerm_network_security_group" "tf-practice-sg" {
  name                = "${var.resource_group_config.prefix}-sg"
  location            = azurerm_resource_group.tf-practice-rg.location
  resource_group_name = azurerm_resource_group.tf-practice-rg.name

  tags = var.resource_group_config.tags
}

resource "azurerm_network_security_rule" "tf-practice-developer-rule" {
  name                        = "${var.resource_group_config.prefix}-developer-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = length(var.vm_config.accessing_ips) > 0 ? var.vm_config.accessing_ips : ["*"] 
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tf-practice-rg.name
  network_security_group_name = azurerm_network_security_group.tf-practice-sg.name
}

resource "azurerm_subnet_network_security_group_association" "tf-practice-sg-association" {
  subnet_id                 = azurerm_subnet.tf-practice-subnet.id
  network_security_group_id = azurerm_network_security_group.tf-practice-sg.id
}
### Network Security Group - End ###

### Public IP - Begin ###
resource "azurerm_public_ip" "tf-practice-public-ip" {
  name                = "${var.resource_group_config.prefix}-public-ip"
  location            = azurerm_resource_group.tf-practice-rg.location
  resource_group_name = azurerm_resource_group.tf-practice-rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  tags = var.resource_group_config.tags
}
### Public IP - End ###

### Virtual Machine - Resources - Begin ###
#### Virtual Machine NIC - Begin ####
resource "azurerm_network_interface" "tf-practice-nic" {
  name                = "${var.resource_group_config.prefix}-nic"
  location            = azurerm_resource_group.tf-practice-rg.location
  resource_group_name = azurerm_resource_group.tf-practice-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf-practice-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf-practice-public-ip.id
  }

  tags = var.resource_group_config.tags
}
#### Virtual Machine NIC - End ####

#### Cloud Init - Begin ####
data "cloudinit_config" "vm-init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"

    content = file("scripts/provision-basic.sh")
  }

  part {
    content_type = "text/cloud-config"

    content = file("scripts/init.yaml")
  }
}
#### Cloud Init - End ####

#### Source Image Reference - Begin ####
data "azurerm_platform_image" "tf-practice-image" {
  location  = azurerm_resource_group.tf-practice-rg.location
  publisher = var.vm_config.os_image.publisher
  offer     = var.vm_config.os_image.offer
  sku       = var.vm_config.os_image.sku
  version   = var.vm_config.os_image.version
}
#### Source Image Reference - End ####

#### Virtual Machine - Begin ####
resource "azurerm_linux_virtual_machine" "tf-practice-vm" {
  name                  = "${var.resource_group_config.prefix}-linux-vm"
  location              = azurerm_resource_group.tf-practice-rg.location
  resource_group_name   = azurerm_resource_group.tf-practice-rg.name
  size                  = var.vm_config.size
  admin_username        = var.vm_config.admin_username
  network_interface_ids = [azurerm_network_interface.tf-practice-nic.id]

  custom_data = data.cloudinit_config.vm-init.rendered

  disable_password_authentication = true
  admin_ssh_key {
    username   = var.vm_config.admin_username
    public_key = file(var.vm_config.admin_ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = data.azurerm_platform_image.tf-practice-image.publisher
    offer     = data.azurerm_platform_image.tf-practice-image.offer
    sku       = data.azurerm_platform_image.tf-practice-image.sku
    version   = data.azurerm_platform_image.tf-practice-image.version
  }

  tags = var.resource_group_config.tags
}
#### Virtual Machine - End ####
### Virtual Machine - Resources - End ###

data "azurerm_public_ip" "tf-practice-public-ip-data" {
  name                = azurerm_public_ip.tf-practice-public-ip.name
  resource_group_name = azurerm_resource_group.tf-practice-rg.name
  depends_on          = [azurerm_linux_virtual_machine.tf-practice-vm]
}