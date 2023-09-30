resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

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
  }
  security_rule {
    name                       = "WEB"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.source_ip
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "my-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    # access from lb
    # public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "my-vm-pihole"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_B1s"
  user_data             = base64encode(local.linux_init)

  os_disk {
    name                 = "my-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "my-vm-pihole"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDX0B543UN5echyv/Fvd5pHJpbB3GMMV6YAovhZwYRiSBUgp7GFUMA6fz19tArF5GmH0isLcDs7SXvi9AILNr6FmmaiBsEqfXKC7wtxVamhpFInkIMJDvNKTvpnTit6oUJ4Zx30v+53zakib7ak6i9PojU/ZJtWjZp6mSU7znlKJkbrZK41nu00pH3A6idi4Ti6MfMJ3sORfQqCG7exftXgXRUj/BsVetIPHx68n+7sUcOT8USMES9D3LHGX/zWdUnAjBBUa8o5S29o33OKc+3/V4KBqXtd+WMilFkvc2/IMULB5q8LohEdUo1WupquJx75PVDoOfIZ6TqwhIZgxXwDkT7r7fn1R7jsSt33gqoGMzQOH7MIGzw9qlejlIWe17ELicH/EWHEwR/VIHgvsuO15utoC5HepwbKalwK3rWoe5sZEEDrM6iEVE6DUn+1gZqvUYhIncwRu8/vMw5QpySA2jxXleBanF/XjJyyA/RC4Pas+l36Q0wuBNa+MZQUyIk= generated-by-azure"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

locals {
  linux_init = templatefile("./templates/linux-init.sh", {})
}
