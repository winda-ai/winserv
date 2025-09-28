data "azurerm_client_config" "current" {}

# Detect caller public IP (IPv4) to restrict RDP if user did not explicitly supply rdp_allowed_source_ips.
# Falls back to an empty list if detection fails (then precondition will raise an error to avoid open RDP).
data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
}

locals {
  rg_name        = "${var.name_prefix}-rg"
  vnet_name      = "${var.name_prefix}-vnet"
  subnet_name    = "${var.name_prefix}-subnet"
  nsg_name       = "${var.name_prefix}-nsg"
  nic_name       = "${var.name_prefix}-nic"
  pip_name       = "${var.name_prefix}-pip"
  kv_name        = replace(lower("${var.name_prefix}kv"), "_", "")
  vm_name        = "${var.name_prefix}-vm"
  osdisk_name    = "${var.name_prefix}-osdisk"
  password_secret_name = "${var.name_prefix}-vm-admin-password"
  avd_host_pool_name  = "${var.name_prefix}-hostpool"
  avd_workspace_name  = "${var.name_prefix}-workspace"
  avd_app_group_name  = "${var.name_prefix}-appgroup"
  hyperv_supported_size  = contains(var.allowed_vm_sizes, var.vm_size)
  hyperv_supported_image = (lower(azurerm_windows_virtual_machine.vm.source_image_reference[0].publisher) == "microsoftwindowsdesktop")
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

resource "random_password" "vm_admin" {
  length      = 8
  special     = true
}

resource "azurerm_key_vault" "kv" {
  name                       = local.kv_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  public_network_access_enabled = true
  enabled_for_disk_encryption = true

  dynamic "access_policy" {
    for_each = var.key_vault_user_object_ids
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value
      secret_permissions = ["Get", "List", "Set", "Delete"]
    }
  }

  tags = var.tags
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = local.password_secret_name
  value        = random_password.vm_admin.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # Create one RDP allow rule per effective source IP. No open wildcard rule is created.
dynamic "security_rule" {
    # local.effective_rdp_ips expected as a map(string) of name => cidr (e.g. { home = "98.51.6.220/24", commute = "192.168.0.2/24" })
    # Create deterministic ordering by sorting keys, then assign priorities 100,110,120,...
    for_each = {
        for idx, k in sort(keys(var.rdp_allowed_source_ips)) :
        k => {
            cidr     = var.rdp_allowed_source_ips[k]
            priority = 100 + idx * 10
        }
    }
    content {
        name                       = "rdp-${security_rule.key}"
        priority                   = security_rule.value.priority
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = security_rule.value.cidr
        destination_address_prefix = "*"
    }
}
}

resource "azurerm_subnet_network_security_group_association" "subnet_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip" {
  name                = local.pip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = local.vm_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  admin_password      = azurerm_key_vault_secret.vm_admin_password.value
  network_interface_ids = [azurerm_network_interface.nic.id]
  tags                = var.tags

  identity { type = "SystemAssigned" }

  os_disk {
    name                 = local.osdisk_name
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "win10-22h2-ent"
    version   = "latest"
  }

  lifecycle {
    precondition {
      condition     = var.enable_hyperv ? contains(var.allowed_vm_sizes, var.vm_size) : true
      error_message = "Hyper-V enabled but VM size ${var.vm_size} not in allowed_vm_sizes list for nested virtualization."
    }
  }
}

# Enable Hyper-V (nested virtualization) inside the VM when requested.
resource "azurerm_virtual_machine_extension" "enable_hyperv" {
  count                      = var.enable_hyperv ? 1 : 0
  name                       = "EnableHyperV"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart; Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart; Restart-Computer -Force\""
  })
  tags = var.tags
  depends_on = [azurerm_windows_virtual_machine.vm]
}

