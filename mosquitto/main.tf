data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "this_resource_group" {
  location = var.resource_group_location
  name     = var.resource_group_name
}


resource "random_pet" "this" {
  length    = 4
  separator = "-"
}

resource "azurerm_virtual_network" "this" {
  name                = "example-vnet"
  address_space       = ["10.42.42.0/24"]
  location            = azurerm_resource_group.this_resource_group.location
  resource_group_name = azurerm_resource_group.this_resource_group.name
}

resource "azurerm_subnet" "primary" {
  name                 = "primary-subnet"
  address_prefixes     = ["10.42.42.0/25"]
  resource_group_name  = azurerm_resource_group.this_resource_group.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_subnet" "secondary" {
  name                 = "secondary-subnet"
  address_prefixes     = ["10.42.42.128/25"]
  resource_group_name  = azurerm_resource_group.this_resource_group.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_public_ip" "broker_public_ip" {
  name                = "broker-public-ip"
  location            = azurerm_resource_group.this_resource_group.location
  resource_group_name = azurerm_resource_group.this_resource_group.name
  sku                 = "Basic" 
  allocation_method   = "Dynamic"
  domain_name_label   = "csegt-${random_pet.this.id}"

}

resource "azurerm_network_security_group" "broker_nsg" {
  name                = "broker-nsg"
  location            = azurerm_resource_group.this_resource_group.location
  resource_group_name = azurerm_resource_group.this_resource_group.name
}

data "http" "myip" {
  url = "https://api.ipify.org"
}

resource "azurerm_network_security_rule" "local_ip" {
  name                        = "local-ip"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "${chomp(data.http.myip.response_body)}"
  destination_address_prefix  = azurerm_subnet.primary.address_prefixes[0] 
  resource_group_name         = azurerm_resource_group.this_resource_group.name
  network_security_group_name = azurerm_network_security_group.broker_nsg.name
}

resource "azurerm_dns_zone" "hudson_dns_zone" {
  name                = "hudsonise.com"
  resource_group_name = var.global_resource_group_name
}

resource "azurerm_dns_cname_record" "target" {
  name                = "mqtt1"
  zone_name           = azurerm_dns_zone.hudson_dns_zone.name
  resource_group_name = azurerm_dns_zone.hudson_dns_zone.resource_group_name
  ttl                 = 60
  record              = azurerm_public_ip.broker_public_ip.fqdn
}

resource "azurerm_dns_txt_record" "example" {
  name                = "@"
  zone_name           = azurerm_dns_zone.hudson_dns_zone.name
  resource_group_name = azurerm_dns_zone.hudson_dns_zone.resource_group_name
  ttl                 = 300

  record {
    value = "MS=ms28151617"
  }
}
