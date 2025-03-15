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
        name = "block everyone"
        priority = 101
        direction = "Inbound"
        access = "Deny"
        protocol = "Tcp"
        source_address_prefix = "*"
        destination_address_prefix = "*"
        source_port_range = "*"
        destination_port_range = "*"
    }
  
    security_rule {
        name                         = "private-db-4"
        priority                     = 102
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_address_prefixes      = [ "10.0.1.0/24" ]
        destination_address_prefixes = [ "10.0.2.0/24" ]
        source_port_range            = "8443-8443"
        destination_port_range       = "8443-8443"
    }
}

resource "azurerm_virtual_network" "vnet-dev-calicot-cc-4" {
    name                = "vnet-dev-calicot-cc-4"
    location            = azurerm_resource_group.rg-calicot-web-dev-4.location
    resource_group_name = azurerm_resource_group.rg-calicot-web-dev-4.name
    address_space       = [ "10.0.0.0/16" ]

    subnet {
        name = "snet-dev-web-cc-4"
        address_prefixes = [ "10.0.1.0/24" ]
    }

    subnet {
        name             = "snet-dev-db-cc-4"
        address_prefixes = [ "10.0.2.0/24" ]
        security_group   = "azurerm_network_security_group.netsg-dev-db-4"
    }
}