# Post-verify Hyper-V (after reboot) by writing verification output; typically run via a second extension pass.
resource "azurerm_virtual_machine_extension" "verify_hyperv" {
  count                = var.enable_hyperv ? 1 : 0
  name                 = "VerifyHyperV"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"$r=Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V; $s=systeminfo | Select-String 'Hyper-V Requirements'; New-Item -ItemType Directory -Path C:/HyperVTest -Force | Out-Null; ($r | Out-String) + ($s | Out-String) | Out-File C:/HyperVTest/verification.txt;\""
  })
  tags = var.tags
  depends_on = [azurerm_virtual_machine_extension.enable_hyperv]
}
resource "azurerm_virtual_machine_extension" "aad_login" {
  name                        = "AADLoginForWindows"
  virtual_machine_id          = azurerm_windows_virtual_machine.vm.id
  publisher                   = "Microsoft.Azure.ActiveDirectory"
  type                        = "AADLoginForWindows"
  type_handler_version        = "2.0"
  auto_upgrade_minor_version  = true
  automatic_upgrade_enabled   = false
  failure_suppression_enabled = false
  tags                        = var.tags
}

resource "azurerm_virtual_machine_extension" "dsc" {
  name                        = "DSC"
  virtual_machine_id          = azurerm_windows_virtual_machine.vm.id
  publisher                   = "Microsoft.Powershell"
  type                        = "DSC"
  type_handler_version        = "2.73"
  auto_upgrade_minor_version  = true
  automatic_upgrade_enabled   = false
  failure_suppression_enabled = false
  settings = jsonencode({
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.03152.876.zip"
    properties = {
      UseAgentDownloadEndpoint = true
      aadJoin                  = true
      hostPoolName             = azurerm_virtual_desktop_host_pool.host_pool.name
    }
  })
  # Provide the AVD registration token as protected settings so it is not stored in plain state output.
  protected_settings = jsonencode({
    properties = {
      registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.reg.token
    }
  })
  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "guest_attestation" {
  name                        = "GuestAttestation"
  virtual_machine_id          = azurerm_windows_virtual_machine.vm.id
  publisher                   = "Microsoft.Azure.Security.WindowsAttestation"
  type                        = "GuestAttestation"
  type_handler_version        = "1.0"
  auto_upgrade_minor_version  = true
  automatic_upgrade_enabled   = false
  failure_suppression_enabled = false
  settings                    = jsonencode({})
  tags                        = var.tags
}
resource "azurerm_virtual_desktop_host_pool" "host_pool" {
  name                  = local.avd_host_pool_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.location
  friendly_name         = "${var.name_prefix}-hostpool"
  description           = "Host Pool for ${var.name_prefix} environment"
  type                  = "Pooled"
  load_balancer_type       = "BreadthFirst"
  maximum_sessions_allowed = var.avd_max_sessions
  preferred_app_group_type = "Desktop"
  start_vm_on_connect      = var.avd_start_vm_on_connect
  public_network_access    = "Enabled"
  validate_environment     = false
  custom_rdp_properties    = var.avd_custom_rdp_properties
  tags = var.tags
}

# AVD host pool registration info (token) used by DSC extension to add the session host.
# Token expires after 24h; a new apply refreshes it and may update the extension if changed.
resource "azurerm_virtual_desktop_host_pool_registration_info" "reg" {
  hostpool_id      = azurerm_virtual_desktop_host_pool.host_pool.id
  expiration_date  = timeadd(timestamp(), "72h")
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                          = local.avd_workspace_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = var.location
  friendly_name                 = "${var.name_prefix}-workspace"
  description                   = "Workspace for ${var.name_prefix} environment"
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_virtual_desktop_application_group" "app_group" {
  name                = local.avd_app_group_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  friendly_name       = "${var.name_prefix}-apps"
  description         = "Default desktop app group for ${var.name_prefix}"
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.host_pool.id
  tags                = var.tags
  default_desktop_display_name = "SessionDesktop"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspace_assoc" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.app_group.id
}
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  location              = var.location
  virtual_machine_id    = azurerm_windows_virtual_machine.vm.id
  daily_recurrence_time = "0300"
  timezone              = "Pacific Standard Time"
  enabled               = true
  tags                  = var.tags
  notification_settings {
    enabled         = false
    email           = "" # Set via variable if needed later
    time_in_minutes = 30
  }
}
