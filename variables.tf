variable "resource_group_location" {
  default     = "southeastasia"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "rg-major-grub"
  description = "Resource group name."
}

variable "username" {
  default     = "azureuser"
  description = "The username for the local account that will be created on the new VM."
}

variable "source_ip" {
  default     = ""
  description = "The IP to access the new VM."
}