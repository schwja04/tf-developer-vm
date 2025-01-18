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

### Network Security Group - Begin ###
resource "azurerm_network_security_group" "developer-sg" {
  name                = "${var.resource_group_config.prefix}-sg"
  location            = azurerm_resource_group.developer-rg.location
  resource_group_name = azurerm_resource_group.developer-rg.name

  tags = var.resource_group_config.tags
}

resource "azurerm_network_security_rule" "developer-rule" {
  count = length(var.vm_config.source_address_prefixes) > 0 ? 1 : 0

  name                        = "${var.resource_group_config.prefix}-developer-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.vm_config.source_address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.developer-rg.name
  network_security_group_name = azurerm_network_security_group.developer-sg.name
}

resource "azurerm_subnet_network_security_group_association" "developer-sg-association" {
  subnet_id                 = azurerm_subnet.developer-subnet.id
  network_security_group_id = azurerm_network_security_group.developer-sg.id
}
### Network Security Group - End ###

### Public IP - Begin ###
resource "azurerm_public_ip" "developer-public-ip" {
  name                = "${var.resource_group_config.prefix}-public-ip"
  location            = azurerm_resource_group.developer-rg.location
  resource_group_name = azurerm_resource_group.developer-rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  tags = var.resource_group_config.tags
}
### Public IP - End ###

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
    public_ip_address_id          = azurerm_public_ip.developer-public-ip.id
  }

  tags = var.resource_group_config.tags
}
#### Virtual Machine NIC - End ####

#### Cloud Init - Begin ####
data "cloudinit_config" "vm-init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "docker-install.sh"
    content_type = "text/x-shellscript"

    content = file("scripts/docker-install.sh")
  }

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
  admin_username        = var.vm_config.admin_username
  network_interface_ids = [azurerm_network_interface.developer-nic.id]

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
    publisher = data.azurerm_platform_image.developer-vm-image.publisher
    offer     = data.azurerm_platform_image.developer-vm-image.offer
    sku       = data.azurerm_platform_image.developer-vm-image.sku
    version   = data.azurerm_platform_image.developer-vm-image.version
  }

  tags = var.resource_group_config.tags
}
#### Virtual Machine - End ####
### Virtual Machine - Resources - End ###

# This is a workaround to get the public IP address of the VM
# as the public_ip_address is not available until the VM is created.
# This is only necessary because I am using a Dynamic Public IP.
# Without this, a `terraform refresh` would be needed to get the public IP.
data "azurerm_public_ip" "developer-public-ip-data" {
  name                = azurerm_public_ip.developer-public-ip.name
  resource_group_name = azurerm_resource_group.developer-rg.name
  depends_on          = [azurerm_linux_virtual_machine.developer-vm]
}