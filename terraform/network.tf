# ──────────────────────────────────────────────────────────────────────
# Virtual Network
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# ACA Environment Subnet (10.0.0.0/23)
# ──────────────────────────────────────────────────────────────────────
# ACA requires a minimum /23 subnet delegated to
# Microsoft.App/environments when using VNet integration.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_subnet" "aca" {
  name                 = "snet-aca-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aca_subnet_prefix]

  delegation {
    name = "aca-delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ──────────────────────────────────────────────────────────────────────
# Private Endpoints Subnet (10.0.2.0/24)
# ──────────────────────────────────────────────────────────────────────
# Hosts Private Endpoints for Azure SQL and Azure Cache for Redis.
# No delegation needed — PEs are standard NIC-based resources.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_subnet" "private_endpoints" {
  name                              = "snet-pe-${local.name_prefix}"
  resource_group_name               = azurerm_resource_group.main.name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [var.pe_subnet_prefix]
  private_endpoint_network_policies = "Enabled"
}

# ──────────────────────────────────────────────────────────────────────
# Network Security Groups
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_network_security_group" "aca" {
  name                = "nsg-aca-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-pe-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  # Deny all inbound from the internet — only VNet traffic allowed
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow inbound from ACA subnet to SQL (1433) and Redis (6380)
  security_rule {
    name                       = "AllowAcaToDataLayer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1433", "6380"]
    source_address_prefix      = var.aca_subnet_prefix
    destination_address_prefix = var.pe_subnet_prefix
  }
}

# ──────────────────────────────────────────────────────────────────────
# NSG ↔ Subnet Associations
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_subnet_network_security_group_association" "aca" {
  subnet_id                 = azurerm_subnet.aca.id
  network_security_group_id = azurerm_network_security_group.aca.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}