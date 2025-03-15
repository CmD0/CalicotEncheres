provider "azurerm" {

  features {}

}

resource "azurerm_resource_group" "rg-calicot-web-dev-4" {
  name     = "rg-calicot-web-dev-4"
  location = "Canada Central"
}

resource "azurerm_network_security_group" "netsg-dev-db-4" {
  name                = "netsg-dev-db-4"
  location            = azurerm_resource_group.rg-calicot-web-dev-4.location
  resource_group_name = azurerm_resource_group.rg-calicot-web-dev-4.name

  security_rule {
    name                       = "block everyone"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                         = "private-db-4"
    priority                     = 102
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_address_prefixes      = ["10.0.1.0/24"]
    destination_address_prefixes = ["10.0.2.0/24"]
    source_port_range            = "8443-8443"
    destination_port_range       = "8443-8443"
  }
}

resource "azurerm_virtual_network" "vnet-dev-calicot-cc-4" {
  name                = "vnet-dev-calicot-cc-4"
  location            = azurerm_resource_group.rg-calicot-web-dev-4.location
  resource_group_name = azurerm_resource_group.rg-calicot-web-dev-4.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name             = "snet-dev-web-cc-4"
    address_prefixes = ["10.0.1.0/24"]
  }

  subnet {
    name             = "snet-dev-db-cc-4"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = "azurerm_network_security_group.netsg-dev-db-4"
  }
}

resource "azurerm_app_service_plan" "plan-calicot-dev-4" {
  name                = "asp-calicot-dev-4"
  location            = azurerm_resource_group.rg-calicot-web-dev-4.location
  resource_group_name = azurerm_resource_group.rg-calicot-web-dev-4.name

  sku {
    tier = "Standard"
    size = "S1"
  }

  per_site_scaling = true
}

resource "azurerm_app_service" "app-calicot-dev-4" {
  name                = "app-calicot-dev-4"
  location            = azurerm_resource_group.rg-calicot-web-dev-4.location
  resource_group_name = azurerm_resource_group.rg-calicot-web-dev-4.name
  app_service_plan_id = azurerm_app_service_plan.plan-calicot-dev-4.id

  https_only = true

  site_config {
    always_on = true
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "ImageUrl" = "https://stcalicotprod000.blob.core.windows.net/images/"
  }
}

resource "azurerm_monitor_autoscale_setting" "app-calicot-dev-scaling-4" {
  name                = "app-calicot-dev-scaling-4"
  location            = azurerm_resource_group.rg-calicot-web-dev-4.location
  resource_group_name = azurerm_resource_group.rg-calicot-web-dev-4.name
  target_resource_id  = azurerm_app_service.app-calicot-dev-4.id

  profile {
    name = "defaultProfile"
    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_app_service.app-calicot-dev-4.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_app_service.app-calicot-dev-4.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 70
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
  predictive {
    scale_mode      = "Enabled"
    look_ahead_time = "PT5M"
  }
}

resource "azurerm_mssql_database" "sqldb-calicot-dev-4" {
  name         = "sqldb-calicot-dev-4"
  server_id    = azurerm_mssql_server.sqlsrv-calicot-dev-4.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"
  enclave_type = "VBS"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_server" "sqlsrv-calicot-dev-4" {
  name                         = "sqlsrv-calicot-dev-4"
  resource_group_name          = azurerm_resource_group.rg-calicot-web-dev-4.name
  location                     = azurerm_resource_group.rg-calicot-web-dev-4.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_key_vault" "kv-calicot-dev-4" {
  name                = "kv-calicot-dev-4"
  location            = azurerm_resource_group.rg-calicot-web-dev-4.location
  resource_group_name = azurerm_resource_group.rg-calicot-web-dev-4.name
  sku_name            = "standard"
  tenant_id           = "4dbda3f1-592e-4847-a01c-1671d0cc077f"

  access_policy {
    object_id = azurerm_app_service.app-calicot-dev-4.identity[0].principal_id

    key_permissions = [ "Get" ]
    secret_permissions = [ "Get" ]
  }
}
