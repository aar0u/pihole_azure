output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "my_lb_ip_out" {
  value = azurerm_public_ip.my_terraform_public_ip_lb.ip_address
}
