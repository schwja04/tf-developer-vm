output "public_ip_address" {
  value = data.azurerm_public_ip.tf-practice-public-ip-data.ip_address
  # value = azurerm_public_ip.tf-practice-public-ip.ip_address
}