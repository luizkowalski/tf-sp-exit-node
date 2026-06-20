provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
}

resource "tailscale_tailnet_key" "main" {
  depends_on    = [tailscale_acl.main]
  description   = "${var.hostname} exit node"
  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
  tags          = ["tag:exit-node"]
}

resource "time_sleep" "wait_for_device" {
  create_duration = "180s"

  triggers = {
    instance_id = oci_core_instance.server.id
  }
}

data "tailscale_device" "main" {
  depends_on = [time_sleep.wait_for_device]
  hostname   = var.hostname
}

resource "tailscale_device_key" "main" {
  device_id           = data.tailscale_device.main.id
  key_expiry_disabled = true
}

resource "tailscale_acl" "main" {
  overwrite_existing_content = true
  acl                        = file("${path.module}/acl.json")
}
