resource "random_string" "atm_name_suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  atm_name = format("%s-%s", "spc", random_string.atm_name_suffix.id)
}

resource "azurerm_traffic_manager_profile" "atfm_profile" {
  name                   = local.atm_name
  resource_group_name    = azurerm_resource_group.this_resource_group.name
  traffic_routing_method = "Performance" // TODO: make this a variable
  dns_config {
    relative_name = local.atm_name
    ttl           = 60
  }
  monitor_config {
    path     = "/"
    port     = 443
    protocol = "HTTPS"
  }
  depends_on = [
    azurerm_resource_group.this_resource_group,
  ]
}

resource "azurerm_traffic_manager_azure_endpoint" "atfm_endpoint_1" {
  name               = "ag-endpoint-region1"
  profile_id         = azurerm_traffic_manager_profile.atfm_profile.id
  weight             = 100
  target_resource_id = azurerm_public_ip.app_gateway_public_ip.id
}