variable "name_prefix" {
  type        = string
  description = "Prefix to use while naming the resources"
}

variable "hostname" {
  type        = string
  default     = null
  description = "Domain name or FQDN to refer to this instance by"
}

variable "ssh_key" {
  type = object({
    name        = string
    private_key = string
  })
  description = "SSH key pair object to access the instance"
}

variable "ssh_user" {
  type        = string
  default     = "ubuntu"
  description = "SSH user to run launch commands as"
}

variable "image_id" {
  type        = string
  default     = ""
  description = "Image ID to create an instance from"
}

variable "network_name" {
  type        = string
  description = "Network to place the instance into"
}

variable "security_groups" {
  type        = list(string)
  default     = []
  description = "Names of security groups to attach to the instance"
}

variable "flavor_name" {
  type        = string
  default     = "a1-ram2-disk20-perf1" # the smallest available
  description = "Instance flavor (type) to use for instance creation"
}

variable "volumes" {
  type = list(object({
    name        = optional(string)
    size        = number
    mount_point = string
    description = optional(string)
  }))
  default     = []
  description = "Storage volumes to attach to this instance"
}

variable "expose_docker_tls_socket" {
  type        = bool
  default     = true
  description = "Generate certificates and allow TLS connections to Docker Engine on port 2376"
}

variable "launch_commands" {
  type        = list(string)
  default     = []
  description = "List of shell commands to run after the first boot"
}

variable "master_ssh_public_key" {
  type        = string
  description = "Public key from master SSH key"
}

