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

output "vm_id" {
  value = azurerm_windows_virtual_machine.vm.id
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
