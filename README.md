# terraform-sp

EC2 instance in AWS São Paulo (`sa-east-1`) with Tailscale (exit node, hostname `brasil`).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- AWS account with credentials configured (`aws configure`, or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)
- A [Tailscale](https://tailscale.com) account on your tailnet

## Setup

### 1. EC2 key pair (AWS Console)

1. Open **EC2** in region **South America (São Paulo) / sa-east-1**.
2. Go to **Key pairs** → **Create key pair**.
3. Name it (e.g. `aws-brasil-kp`), type **RSA**, format **`.pem`**, then create and download the file.
4. Move the file into this repo (or anywhere on your machine) and restrict permissions:

```bash
mv ~/Downloads/aws-brasil-kp.pem .
chmod 400 aws-brasil-kp.pem
```

The key pair **name** in AWS must match `key_name` in `variables.tf`. The **file** name is what you pass to `ssh -i`.

### 2. Tailscale auth key

1. Open [Tailscale → Settings → Keys](https://login.tailscale.com/admin/settings/keys).
2. Click **Generate auth key**.
3. Choose **Reusable** or **Ephemeral** (either works for a single server).
4. Copy the key (starts with `tskey-auth-`). You will paste it in the next step.

### 3. Variables

Create `terraform.tfvars` and add your Tailscale key:

```hcl
tailscale_auth_key = "tskey-auth-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### 4. Deploy

```bash
terraform init
terraform apply
```

Confirm the plan, then type `yes`. Note the `public_ip` output when apply finishes.

## SSH

```bash
ssh -i aws-brasil-kp.pem ubuntu@$(terraform output -raw public_ip)
```

Use your actual `.pem` path if the key file is not in the project directory.

## What gets created

- VPC, public subnet, internet gateway, and routes in `sa-east-1`
- Ubuntu 24.04 EC2 instance with SSH (22) and Tailscale UDP (41641) allowed
- On first boot: Tailscale install, join with your auth key, advertise as exit node

After deploy, the instance should appear in the [Tailscale admin console](https://login.tailscale.com/admin/machines) as `brasil`.
