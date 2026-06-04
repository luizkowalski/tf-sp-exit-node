variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = "aws-brasil-kp"
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key (ephemeral or reusable)"
  type        = string
  sensitive   = true
}
