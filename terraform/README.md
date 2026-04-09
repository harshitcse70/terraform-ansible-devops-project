#  Terraform Infrastructure Documentation

Comprehensive guide to the Terraform infrastructure provisioning setup for multi-environment AWS deployment.

---


## Overview

This Terraform configuration provisions a multi-environment AWS infrastructure consisting of:

- **3 EC2 Instances**: Development, Staging, and Production environments
- **Security Groups**: Environment-specific firewall rules
- **SSH Key Pairs**: Secure authentication for instance access
- **Remote State Infrastructure**: S3 bucket and DynamoDB table for team collaboration

---

##  Architecture

### Infrastructure Components

```
┌───────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                     │
│                                                           │
│  ┌────────────────────────────────────────────────────┐   │
│  │        State Management (Bootstrap)                │   │
│  │                                                    │   │
│  │  ┌────────────┐           ┌─────────────┐          │   │
│  │  │ S3 Bucket  │           │  DynamoDB   │          │   │
│  │  │            │           │   Table     │          │   │
│  │  │ • Versioned│           │ • Lock      │          │   │
│  │  │ • Encrypted│           │ • Prevent   │          │   │
│  │  │ • tfstate  │           │   Conflicts │          │   │
│  │  └────────────┘           └─────────────┘          │   │
│  └────────────────────────────────────────────────────┘   │
│                                                           │
│  ┌──────────────────────────────────────────────────── ┐  │
│  │         Application Infrastructure (Main)           │  │
│  │                                                     │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐   │  │
│  │  │     Dev      │  │   Staging    │  │   Prod   │   │  
│  │  │              │  │              │  │          │   │
│  │  │ EC2          │  │ EC2          │  │ EC2      │   │
│  │  │ t2.micro     │  │ t2.small     │  │ t2.medium│   │
│  │  │              │  │              │  │          │   │
│  │  │ SG: dev-sg   │  │ SG: stg-sg   │  │ SG: prod │   │
│  │  │ Key: dev-key │  │ Key: stg-key │  │ Key: prod│   │
│  │  └──────────────┘  └──────────────┘  └──────────┘   │
│  └──────────────────────────────────────────────────── ┘  │
└───────────────────────────────────────────────────────────┘
```

### Resource Dependencies

```
S3 Bucket (bootstrap)
    ↓
DynamoDB Table (bootstrap)
    ↓
Backend Configuration (main terraform)
    ↓
┌─────────────────────────────────────────┐
│         EC2 Module Instances            │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Development Environment         │    │
│  │  • EC2 Instance                 │    │
│  │  • Security Group               │    │
│  │  • Key Pair                     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Staging Environment             │    │
│  │  • EC2 Instance                 │    │
│  │  • Security Group               │    │
│  │  • Key Pair                     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Production Environment           │   │
│  │  • EC2 Instance                  │   │
│  │  • Security Group                │   │
│  │  • Key Pair                      │   │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

---

##  Directory Structure

```
terraform/
├── README.md                    # This file
│
├── bootstrap/                   # Remote state infrastructure
│   ├── README.md               # Bootstrap documentation
│   ├── main.tf                 # S3 and DynamoDB resources
│   ├── providers.tf            # AWS provider for bootstrap
│   ├── variables.tf            # Bootstrap input variables
│   ├── output.tf               # Bucket and table names
│   ├── terraform.tfstate       # Local state (bootstrap only)
│   └── terraform.tfstate.backup # State backup
│
├── modules/                     # Reusable Terraform modules
│   └── ec2/                    # EC2 instance module
│       ├── README.md           # Module documentation
│       ├── main.tf             # EC2, SG, key pair resources
│       ├── variables.tf        # Module input variables
│       └── outputs.tf          # Module outputs (IP, ID, etc.)
│
├── environments/                # Environment-specific configs (optional)
│   ├── dev/                    # Development overrides
│   ├── stg/                    # Staging overrides
│   └── prod/                   # Production overrides
│
├── backend.tf                   # Remote backend configuration
├── main.tf                      # Main infrastructure definition
├── providers.tf                 # AWS provider configuration
├── outputs.tf                   # Root module outputs
├── variables.tf                 # Root module variables (if any)
├── terraform.tfvars            # Variable values (gitignored)
├── init-backend.sh             # Backend initialization script
└── devops-key.pub              # SSH public key
```

## Bootstrap Process

### Why Bootstrap?

**The Chicken-and-Egg Problem**:
- Terraform needs an S3 backend to store state
- But S3 doesn't exist until Terraform creates it
- Can't use S3 backend in the same config that creates S3

**Solution**: Bootstrap infrastructure is managed separately with **local state**.

### Bootstrap Architecture

```
┌─────────────────────────────────────────┐
│      Bootstrap (Local State)            │
│                                         │
│  terraform/bootstrap/                   │
│                                         │
│  Creates:                               │
│  ┌────────────────────────────────┐     │
│  │ S3 Bucket                      │     │
│  │ • Name: terraform-state-*      │     │
│  │ • Versioning: Enabled          │     │
│  │ • Encryption: AES256           │     │
│  │ • Public Access: Blocked       │     │
│  └────────────────────────────────┘     │
│                                         │
│  ┌────────────────────────────────┐     │
│  │ DynamoDB Table                 │     │
│  │ • Name: terraform-lock-*       │     │
│  │ • Key: LockID (String)         │     │
│  │ • Billing: On-Demand           │     │
│  └────────────────────────────────┘     │
│                                         │
│  State: terraform.tfstate (local)       │
└─────────────────────────────────────────┘
                    ↓
          Used by main terraform
