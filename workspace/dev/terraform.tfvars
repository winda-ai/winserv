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
