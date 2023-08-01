# InfoManiak Hosting Setup

Terraform module to create hosting setups for Connect-i projects in InfoManiak cloud.

## Requirements

| Name                                     | Version   |
| ---------------------------------------- | --------- |
| `terraform`                              | >= 1.0    |
| `terraform-provider-openstack/openstack` | ~> 1.44.0 |
| `hashicorp/template`                     | ~> 2.2.0  |

## Usage

Module creates and manages a minimal set of hosting resources:
* virtual machine instance
* security group (with port `22` open by default)
* block storage volumes (optional)

Every VM created by this module authorizes master SSH key for default SSH user and `root` (see `master_ssh_public_key` variable).

The module expects that the VM image used for instance creation has Docker Engine installed. By default, the module applies `cloud-init` configuration that automatically [exposes TLS-protected Docker API socket](https://docs.docker.com/engine/security/protect-access/#use-tls-https-to-protect-the-docker-daemon-socket) - this behavior is controlled by `expose_docker_tls_socket` variable.

Client certificates for accessing Docker socket can be found at `/root/.docker/` directory (`cert.pem`, `key.pem` and `ca.pem`). To use them for authentication with remote Docker Engine, define two variables:
* [`DOCKER_CERT_PATH`](https://docs.docker.com/compose/reference/envvars/#docker_cert_path) - directory where you store client certificates
* [`DOCKER_HOST`](https://docs.docker.com/compose/reference/envvars/#docker_host) - remote Docker Engine address (`tcp://SERVER_IP:2376`)

## Variables

| Variable                   | Description                                                  | Type           | Default                | Required |
| -------------------------- | ------------------------------------------------------------ | -------------- | ---------------------- | -------- |
| `name_prefix`              | Prefix to use while naming the resources                     | `string`       |                        | yes      |
| `network_name`             | Network to place the instance into                           | `string`       |                        | yes      |
| `ssh_key`                  | SSH key pair object to access the instance. Maps to [`openstack_compute_keypair_v2` resource](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_keypair_v2) | `object`       |                        | yes      |
| `ssh_key.name`             | SSH key pair name                                            | `string`       |                        | yes      |
| `ssh_key.private_key`      | Private key content                                          | `string`       |                        | yes      |
| `hostname`                 | Domain name or FQDN to refer to this instance by             | `string`       |                        | no       |
| `image_id`                 | Image ID to create an instance from                          | `string`       | `docker-baseline-v1.0` | no       |
| `flavor_name`              | Instance flavor (type) to use for instance creation. Defaults to the smallest one available | `string`       | `a1-ram2-disk20-perf1` | no       |
| `ssh_user`                 | SSH user to run launch commands as                           | `string`       | `debian`               | no       |
| `security_groups`          | Names of security groups to attach to the instance           | `list(string)` | `[]`                   | no       |
| `volumes`                  | Storage volumes to attach to this instance                   | `list(object)` | `[]`                   | no       |
| `expose_docker_tls_socket` | Generate certificates and allow TLS connections to Docker Engine on port 2376 | `bool`         | `true`                 | no       |
| `launch_commands`          | List of shell commands to run after the first boot. Executed by means of [Terraform provisioners](https://www.terraform.io/language/resources/provisioners/syntax) | `list(string)` | `[]`                   | no       |
| `master_ssh_public_key`    | Public key from master SSH key                               | `string`       |                        | yes      |
| `baseline_image_version`   | Version of baseline VM image to use for instance creation    | `string`       | `1.0`                  | no       |

## Outputs

| Output     | Description                                             | Type           |
| ---------- | ------------------------------------------------------- | -------------- |
| `instance` | Virtual machine created by the module                   | `object`       |
| `volumes`  | List of block storage volumes created for this instance | `list(object)` |

## Example

Minimal example - creates a VM with only SSH port connections allowed and Docker API configured (but closed by the security group) on port `2376`:

```hcl
module "test" {
  source                   = "./modules/hosting"
  name_prefix              = "test"
  flavor_name              = data.openstack_compute_flavor_v2.small.name
  network_name             = data.openstack_networking_network_v2.default.name
  ssh_key                  = openstack_compute_keypair_v2.my_key_pair
}
```

A more sophisticated example for a typical web project - same setup, but also HTTP/HTTPS traffic allowed and an extra volume is created:

```hcl
module "web" {
  source       = "./modules/hosting"
  name_prefix  = "web"
  hostname     = "www.project.com"
  flavor_name  = data.openstack_compute_flavor_v2.large.name
  network_name = data.openstack_networking_network_v2.default.name
  ssh_key      = openstack_compute_keypair_v2.my_key_pair

  security_groups = [
    openstack_compute_secgroup_v2.allow_http_https.name,
    openstack_compute_secgroup_v2.allow_ssh.name,
  ]

  volumes = [
    {
      size        = 100
      description = "Web data"
    },
  ]
}
```

> Note that the newly created 100 GB volume will be attached to the instance upon creation, but there won't be any partition or file system present. Either log in via SSH and perform the necessary operations manually, or rely on `launch_commands` variable to pass the commands to run on first boot. Any kind of automation for what's **inside** VMs is out of scope of Terraform - but there's always a handful of options like [Terraform provisioners](https://www.terraform.io/language/resources/provisioners/syntax), [Ansible](https://www.ansible.com), [Packer](https://www.packer.io) or `user_data` attribute since OpenStack images are compatible with [`cloud-init`](https://cloudinit.readthedocs.io/en/latest/).

## Links

* [Terraform Modules Documentation](https://www.terraform.io/docs/modules/index.html)
* [Terraform naming conventions](https://www.terraform-best-practices.com/naming)
