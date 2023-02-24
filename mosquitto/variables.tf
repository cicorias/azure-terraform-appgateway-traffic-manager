variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the resources."
  default     = "scicoria-mosquitto"
}

variable "resource_group_location" {
  type        = string
  description = "The location of the resource group in which to create the resources."
  default     = "eastus"
}

# variable "vm_pool_instance_count" {
#   type        = number
#   description = "The number of VMs to create in the VM pool."
#   default     = 1
# }
