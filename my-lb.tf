# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip_lb" {
  name                = "my-public-ip-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "my_terraform_lb" {
  name                = "my-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public-ip-config"
    public_ip_address_id = azurerm_public_ip.my_terraform_public_ip_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "my_terraform_lb_pool" {
  loadbalancer_id = azurerm_lb.my_terraform_lb.id
  name            = "backend-pool"
}

resource "azurerm_lb_rule" "my_lb_rule_ssh" {
  # resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "SSH"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.my_terraform_lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "my_lb_rule_dns" {
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "DNS"
  protocol                       = "Udp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = azurerm_lb.my_terraform_lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "my_lb_rule_pihole" {
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "Pihole"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.my_terraform_lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "my_lb_rule_api" {
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "API"
  protocol                       = "Tcp"
  frontend_port                  = 5006
  backend_port                   = 5000
  frontend_ip_configuration_name = azurerm_lb.my_terraform_lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_outbound_rule" "my_lb_outbound_rule" {
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "MyOutbound"
  protocol                       = "All"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.my_terraform_lb_pool.id
  allocated_outbound_ports       = 10000
  frontend_ip_configuration {
    name = azurerm_lb.my_terraform_lb.frontend_ip_configuration[0].name
  }
}
