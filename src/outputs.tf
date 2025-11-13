output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "vm_address" {
  value = azurerm_public_ip.pip.fqdn
}

output "vm_id" {
  value = try(azurerm_virtual_machine.vm[0].id, azurerm_windows_virtual_machine.vm[0].id)
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "key_vault_secret_name" {
  value     = azurerm_key_vault_secret.vm_admin_password.name
  sensitive = false
}

output "avd_host_pool_id" {
  value = azurerm_virtual_desktop_host_pool.host_pool.id
}

output "avd_workspace_id" {
  value = azurerm_virtual_desktop_workspace.workspace.id
}

output "avd_application_group_id" {
  value = azurerm_virtual_desktop_application_group.app_group.id
}

output "connection_summary" {
  description = "Summarized AVD connection resources"
  value = {
    workspace_name         = azurerm_virtual_desktop_workspace.workspace.name
    workspace_id           = azurerm_virtual_desktop_workspace.workspace.id
    host_pool_name         = azurerm_virtual_desktop_host_pool.host_pool.name
    host_pool_id           = azurerm_virtual_desktop_host_pool.host_pool.id
    application_group_name = azurerm_virtual_desktop_application_group.app_group.name
    application_group_id   = azurerm_virtual_desktop_application_group.app_group.id
  }
}

output "auto_snapshot_info" {
  description = "Information about the most recent auto-created snapshot"
  value = var.auto_snapshot_on_destroy ? {
    enabled          = true
    snapshot_id      = try(azurerm_snapshot.pre_destroy_snapshot[0].id, null)
    snapshot_name    = try(azurerm_snapshot.pre_destroy_snapshot[0].name, null)
    snapshot_rg      = local.snapshot_rg
    created_at       = try(azurerm_snapshot.pre_destroy_snapshot[0].tags["created_at"], null)
    restore_command  = try("Update terraform.tfvars: existing_os_disk_id = \"${azurerm_snapshot.pre_destroy_snapshot[0].id}\"", "N/A")
    list_command     = "az snapshot list --resource-group ${local.snapshot_rg} --query \"[?tags.auto_snapshot=='true' && tags.environment=='${var.name_prefix}'].{name:name,created:tags.created_at}\" -o table"
  } : {
    enabled = false
  }
}
