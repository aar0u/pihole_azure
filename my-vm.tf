locals {
  linux_init = templatefile("./templates/linux-init.sh",
    {
      resource_group_name : azurerm_resource_group.rg.name,
      nsg_name : azurerm_network_security_group.my_terraform_nsg.name,
      public_ip : azurerm_public_ip.my_terraform_public_ip_lb.ip_address,
      subscription_id : data.azurerm_subscription.current.subscription_id,
      module_path : path.module,
      username : var.username
    }
  )
  vm_name = "pihole"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine_scale_set" "my_scale_set" {
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

  identity {
    type = "SystemAssigned"
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

resource "azurerm_monitor_autoscale_setting" "my_scale_set_autoscale" {
  name                = "${local.vm_name}-scaleset-autoscale-profiles"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.my_scale_set.id

  profile {
    name = "profile1"
    capacity {
      default = 1
      minimum = 1
      maximum = 1
    }
  }
}

resource "azurerm_role_assignment" "vm_nsg_contributor" {
  scope                = azurerm_network_security_group.my_terraform_nsg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_linux_virtual_machine_scale_set.my_scale_set.identity[0].principal_id
}
