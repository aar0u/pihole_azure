locals {
  init_script = templatefile("./scripts/init.sh",
    {
      resource_group_name : azurerm_resource_group.rg.name,
      nsg_name : azurerm_network_security_group.my_terraform_nsg.name,
      public_ip : azurerm_public_ip.public_ip1.ip_address,
      subscription_id : data.azurerm_subscription.current.subscription_id,
      module_path : path.module,
      username : var.username
    }
  )
  sku = "Standard_B2ats_v2"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine_scale_set" "my_scale_set" {
  name                 = "${var.target_group_name}-ss"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  sku                  = local.sku
  instances            = 1
  user_data            = base64encode(local.init_script)
  computer_name_prefix = "${var.target_group_name}-vm-"
  admin_username       = var.username
  zones                = ["1"]

  admin_ssh_key {
    username   = var.username
    public_key = var.public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-minimal-jammy"
    sku       = "minimal-22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  network_interface {
    name                      = "${var.target_group_name}-scaleset-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id

    ip_configuration {
      name                                   = "${var.target_group_name}-scaleset-ip-conf"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet_pihole.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_pool_outbound.id, azurerm_lb_backend_address_pool.lb_pool_pihole.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "my_scale_set_autoscale" {
  name                = "${var.target_group_name}-scaleset-autoscale-profiles"
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
