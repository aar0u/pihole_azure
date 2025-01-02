# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "my-network-security-group"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.source_ip
    destination_address_prefix = "*"
    description               = "Allow SSH access from specified IP"
  }

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
    description               = "Allow DNS queries from specified IP"
  }

  security_rule {
    name                       = "WEB"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = var.source_ip
    destination_address_prefix = "*"
    description               = "Allow HTTP/HTTPS access from specified IP"
  }

  security_rule {
    name                       = "PUBLIC"
    priority                   = 330
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5000", "5001"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description               = "Allow application ports from specified IP"
  }
}
