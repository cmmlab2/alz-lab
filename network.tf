locals {
  lab_location = "germanywestcentral" # ίδιο με το starter_locations στο tfvars
}

# ---------- HUB (Connectivity subscription) ----------
resource "azurerm_resource_group" "lab_hub" {
  provider = azurerm.connectivity
  name     = "rg-network-platform-001"
  location = local.lab_location
}

resource "azurerm_network_security_group" "lab_hub_shared" {
  provider            = azurerm.connectivity
  name                = "nsg-shared-platform-001"
  location            = local.lab_location
  resource_group_name = azurerm_resource_group.lab_hub.name
}

resource "azurerm_virtual_network" "lab_hub" {
  provider            = azurerm.connectivity
  name                = "vnet-hub-platform-001"
  location            = local.lab_location
  resource_group_name = azurerm_resource_group.lab_hub.name
  address_space       = ["172.16.0.0/24"]

  subnet {
    name             = "snet-shared-platform-001"
    address_prefixes = ["172.16.0.0/26"]
    security_group   = azurerm_network_security_group.lab_hub_shared.id
  }
}

# ---------- SPOKE (Corp subscription) ----------
resource "azurerm_resource_group" "lab_spoke" {
  provider = azurerm.corp
  name     = "rg-network-corp-001"
  location = local.lab_location
}

resource "azurerm_network_security_group" "lab_spoke_app" {
  provider            = azurerm.corp
  name                = "nsg-app-corp-001"
  location            = local.lab_location
  resource_group_name = azurerm_resource_group.lab_spoke.name
}

resource "azurerm_virtual_network" "lab_spoke" {
  provider            = azurerm.corp
  name                = "vnet-spoke-corp-001"
  location            = local.lab_location
  resource_group_name = azurerm_resource_group.lab_spoke.name
  address_space       = ["172.16.1.0/24"]

  subnet {
    name             = "snet-app-corp-001"
    address_prefixes = ["172.16.1.0/26"]
    security_group   = azurerm_network_security_group.lab_spoke_app.id
  }
}

# ---------- PEERING (Hub <-> Spoke) ----------
resource "azurerm_virtual_network_peering" "lab_hub_to_spoke" {
  provider                     = azurerm.connectivity
  name                         = "peer-hub-to-spoke-corp-001"
  resource_group_name          = azurerm_resource_group.lab_hub.name
  virtual_network_name         = azurerm_virtual_network.lab_hub.name
  remote_virtual_network_id    = azurerm_virtual_network.lab_spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "lab_spoke_to_hub" {
  provider                     = azurerm.corp
  name                         = "peer-spoke-corp-to-hub-001"
  resource_group_name          = azurerm_resource_group.lab_spoke.name
  virtual_network_name         = azurerm_virtual_network.lab_spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.lab_hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
