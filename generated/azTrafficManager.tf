
resource "azurerm_traffic_manager_profile" "atfm_profile" {
  name                   = "baseatfprofile" // TODO: Make this a variable
  resource_group_name    = azurerm_resource_group.this_resource_group.name
  traffic_routing_method = "Performance" // TODO: make this a variable
  dns_config {
    relative_name = "baseatfprofile" // TODO: Make this a variable
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