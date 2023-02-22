locals {
  trusted_client_certificate_chain_1 = "ca2"
  trusted_client_certificate_chain_2 = "ca3"
  ssl_profile_name                   = "ssl2"
  request_routing_rule_name          = "sslrule"
  http_listener_name                 = "sslhttp"
  user_assigned_identity_name        = "usermsi1"
  app_gateway_name                   = "myAppGateway"
  backend_address_pool_name          = "myBackendPool"
  backend_http_settings_name         = "myHTTPsetting"
  frontend_ip_configuration_name     = "myFrontendIP"
  gateway_ip_configuration_name      = "myGatewayIP"
  frontend_port_name                 = "myFrontendPort"
  frontend_ssl_cert_name             = "cert1"
  rewrite_rule_set_name              = "to80"
}


# ------------------- Azure Application Gateway -------------------
resource "azurerm_user_assigned_identity" "user_identity" {
  location            = azurerm_resource_group.this_resource_group.location
  name                = local.user_assigned_identity_name
  resource_group_name = azurerm_resource_group.this_resource_group.name
  depends_on = [
    azurerm_resource_group.this_resource_group,
  ]
}

resource "azurerm_application_gateway" "app_gateway" {
  location            = azurerm_resource_group.this_resource_group.location
  name                = local.app_gateway_name
  resource_group_name = azurerm_resource_group.this_resource_group.name

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    affinity_cookie_name  = "ApplicationGatewayAffinity"
    cookie_based_affinity = "Disabled"
    name                  = local.backend_http_settings_name
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
  }

  frontend_ip_configuration {
    name = local.frontend_ip_configuration_name
    # private_link_configuration_name = "aglink" // DEBUG: removed
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = azurerm_subnet.subnet_app_gateway_2.id
  }

  http_listener {
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    name                           = local.http_listener_name
    protocol                       = "Https"
    ssl_certificate_name           = local.frontend_ssl_cert_name
    ssl_profile_name               = local.ssl_profile_name
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
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
    http_listener_name         = local.http_listener_name
    name                       = local.request_routing_rule_name
    priority                   = 8
    rewrite_rule_set_name      = local.rewrite_rule_set_name
    rule_type                  = "Basic"
  }

  // potential list of request headers to pass to backend pool
  // https://learn.microsoft.com/en-us/azure/application-gateway/rewrite-http-headers-url#server-variables
  // mTSL https://learn.microsoft.com/en-us/azure/application-gateway/rewrite-http-headers-url#mutual-authentication-server-variables
  rewrite_rule_set {
    name = local.rewrite_rule_set_name
    rewrite_rule {
      name          = "client_certificate_mtls"
      rule_sequence = 100
      request_header_configuration {
        header_name  = "x-client-certificate"
        header_value = "{var_client_certificate}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-end-date"
        header_value = "{var_client_certificate_end_date}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-fingerprint"
        header_value = "{var_client_certificate_fingerprint}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-issuer"
        header_value = "{var_client_certificate_issuer}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-serial"
        header_value = "{var_client_certificate_serial}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-start-date"
        header_value = "{var_client_certificate_start_date}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-subject"
        header_value = "{var_client_certificate_subject}"
      }
      request_header_configuration {
        header_name  = "x-client-certificate-verification"
        header_value = "{var_client_certificate_verification}"
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
    name     = local.frontend_ssl_cert_name
    data     = filebase64("./certs/export1.pfx")
    password = "password"
  }
  ssl_profile {
    name                             = local.ssl_profile_name
    trusted_client_certificate_names = [local.trusted_client_certificate_chain_1]
    verify_client_cert_issuer_dn     = true
  }
  // this is the ca public cert that clients are signed with
  trusted_client_certificate {
    data = file("./certs/ca_pub.pem")
    name = local.trusted_client_certificate_chain_1
  }

  depends_on = [
    azurerm_user_assigned_identity.user_identity,
    azurerm_public_ip.app_gateway_public_ip,
    azurerm_subnet.subnet_app_gateway_2,
    azurerm_subnet.subnet_app_gateway,
  ]
}
