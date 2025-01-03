output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip" {
  value = azurerm_public_ip.public_ip1.ip_address
}

output "rg_shared" {
  value = {
    virtual_network_name           = azurerm_virtual_network.vnet1.name
    group_name                     = azurerm_resource_group.rg_shared.name
    address_id                     = azurerm_public_ip.public_ip1.id
    lb_id                          = azurerm_lb.lb1.id
    lb_pool_outbound_id            = azurerm_lb_backend_address_pool.lb_pool_outbound.id
    frontend_ip_configuration_name = azurerm_lb.lb1.frontend_ip_configuration[0].name
  }
}
