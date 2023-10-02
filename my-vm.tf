locals {
  linux_init = templatefile("./templates/linux-init.sh",
  { public_ip : azurerm_public_ip.my_terraform_public_ip_lb.ip_address })
  vm_name = "pihole"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine_scale_set" "my_terraform_vm" {
  name                 = "${local.vm_name}-scaleset"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  sku                  = "Standard_B1s"
  instances            = 1
  user_data            = base64encode(local.linux_init)
  computer_name_prefix = "${local.vm_name}-vm-"
  admin_username       = var.username

  admin_ssh_key {
    username   = var.username
    public_key = var.public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  network_interface {
    name                      = "${local.vm_name}-scaleset-ni"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id

    ip_configuration {
      name                                   = "${local.vm_name}-scaleset-ip-configuration"
      primary                                = true
      subnet_id                              = azurerm_subnet.my_terraform_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.my_terraform_lb_pool.id]
    }
  }
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
