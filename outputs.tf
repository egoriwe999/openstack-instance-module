output "instance" {
  value       = openstack_compute_instance_v2.instance
  description = "Created instance"
}

output "volumes" {
  value       = openstack_blockstorage_volume_v3.data_volume[*]
  description = "List of volumes attached to the instance"
}
