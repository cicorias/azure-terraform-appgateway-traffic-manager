
# ------------------- Bastion Host -------------------
resource "azurerm_bastion_host" "bastion_host" {
  location            = azurerm_resource_group.this_resource_group.location
  name                = "myVNet-bastion"
  resource_group_name = azurerm_resource_group.this_resource_group.name
  ip_configuration {
    name                 = "IpConf"
    public_ip_address_id = azurerm_public_ip.bastion_host_public_ip.id
    subnet_id            = azurerm_subnet.subnet_bastion_host.id
  }
  depends_on = [
    azurerm_public_ip.bastion_host_public_ip,
    azurerm_subnet.subnet_bastion_host,
  ]
}

