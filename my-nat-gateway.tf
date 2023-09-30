resource "azurerm_public_ip_prefix" "my_terraform_nat_public_ip" {
  name                = "my-nat-gateway-public-ip-prefix"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  prefix_length       = 30
}

resource "azurerm_nat_gateway" "my_terraform_nat" {
  name                    = "my-nat-gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "my_terraform_nat_assoc" {
  nat_gateway_id      = azurerm_nat_gateway.my_terraform_nat.id
  public_ip_prefix_id = azurerm_public_ip_prefix.my_terraform_nat_public_ip.id
}
