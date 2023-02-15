resource "azurerm_network_interface" "nic" {
  count               = var.vm_pool_instance_count
  name                = "nic-${count.index + 1}"
  location            = azurerm_resource_group.this_resource_group.location
  resource_group_name = azurerm_resource_group.this_resource_group.name

  ip_configuration {
    name                          = "nic-ipconfig-${count.index + 1}"
    subnet_id                     = azurerm_subnet.subnet_app_gateway.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc01" {
  count                   = var.vm_pool_instance_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "nic-ipconfig-${count.index + 1}"
  backend_address_pool_id = tolist(azurerm_application_gateway.app_gateway.backend_address_pool).0.id //azurerm_application_gateway.network.backend_address_pool[0].id
}

resource "random_password" "password" {
  length  = 16
  special = true
  lower   = true
  upper   = true
  number  = true
}

resource "azurerm_windows_virtual_machine" "vm" {
  count               = var.vm_pool_instance_count
  name                = "myVM${count.index + 1}"
  resource_group_name = azurerm_resource_group.this_resource_group.name
  location            = azurerm_resource_group.this_resource_group.location
  size                = "Standard_DS1_v2"
  admin_username      = "azureadmin"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm-extensions" {
  count                = var.vm_pool_instance_count
  name                 = "vm${count.index + 1}-ext"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS

}
