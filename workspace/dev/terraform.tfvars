location    = "eastus"
name_prefix = "winda-dev"
vm_size          = "Standard_D4ds_v4"
vm_admin_username = "winda-ai"
vnet_address_space = ["192.168.0.0/16"]
subnet_address_prefix = "192.168.0.0/24"
tags = {
	env     = "dev"
	project = "winda"
}
existing_disk_snapshot_id = "/subscriptions/35c779b2-b36f-40ca-9ee5-d434a15742ef/resourceGroups/winda-assets/providers/Microsoft.Compute/snapshots/winda-ai-vm-snapshot-20251112"
create_brand_new = false
create_new_vm_from_snapshot = true
new_vm_name_suffix = "restored"