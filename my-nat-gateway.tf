# NAT gateway is costy, vm can go internet via current LB with public IP

# resource "azurerm_public_ip" "my_terraform_public_ip_nat" {
#   name                = "my-public-ip-nat-gateway"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1"]
# }

# resource "azurerm_nat_gateway" "my_terraform_nat" {
#   name                    = "my-nat-gateway"
#   location                = azurerm_resource_group.rg.location
#   resource_group_name     = azurerm_resource_group.rg.name
#   sku_name                = "Standard"
#   idle_timeout_in_minutes = 4
#   zones                   = ["1"]
# }

# resource "azurerm_nat_gateway_public_ip_association" "my_terraform_nat_public_ip_assoc" {
#   nat_gateway_id      = azurerm_nat_gateway.my_terraform_nat.id
#   public_ip_address_id = azurerm_public_ip.my_terraform_public_ip_nat.id
# }

# resource "azurerm_subnet_nat_gateway_association" "my_terraform_nat_subnet_assoc" {
#   nat_gateway_id = azurerm_nat_gateway.my_terraform_nat.id
#   subnet_id      = azurerm_subnet.my_terraform_subnet.id
# }
