# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.target_group_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "DNS"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = var.source_ip
    destination_address_prefix = "*"
    description                = "Allow DNS queries from specified IP"
  }

  security_rule {
    name                       = "AllowFromMyIP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443"]
    source_address_prefix      = var.source_ip
    destination_address_prefix = "*"
    description                = "Allow access from specified IP"
  }

  security_rule {
    name                       = "PublicPorts"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5000", "5001"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow ports from Public"
  }
}