```

### Bootstrap Workflow

```bash
# 1. Navigate to bootstrap directory
cd terraform/bootstrap

# 2. Initialize Terraform (downloads AWS provider)
terraform init

# 3. Review what will be created
terraform plan

# 4. Create S3 bucket and DynamoDB table
terraform apply

# 5. Note the outputs (bucket name and table name)
terraform output
# bucket_name = "terraform-state-abc123def"
# dynamodb_table_name = "terraform-locks-xyz789"

# 6. Use these values for main terraform backend configuration
```

**Important Notes**:
- Bootstrap state is stored locally (`terraform.tfstate`)
- This is the only place where local state is acceptable
- Keep `bootstrap/terraform.tfstate` safe - it's needed to destroy resources later
- Bootstrap is run only once per AWS account/project

---

##  Remote Backend Configuration

### Backend Configuration File

**File**: `terraform/backend.tf`

```hcl
terraform {
  backend "s3" {
    # Configuration provided during init
  }
}
```

**Why Empty Block?**:
- Configuration provided via `-backend-config` during `terraform init`
- Allows flexible configuration without hardcoding values
- Supports different backends per environment (if needed)

### Backend Initialization

**Manual Method**:

```bash
terraform init \
  -backend-config="bucket=terraform-state-abc123def" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=eu-north-1" \
  -backend-config="dynamodb_table=terraform-locks-xyz789" \
  -backend-config="encrypt=true"
```

**Script Method** (`init-backend.sh`):


**Usage**:Refer to source code [code](init-backend.sh)


### State Migration

When initializing backend for the first time:

```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes
```

**Answer**: `yes` - This migrates any existing local state to S3.



## Modules

### EC2 Module Structure

**Location**: `terraform/modules/ec2/`

```
modules/ec2/
├── README.md          # Module documentation
├── main.tf           # Resource definitions
├── variables.tf      # Input variables
└── outputs.tf        # Output values
```

**Outputs Usage**:
- Used by Ansible for dynamic inventory
- Used by other Terraform modules for cross-references
- Displayed to user after `terraform apply`

---


---

##  Workflow

### Complete Terraform Workflow

```
┌─────────────────────────────────────────────────────────┐
│ 1. Bootstrap Phase (One-time)                           │
│                                                          │
│ cd terraform/bootstrap                                  │
│ terraform init                                          │
│ terraform apply                                         │
│ # Note bucket and table names                           │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Backend Initialization                                │
│                                                          │
│ cd ../                                                   │
│ terraform init -backend-config=...                      │
│ # Or use init-backend.sh script                         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Plan Infrastructure                                   │
│                                                          │
│ terraform plan                                          │
│ # Review planned changes                                │
│ # Ensure no unexpected changes                          │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 4. Apply Infrastructure                                  │
│                                                          │
│ terraform apply                                         │
│ # Type 'yes' to confirm                                 │
│ # Wait for completion (~3-5 minutes)                    │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 5. Verify Outputs                                        │
│                                                          │
│ terraform output                                        │
│ # Verify all IPs are displayed                          │
│ # Test SSH connectivity                                 │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 6. Update Ansible Inventory                              │
│                                                          │
│ cd ../ansible                                           │
│ ./update_inventory.sh                                   │
│ # Proceed to Ansible configuration                      │
└─────────────────────────────────────────────────────────┘
```

### Making Changes

```
┌─────────────────────────────────────────────────────────┐
│ 1. Modify Terraform Code                                 │
│                                                          │
│ vim terraform/main.tf                                   │
│ # Change instance type, add resources, etc.             │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Format Code                                           │
│                                                          │
│ terraform fmt -recursive                                │
│ # Ensures consistent formatting                         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Validate Syntax                                       │
│                                                          │
│ terraform validate                                      │
│ # Checks for syntax errors                              │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 4. Plan Changes                                          │
│                                                          │
│ terraform plan -out=tfplan                              │
│ # Review what will change                               │
│ # Save plan to file for safety                          │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 5. Apply Saved Plan                                      │
│                                                          │
│ terraform apply tfplan                                  │
│ # No confirmation needed (already saved)                │
└─────────────────────────────────────────────────────────┘
```

### Destroying Infrastructure

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Destroy specific resource
terraform destroy -target=module.dev

# Destroy with auto-approve (dangerous!)
terraform destroy -auto-approve
```

---

##  Best Practices

### Code Organization

```hcl
# main.tf - Main infrastructure
# providers.tf - Provider configuration
# backend.tf - Backend configuration
# variables.tf - Input variables
# outputs.tf - Output values
# versions.tf - Terraform and provider versions
```


