provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
}

resource "tailscale_tailnet_key" "main" {
  depends_on    = [tailscale_acl.main]
  description   = "brasil exit node"
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = ["tag:exit-node"]
}

resource "time_sleep" "wait_for_device" {
  depends_on      = [aws_instance.server]
  create_duration = "60s"
}

data "tailscale_device" "main" {
  depends_on = [time_sleep.wait_for_device]
  hostname   = "brasil"
}

resource "tailscale_device_key" "main" {
  device_id           = data.tailscale_device.main.id
  key_expiry_disabled = true
}

resource "tailscale_acl" "main" {
  overwrite_existing_content = true
  acl                        = file("${path.module}/acl.json")
}
