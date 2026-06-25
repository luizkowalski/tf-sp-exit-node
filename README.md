# terraform-sp

OCI instance in Oracle Cloud São Paulo (`sa-saopaulo-1`) with Tailscale (exit node, hostname `oraculo`).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- Oracle Cloud account with an API key configured
- A [Tailscale](https://tailscale.com) account on your tailnet

> No SSH key pair is required. The instance exposes no public SSH port — all
> access (SSH included) goes over Tailscale. A `proxy` user with passwordless
> sudo is provisioned via cloud-init for SSH login.

## Setup

### 1. OCI API key

Generate an API key and upload it to your OCI user profile:

1. Open [OCI Console → Profile → API Keys](https://cloud.oracle.com/identity/users) → **Add API Key**.
2. Download or generate the private key (`.pem`).
3. Save the key to `~/.oci/api.pem` (or any path you prefer).
4. Copy the fingerprint shown after upload.

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
tenancy_ocid        = "ocid1.tenancy.oc1...<your-tenancy-ocid>"
user_ocid           = "ocid1.user.oc1...<your-user-ocid>"
fingerprint         = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path    = "~/.oci/api.pem"
compartment_id      = "ocid1.tenancy.oc1...<same-as-tenancy-for-root>"
availability_domain = "Pdok:SA-SAOPAULO-1-AD-1"

tailscale_oauth_client_id     = "k..."
tailscale_oauth_client_secret = "tskey-client-..."

# Optionals (defaults shown)
region   = "sa-saopaulo-1"
hostname = "brasil"
```

| Variable | Description |
|---|---|
| `tenancy_ocid` | OCID of your OCI tenancy |
| `user_ocid` | OCID of your OCI user |
| `fingerprint` | Fingerprint of the uploaded API key |
| `private_key_path` | Path to the API private key `.pem` |
| `compartment_id` | Compartment OCID (tenancy OCID for root) |
| `availability_domain` | OCI availability domain name |
| `tailscale_oauth_client_id` | Tailscale OAuth client ID |
| `tailscale_oauth_client_secret` | Tailscale OAuth client secret |
| `region` | OCI region (default: `sa-saopaulo-1`) |
| `hostname` | Tailscale node hostname (default: `brasil`) |

### 5. Deploy

```bash
terraform init
terraform apply
```

Confirm the plan, then type `yes`.

## SSH into the instance

SSH goes through Tailscale — no key file, no public IP needed:

```bash
tailscale ssh proxy@oraculo
```

`proxy` is created by cloud-init with passwordless sudo. `root` also works
(`tailscale ssh root@oraculo`); both are permitted by the SSH rule in `acl.json`.

## What gets created

- VCN, public subnet, internet gateway, and route table in `sa-saopaulo-1`
- Ubuntu 24.04 OCI instance (`VM.Standard.E2.1.Micro`) — only Tailscale UDP (41641) is open inbound; no public SSH
- `proxy` user with passwordless sudo, provisioned via cloud-init for Tailscale SSH
- Tailscale auth key (pre-authorized, tagged `tag:exit-node`) generated at apply time
- Tailscale ACL replaced with the contents of `acl.json` (includes `tag:exit-node` owners and `autoApprovers`)
- Exit node route auto-approved — no manual approval step in the admin console
- Node key expiry disabled

After deploy, the instance should appear in the [Tailscale admin console](https://login.tailscale.com/admin/machines) as `oraculo` with exit node active.
