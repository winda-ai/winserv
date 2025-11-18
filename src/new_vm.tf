# New VM from snapshot in a dedicated resource group
# This creates a separate VM that doesn't interfere with the main VM resources

locals {
  new_vm_enabled     = var.create_new_vm_from_snapshot && var.existing_disk_snapshot_id != null
  new_vm_rg_name     = "${var.name_prefix}-${var.new_vm_name_suffix}-rg"
  new_vm_name        = "${var.name_prefix}-${var.new_vm_name_suffix}-vm"
  new_vm_nic_name    = "${var.name_prefix}-${var.new_vm_name_suffix}-nic"
  new_vm_pip_name    = "${var.name_prefix}-${var.new_vm_name_suffix}-pip"
  new_vm_osdisk_name = "${var.name_prefix}-${var.new_vm_name_suffix}-osdisk"
}

# Dedicated resource group for the new VM
resource "azurerm_resource_group" "new_vm_rg" {
  count    = local.new_vm_enabled ? 1 : 0
  name     = local.new_vm_rg_name
  location = var.location
  tags     = merge(var.tags, { purpose = "snapshot-restore-vm" })
}

# Data source to read the snapshot
data "azurerm_snapshot" "source_snapshot" {
  count               = local.new_vm_enabled && can(regex("/snapshots/", var.existing_disk_snapshot_id)) ? 1 : 0
  name                = split("/", var.existing_disk_snapshot_id)[8]
  resource_group_name = split("/", var.existing_disk_snapshot_id)[4]
}

# Create a new managed disk from the snapshot
resource "azurerm_managed_disk" "new_vm_disk" {
  count                = local.new_vm_enabled ? 1 : 0
  name                 = local.new_vm_osdisk_name
  location             = var.location
  resource_group_name  = azurerm_resource_group.new_vm_rg[0].name
  hyper_v_generation   = "V1"
  storage_account_type = "Premium_LRS"
  create_option        = "Copy"
  source_resource_id   = data.azurerm_snapshot.source_snapshot[0].id
  disk_size_gb         = data.azurerm_snapshot.source_snapshot[0].disk_size_gb
  os_type              = "Windows"
  tags                 = merge(var.tags, { source_snapshot = data.azurerm_snapshot.source_snapshot[0].name })
}

# Dedicated public IP for new VM
resource "azurerm_public_ip" "new_vm_pip" {
  count               = local.new_vm_enabled ? 1 : 0
  name                = local.new_vm_pip_name
  domain_name_label   = "${var.name_prefix}-${var.new_vm_name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.new_vm_rg[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Dedicated NIC for new VM (uses existing VNet/subnet)
resource "azurerm_network_interface" "new_vm_nic" {
  count               = local.new_vm_enabled ? 1 : 0
  name                = local.new_vm_nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.new_vm_rg[0].name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.new_vm_pip[0].id
  }
}

# New VM created from the snapshot disk (using azurerm_virtual_machine for attach mode)
resource "azurerm_virtual_machine" "new_vm" {
  count                 = local.new_vm_enabled ? 1 : 0
  name                  = local.new_vm_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.new_vm_rg[0].name
  vm_size               = var.vm_size
  network_interface_ids = [azurerm_network_interface.new_vm_nic[0].id]
  tags                  = merge(var.tags, { created_from = "snapshot" })

  delete_os_disk_on_termination = false # Preserve disk if VM is deleted

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name            = local.new_vm_osdisk_name
    caching         = "ReadWrite"
    create_option   = "Attach"
    managed_disk_id = azurerm_managed_disk.new_vm_disk[0].id
    os_type         = "Windows"
  }

  lifecycle {
    precondition {
      condition     = var.enable_hyperv ? contains(var.allowed_vm_sizes, var.vm_size) : true
      error_message = "Hyper-V enabled but VM size ${var.vm_size} not in allowed_vm_sizes list for nested virtualization."
    }
  }
}

# Auto-shutdown schedule for new VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "new_vm_shutdown" {
  count                 = local.new_vm_enabled ? 1 : 0
  location              = var.location
  virtual_machine_id    = azurerm_virtual_machine.new_vm[0].id
  daily_recurrence_time = "0300"
  timezone              = "Pacific Standard Time"
  enabled               = true
  tags                  = var.tags

  notification_settings {
    enabled         = false
    email           = ""
    time_in_minutes = 30
  }
}
