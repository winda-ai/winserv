location    = "eastus"
name_prefix = "winda-dev"
# Provide any additional AAD object IDs that should have Key Vault secret read access
additional_key_vault_user_object_ids = []
vm_size          = "Standard_D4ds_v4"
vm_admin_username = "winda-ai"
vnet_address_space = ["192.168.0.0/16"]
subnet_address_prefix = "192.168.0.0/24"
tags = {
	env     = "dev"
	project = "winda"
}
rdp_allowed_source_ips = ["174.166.27.0/32"]
