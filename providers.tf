terraform {
  required_version = ">= 0.14.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.44.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
    teleport = {
      version = ">= 13.2.2"
      source  = "terraform.releases.teleport.dev/gravitational/teleport"
    }
  }
}
