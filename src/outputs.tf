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
  value = try(azurerm_public_ip.pip[0].ip_address,null)
}

output "vm_address" {
  value = try(azurerm_public_ip.pip[0].fqdn,null)
}

output "vm_id" {
  value = try(azurerm_windows_virtual_machine.vm[0].id,null)
}

output "key_vault_name" {
  value = try(azurerm_key_vault.kv[0].name,null)
}

output "key_vault_secret_name" {
  value     = try(azurerm_key_vault_secret.vm_admin_password[0].name,null)
  sensitive = false
}

output "avd_host_pool_id" {
  value = try(azurerm_virtual_desktop_host_pool.host_pool[0].id,null)
}

output "avd_workspace_id" {
  value = try(azurerm_virtual_desktop_workspace.workspace[0].id,null)
}

output "avd_application_group_id" {
  value = try(azurerm_virtual_desktop_application_group.app_group[0].id,null)
}

output "connection_summary" {
  description = "Summarized AVD connection resources"
  value = {
    workspace_name         = try(azurerm_virtual_desktop_workspace.workspace[0].name,null)
    workspace_id           = try(azurerm_virtual_desktop_workspace.workspace[0].id,null)
    host_pool_name         = try(azurerm_virtual_desktop_host_pool.host_pool[0].name,null)
    host_pool_id           = try(azurerm_virtual_desktop_host_pool.host_pool[0].id,null)
    application_group_name = try(azurerm_virtual_desktop_application_group.app_group[0].name,null)
    application_group_id   = try(azurerm_virtual_desktop_application_group.app_group[0].id,null)
  }
}

# New VM outputs (conditional on create_new_vm_from_snapshot)
output "new_vm_resource_group" {
  description = "Resource group of the new VM created from snapshot"
  value       = try(azurerm_resource_group.new_vm_rg[0].name, null)
}

output "new_vm_id" {
  description = "ID of the new VM created from snapshot"
  value       = try(azurerm_virtual_machine.new_vm[0].id, null)
}

output "new_vm_public_ip" {
  description = "Public IP address of the new VM"
  value       = try(azurerm_public_ip.new_vm_pip[0].ip_address, null)
}

output "new_vm_fqdn" {
  description = "FQDN of the new VM"
  value       = try(azurerm_public_ip.new_vm_pip[0].fqdn, null)
}

output "new_vm_summary" {
  description = "Summary of the new VM created from snapshot"
  value = var.create_new_vm_from_snapshot ? {
    name            = try(azurerm_virtual_machine.new_vm[0].name, null)
    resource_group  = try(azurerm_resource_group.new_vm_rg[0].name, null)
    location        = try(azurerm_resource_group.new_vm_rg[0].location, null)
    public_ip       = try(azurerm_public_ip.new_vm_pip[0].ip_address, null)
    fqdn            = try(azurerm_public_ip.new_vm_pip[0].fqdn, null)
    source_snapshot = var.existing_disk_snapshot_id
  } : null
}
