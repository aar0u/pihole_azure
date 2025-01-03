output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip" {
  value = azurerm_public_ip.public_ip1.ip_address
}

output "lb_pool_outbound" {
  value = azurerm_lb_backend_address_pool.lb_pool_outbound.id
}
