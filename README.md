# terraform-sp

EC2 instance in AWS São Paulo (`sa-east-1`) with Tailscale (exit node, hostname `brasil`).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- AWS account with credentials configured (`aws configure`, or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)
- A [Tailscale](https://tailscale.com) account on your tailnet

> No AWS key pair is required. The instance exposes no public SSH port — all
> access (SSH included) goes over Tailscale. A `proxy` user with passwordless
> sudo is provisioned via cloud-init for SSH login.

## Setup

### 1. Tailscale ACL

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

### 2. Tailscale OAuth client

Create an OAuth client once:

1. Open [Tailscale → Settings → OAuth clients](https://login.tailscale.com/admin/settings/oauth).
2. Click **Generate OAuth client**.
3. Grant the **Devices** (`write`) and **ACL** (`write`) scopes.
4. Copy the client ID and secret.

### 3. Variables

Create `terraform.tfvars`:

```hcl
tailscale_oauth_client_id     = "k..."
tailscale_oauth_client_secret = "tskey-client-..."
region                        = "sa-east-1" # Default is already set to "sa-east-1"
```

### 4. Deploy

```bash
terraform init
terraform apply
```

Confirm the plan, then type `yes`

## SSH into the instance

SSH goes through Tailscale — no key file, no public IP needed:

```bash
tailscale ssh proxy@brasil
```

`proxy` is created by cloud-init with passwordless sudo. `root` also works
(`tailscale ssh root@brasil`); both are permitted by the SSH rule in `acl.json`.

## What gets created

- VPC, public subnet, internet gateway, and routes in `sa-east-1`
- Ubuntu 26.04 EC2 instance — only Tailscale UDP (41641) is open inbound; no public SSH
- `proxy` user with passwordless sudo, provisioned via cloud-init for Tailscale SSH
- Tailscale auth key (pre-authorized, tagged `tag:exit-node`) generated at apply time
- Tailscale ACL replaced with the contents of `acl.json` (includes `tag:exit-node` owners and `autoApprovers`)
- Exit node route auto-approved — no manual approval step in the admin console
- Node key expiry disabled

After deploy, the instance should appear in the [Tailscale admin console](https://login.tailscale.com/admin/machines) as `brasil` with exit node active.
