locals {
  cert_data = {
    domain       = coalesce(var.hostname, "$(cat /etc/hostname)") # use automatically generated one if none provided
    country      = "CH"
    state        = "unknown"
    locality     = "Zurich"
    organization = "Connect-i"
    email        = "devops@connect-i.ch"
    password     = "opigno"
  }
}
