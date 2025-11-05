variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Prefix to apply to all resource names"
  type        = string
}

variable "key_vault_user_object_ids" {
  description = "List of AAD object IDs (users or service principals) to grant access to Key Vault"
  type        = list(string)
  default = [
    "7c59b52f-71ae-4e34-a7a5-8a33257fe289", # Github User
    "012cd534-e958-4c26-9f4d-53f58473da6e", # Dhishan
    "c3939e37-088b-404c-8624-b8501ce43610"  # Atilla
  ]
}

variable "vm_size" {
  description = "Size of the Windows VM"
  type        = string
  default     = "Standard_D4ds_v4"
}

variable "vm_admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
  default     = "winda-ai"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["192.168.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for primary subnet"
  type        = string
  default     = "192.168.0.0/24"
}

variable "tags" {
  description = "Common tags applied to all taggable resources"
  type        = map(string)
  default     = {}
}

variable "rdp_allowed_source_ips" {
  description = "List of public IPv4 addresses (without CIDR) allowed inbound RDP (3389). Leave empty to block unless other rules exist."
  type        = map(string)
  default = {
    "home"    = "98.51.6.0/24"
    "commute" = "192.168.0.0/24"
    "Atilla"  = "174.166.27.0/24"
  }
}

variable "enable_hyperv" {
  description = "Enable Hyper-V (nested virtualization) inside the Windows VM"
  type        = bool
  default     = true
}

variable "allowed_vm_sizes" {
  description = "List of VM sizes permitted when Hyper-V is enabled (nested virtualization capable families). Use a subset to enforce standards."
  type        = list(string)
  default = [
    # Cheapest (generally): Standard_F4s_v2
    "Standard_F4s_v2",
    "Standard_D4s_v3",
    "Standard_D4ds_v4",
    "Standard_D4ds_v5",
    "Standard_E4s_v3",
    "Standard_F8s_v2",
    "Standard_D8s_v3",
    "Standard_D8ds_v4",
    "Standard_D8ds_v5",
    "Standard_E8s_v3"
  ]
}

variable "avd_max_sessions" {
  description = "Maximum sessions allowed per session host in the host pool"
  type        = number
  default     = 2
}

variable "avd_custom_rdp_properties" {
  description = "Custom RDP properties string for AVD host pool"
  type        = string
  default     = "drivestoredirect:s:*;redirectclipboard:i:1;redirectprinters:i:1;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;redirectwebauthn:i:1;use multimon:i:1;"
}

variable "avd_start_vm_on_connect" {
  description = "Whether to start session host VM on connect"
  type        = bool
  default     = true
}

variable "existing_os_disk_id" {
  description = "Resource ID of an Azure Image or Snapshot to restore the VM from (preserves installed apps and state). Provide the full resource ID of either: 1) an Azure Managed Image created from a VM, or 2) a Snapshot of an OS disk. Leave null to create a fresh VM from marketplace image."
  type        = string
  default     = null
}
