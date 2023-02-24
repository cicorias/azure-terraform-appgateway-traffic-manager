resource "azurerm_network_interface" "nic" {
  name                = "nic-1"
  location            = azurerm_resource_group.this_resource_group.location
  resource_group_name = azurerm_resource_group.this_resource_group.name

  ip_configuration {
    name                          = "nic-ipconfig-1"
    subnet_id                     = azurerm_subnet.primary.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.broker_public_ip.id
  }
}

# linux vm
# Create a Linux virtual machine with cloud-init
# Read in the public key from your local SSH key pair
locals {
  ssh_key_location = "~/.ssh/id_rsa.pub"
}

data "local_file" "ssh_pub_key" {
  filename = pathexpand(local.ssh_key_location)
}

resource "azurerm_linux_virtual_machine" "vmlinux" {
  name                = "broker-vm"
  resource_group_name = azurerm_resource_group.this_resource_group.name
  location            = azurerm_resource_group.this_resource_group.location
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"
  custom_data         = base64encode("${file("./resources/cloud-init.txt")}")

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.local_file.ssh_pub_key.content
  }
}

