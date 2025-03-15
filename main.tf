provider "azurerm" {

    features {}

}

resource "azurerm_resource_group" "rg-calicot-web-dev-4" {
    name     = "rg-calicot-web-dev-4"
    location = "Canada Central"
}

resource "azurerm_virtual_network" "vnet-dev-calicot-cc-4" {
    name                = "vnet-dev-calicot-cc-4"
    location            = "azurerm_resource_group.rg-calicot-web-dev-4.location"
    resource_group_name = "azurerm_resource_group.rg-calicot-web-dev-4.name"
    address_space       = [ "10.0.0.0/16" ]

    subnet {
        name = "snet-dev-web-cc-4"
        address_prefixes = [ "10.0.1.0/24" ]
    }

    subnet {
        name             = "snet-dev-db-cc-4"
        address_prefixes = [ "10.0.2.0/24" ]
        // TODO: add security group
    }
}