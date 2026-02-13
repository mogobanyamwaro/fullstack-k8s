# Terraform – EC2 Infrastructure

Provisions a standard AWS infra: VPC, Internet Gateway, public subnets, security group, and 3 EC2 instances. No configuration is applied to instances (provision only).

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- AWS credentials (Access Key ID and Secret Access Key)
- An existing EC2 key pair in your region (for SSH)

## How to Run

1. **Copy and edit variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with:
   - `aws_access_key_id` – your AWS access key
   - `aws_secret_access_key` – your AWS secret key
   - `key_name` – name of an existing EC2 key pair
   - `availability_zones` – optional, defaults to `us-east-1a`, `us-east-1b`, `us-east-1c`

3. **Apply:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

4. **Destroy** (when done):
   ```bash
   terraform destroy
   ```

`terraform.tfvars` is gitignored. Put your access key and secret key there – they are marked `sensitive` and won’t appear in plan/apply output.

See `terraform.tfvars.example` for the full template. Required: `aws_access_key_id`, `aws_secret_access_key`, `key_name`.

## What Gets Created

| Resource | Description |
|----------|-------------|
| VPC | 10.0.0.0/16 with DNS support |
| Internet Gateway | Attached to VPC |
| Public Subnets | One per AZ, auto-assign public IP |
| Route Table | Routes 0.0.0.0/0 to IGW |
| Security Group | SSH (22), HTTP (80), HTTPS (443), all egress |
| EC2 Instances | 3 × t3.micro (Ubuntu 22.04), spread across subnets |

## Outputs

- `vpc_id` – VPC ID  
- `instance_ids` – EC2 instance IDs  
- `instance_public_ips` – Public IPs  
- `instance_private_ips` – Private IPs  

## Security Note

By default, SSH is open to `0.0.0.0/0`. Restrict `ssh_cidr` in `terraform.tfvars` to your IP in production.
