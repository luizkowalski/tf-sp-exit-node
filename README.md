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

### 2. Tailscale ACL

The policy is defined in `acl.json` and **replaces your entire tailnet ACL on apply**. If you have existing rules:

1. Export your current policy from the [Tailscale admin console](https://login.tailscale.com/admin/acls/file) (top-right → **Download**).
2. Merge its contents into `acl.json`.
3. Make sure the following are present — they are required for the exit node to work:

```json
"tagOwners": {
  "tag:exit-node": []
},
"autoApprovers": {
  "exitNode": ["tag:exit-node"]
}
```

### 3. Tailscale OAuth client

Create an OAuth client once:

1. Open [Tailscale → Settings → OAuth clients](https://login.tailscale.com/admin/settings/oauth).
2. Click **Generate OAuth client**.
3. Grant the **Devices** (`write`) and **ACL** (`write`) scopes.
4. Copy the client ID and secret.

### 4. Variables

Create `terraform.tfvars`:

```hcl
tailscale_oauth_client_id     = "k..."
tailscale_oauth_client_secret = "tskey-client-..."
```

### 5. Deploy

```bash
terraform init
terraform apply
```

Confirm the plan, then type `yes`. Note the `public_ip` output when apply finishes.

## SSH into the instance

```bash
ssh -i aws-brasil-kp.pem ubuntu@$(terraform output -raw public_ip)
```

Use your actual `.pem` path if the key file is not in the project directory.

## What gets created

- VPC, public subnet, internet gateway, and routes in `sa-east-1`
- Ubuntu 24.04 EC2 instance with SSH (22) and Tailscale UDP (41641) allowed
- Tailscale auth key (pre-authorized, tagged `tag:exit-node`) generated at apply time
- Tailscale ACL replaced with the contents of `acl.json` (includes `tag:exit-node` owners and `autoApprovers`)
- Exit node route auto-approved — no manual approval step in the admin console
- Node key expiry disabled

After deploy, the instance should appear in the [Tailscale admin console](https://login.tailscale.com/admin/machines) as `brasil` with exit node active.
