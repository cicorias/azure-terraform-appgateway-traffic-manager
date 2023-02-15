data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "this_resource_group" {
  location = var.resource_group_location
  name     = var.resource_group_name
}


# ------------------- Azure Key Vault -------------------
resource "azurerm_key_vault" "key_vault" {
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  location                        = azurerm_resource_group.this_resource_group.location
  name                            = "scicoriakv2" //TODO: move to variable
  resource_group_name             = azurerm_resource_group.this_resource_group.name
  sku_name                        = "standard" //TODO: move to variable
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  depends_on = [
    azurerm_resource_group.this_resource_group,
  ]
}

// TODO: the following not used now -- as loading pfx from file
# resource "azurerm_key_vault_certificate" "ag_certificate" {
#   key_vault_id = azurerm_key_vault.key_vault.id
#   name         = "servercert4" //TODO: move to variable
#   certificate_policy {
#     issuer_parameters {
#       name = "Unknown"
#     }
#     key_properties {
#       exportable = true
#       key_type   = "EC"
#       reuse_key  = false
#     }
#     lifetime_action {
#       action {
#         action_type = "EmailContacts"
#       }
#       trigger {
#         lifetime_percentage = 80
#       }
#     }
#     secret_properties {
#       content_type = "application/x-pkcs12"
#     }
#   }
#   depends_on = [
#     azurerm_key_vault.key_vault,
#   ]
# }


resource "azurerm_public_ip" "app_gateway_public_ip" {
  allocation_method   = "Static"
  domain_name_label   = "scicoriaag1"
  location            = azurerm_resource_group.this_resource_group.location
  name                = "myAGPublicIPAddress"
  resource_group_name = azurerm_resource_group.this_resource_group.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.this_resource_group,
  ]
}

resource "azurerm_virtual_network" "az_vnet" {
  address_space       = ["10.21.0.0/16"]
  location            = azurerm_resource_group.this_resource_group.location
  name                = "myVNet"
  resource_group_name = azurerm_resource_group.this_resource_group.name
  depends_on = [
    azurerm_resource_group.this_resource_group,
  ]
}
resource "azurerm_public_ip" "bastion_host_public_ip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this_resource_group.location
  name                = "myVNet-ip"
  resource_group_name = azurerm_resource_group.this_resource_group.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.this_resource_group,
  ]
}
resource "azurerm_subnet" "subnet_bastion_host" {
  address_prefixes     = ["10.21.2.0/26"]
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.this_resource_group.name
  virtual_network_name = "myVNet"
  depends_on = [
    azurerm_virtual_network.az_vnet,
  ]
}
resource "azurerm_subnet" "subnet_app_gateway" {
  address_prefixes     = ["10.21.1.0/24"]
  name                 = "myBackendSubnet"
  resource_group_name  = azurerm_resource_group.this_resource_group.name
  virtual_network_name = "myVNet"
  depends_on = [
    azurerm_virtual_network.az_vnet,
  ]
}
resource "azurerm_subnet" "subnet_app_gateway_2" {
  address_prefixes     = ["10.21.0.0/24"]
  name                 = "myAGSubnet"
  resource_group_name  = azurerm_resource_group.this_resource_group.name
  virtual_network_name = "myVNet"
  depends_on = [
    azurerm_virtual_network.az_vnet,
  ]
}
