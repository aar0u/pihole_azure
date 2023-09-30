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

resource "azurerm_lb_backend_address_pool_address" "my_terraform_lb_pool_adds" {
  name                    = "backend-ip"
  backend_address_pool_id = azurerm_lb_backend_address_pool.my_terraform_lb_pool.id
  virtual_network_id      = azurerm_virtual_network.my_terraform_network.id
  ip_address              = azurerm_network_interface.my_terraform_nic.private_ip_address
}

resource "azurerm_lb_rule" "my_lb_rule_ssh" {
  # resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "SSH"
  protocol                       = "Tcp"
  frontend_port                  = 81
  backend_port                   = 22
  frontend_ip_configuration_name = "public-ip-config"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
}

resource "azurerm_lb_rule" "my_lb_rule_dns" {
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "DNS"
  protocol                       = "Udp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = "public-ip-config"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
}

resource "azurerm_lb_rule" "my_lb_rule_web" {
  loadbalancer_id                = azurerm_lb.my_terraform_lb.id
  name                           = "WEB"
  protocol                       = "Tcp"
  frontend_port                  = 91
  backend_port                   = 80
  frontend_ip_configuration_name = "public-ip-config"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
}
