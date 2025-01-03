variable "shared_group_name" {
  description = "The name of the resource group"
  default     = "shared"
}

variable "domain_name_label" {
  default     = "grub"
  description = "Domain name label for the public IP."
}

resource "azurerm_resource_group" "rg_shared" {
  location = var.resource_group_location
  name     = var.shared_group_name
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_pihole" {
  name                 = "subnet-pihole"
  resource_group_name  = azurerm_resource_group.rg_shared.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}
