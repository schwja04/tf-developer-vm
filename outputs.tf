output "public_ip_address" {
  value = data.azurerm_public_ip.developer-public-ip-data.ip_address
  # value = azurerm_public_ip.developer-public-ip.ip_address 
}