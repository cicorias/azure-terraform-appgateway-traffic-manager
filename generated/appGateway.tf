locals {
  trusted_client_certificate_chain_1 = "ca2"
  ssl_profile_one                    = "ssl_profile_one"
  // etc. trusted_client_certificate_chain_2 = "ca3"
}


# ------------------- Azure Application Gateway -------------------
resource "azurerm_user_assigned_identity" "user_identity" {
  location            = azurerm_resource_group.this_resource_group.location
  name                = "usermsi1"
  resource_group_name = azurerm_resource_group.this_resource_group.name
  depends_on = [
    azurerm_resource_group.this_resource_group,
  ]
}

resource "azurerm_application_gateway" "app_gateway" {
  location            = azurerm_resource_group.this_resource_group.location
  name                = "myAppGateway"
  resource_group_name = azurerm_resource_group.this_resource_group.name

  backend_address_pool {
    name = "myBackendPool"
  }
  backend_http_settings {
    affinity_cookie_name  = "ApplicationGatewayAffinity"
    cookie_based_affinity = "Disabled"
    name                  = "myHTTPsetting"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }
  frontend_ip_configuration {
    name = "myAGIPConfig"
    # private_link_configuration_name = "aglink" // DEBUG: removed
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }
  frontend_port {
    name = "myFrontendPort"
    port = 80
  }
  frontend_port {
    name = "port_443"
    port = 443
  }
  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet_app_gateway_2.id
  }
  http_listener {
    frontend_ip_configuration_name = "myAGIPConfig"
    frontend_port_name             = "port_443"
    name                           = "secure443"
    protocol                       = "Https"
    ssl_certificate_name           = "cert1"
    ssl_profile_name               = "ssl2"
  }
  identity {
    identity_ids = [azurerm_user_assigned_identity.user_identity.id]
    type         = "UserAssigned"
  }
  # private_link_configuration {
  #   name = "aglink"
  #   ip_configuration {
  #     name                          = "privateLinkIpConfig1"
  #     primary                       = false
  #     private_ip_address_allocation = "Dynamic"
  #     subnet_id                     = azurerm_subnet.subnet_app_gateway.id
  #   }
  # }
  request_routing_rule {
    backend_address_pool_name  = "myBackendPool"
    backend_http_settings_name = "myHTTPsetting"
    http_listener_name         = "secure443"
    name                       = local.ssl_profile_one
    priority                   = 8
    rewrite_rule_set_name      = "to80"
    rule_type                  = "Basic"
  }
  rewrite_rule_set {
    name = "to80"
    rewrite_rule {
      name          = "client_certificate_subject"
      rule_sequence = 100
      request_header_configuration {
        header_name  = "x-client-certificate-verification"
        header_value = "{var_client_certificate_verification}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-subject"
        header_value = "{var_client_certificate_subject}"
      }
    }
  }
  sku {
    capacity = 2
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  waf_configuration {
    enabled          = false
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"
    # file_upload_limit_mb = 100
    # max_request_body_size_kb = 128
    # request_body_check = true
  }


  // this is the listener hostname cert
  // this should match hostnames of:
  // - traffic manager profile name  .trafficmanager.net
  // - we can possibly rewrite hostname based upon what the backend desires.
  ssl_certificate {
    name     = "cert1" // TODO: make this a variable
    data     = filebase64("export1.pfx")
    password = "password"
  }

  // this is the ca public cert that clients are signed with - up to 5 chains supported.
  trusted_client_certificate {
    data = file("./certs/ca_pub.pem")
    name = local.trusted_client_certificate_chain_1
  }

  ssl_profile {
    name                             = local.ssl_profile_one
    trusted_client_certificate_names = [local.trusted_client_certificate_chain_1]
    verify_client_cert_issuer_dn     = true
  }


  depends_on = [
    azurerm_user_assigned_identity.user_identity,
    azurerm_public_ip.app_gateway_public_ip,
    azurerm_subnet.subnet_app_gateway_2,
    azurerm_subnet.subnet_app_gateway,
  ]
}
