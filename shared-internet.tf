resource "azurerm_public_ip" "public_ip1" {
  name                = "public-ip1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label
}

resource "azurerm_lb" "lb1" {
  name                = "lb1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public-ip-conf"
    public_ip_address_id = azurerm_public_ip.public_ip1.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_pool_outbound" {
  loadbalancer_id = azurerm_lb.lb1.id
  name            = "lb-pool-outbound"
}

resource "azurerm_lb_outbound_rule" "lb_rule_outbound" {
  loadbalancer_id          = azurerm_lb.lb1.id
  name                     = "lb-rule-outbound"
  protocol                 = "All"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.lb_pool_outbound.id
  allocated_outbound_ports = 10000
  frontend_ip_configuration {
    name = azurerm_lb.lb1.frontend_ip_configuration[0].name
  }
}

resource "azurerm_lb_backend_address_pool" "lb_pool_pihole" {
  loadbalancer_id = azurerm_lb.lb1.id
  name            = "lb-pool-pihole"
}

resource "azurerm_lb_nat_rule" "lb_pool_pihole_ssh" {
  resource_group_name            = azurerm_resource_group.rg_shared.name
  loadbalancer_id                = azurerm_lb.lb1.id
  name                           = "lb-pool-pihole-ssh"
  protocol                       = "Tcp"
  frontend_port_start            = 22
  frontend_port_end              = 23
  backend_port                   = 22
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb_pool_pihole.id
  frontend_ip_configuration_name = azurerm_lb.lb1.frontend_ip_configuration[0].name
}

resource "azurerm_lb_rule" "lb_pool_pihole_dns" {
  loadbalancer_id                = azurerm_lb.lb1.id
  name                           = "DNS"
  protocol                       = "Udp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = azurerm_lb.lb1.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool_pihole.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "lb_pool_pihole_web" {
  loadbalancer_id                = azurerm_lb.lb1.id
  name                           = "Pihole"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb1.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool_pihole.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "lb_pool_pihole_api" {
  loadbalancer_id                = azurerm_lb.lb1.id
  name                           = "API"
  protocol                       = "Tcp"
  frontend_port                  = 5006
  backend_port                   = 5000
  frontend_ip_configuration_name = azurerm_lb.lb1.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool_pihole.id]
  disable_outbound_snat          = true
}
