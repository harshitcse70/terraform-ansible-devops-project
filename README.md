# Multi-Environment Infrastructure with Terraform & Ansible

A production-grade DevOps project demonstrating Infrastructure as Code (IaC) and Configuration Management using Terraform and Ansible to provision and configure multi-environment AWS infrastructure.


---

## Introduction

This project demonstrates a **complete DevOps workflow** using:

* **Terraform** → Infrastructure provisioning
* **Ansible** → Configuration management
* **AWS** → Cloud platform

The goal of this project is to build a **multi-environment infrastructure (dev, staging, production)** and automate server configuration using industry best practices.

---

## Project Objectives

* Provision infrastructure using Terraform
* Implement **remote state management (S3 + DynamoDB)**
* Create **modular and reusable Terraform code**
* Configure servers using **Ansible roles**
* Automate deployment across multiple environments
* Implement **dynamic inventory integration**
* Follow **production-level DevOps practices**

## Project Diagram : 
![Project-design](https://github.com/user-attachments/assets/1e13c28d-ce3f-4bd1-bdb6-550dc12a9ce1)



---
---

##  Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cloud                              │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Development  │  │   Staging    │  │  Production  │       │
│  │ Environment  │  │ Environment  │  │ Environment  │       │
│  │              │  │              │  │              │       │
│  │ EC2: t2.micro│  │ EC2: t2.small│  │EC2: t2.medium│       │
│  │  + Docker    │  │  + Docker    │  │  + Docker    │       │
│  │  + Nginx     │  │  + Nginx     │  │  + Nginx     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │          State Management Infrastructure           │     │
│  │                                                    │     │
│  │  S3 Bucket: terraform-state-storage                │     │
│  │  DynamoDB: terraform-state-lock                    │     │
│  └────────────────────────────────────────────────────┘     │ 
└─────────────────────────────────────────────────────────────┘

                            ▼
                            
              Local Development Machine
                            
┌──────────────────┐              ┌──────────────────┐
│    Terraform     │──provisions──▶│    Ansible    │
│  (IaC Layer)     │              │ (Config Layer)   │
│                  │              │                  │
│ • Modules        │              │ • Roles          │
│ • Environments   │              │ • Playbooks      │
│ • Remote State   │              │ • Dynamic Inv.   │
└──────────────────┘              └──────────────────┘
```

### Infrastructure Flow

```
1. Bootstrap Phase
   └── Terraform creates S3 + DynamoDB
   
2. Provisioning Phase
   ├── Terraform initializes with remote backend
   ├── Creates EC2 instances per environment
   ├── Configures security groups
   ├── Generates SSH key pairs
   └── Outputs public IPs
   
3. Configuration Phase
   ├── Ansible retrieves IPs from Terraform outputs
   ├── Updates dynamic inventory files
   ├── Connects to instances via SSH
   ├── Applies Docker role (installs Docker, starts service)
   ├── Applies Nginx role (installs Nginx, deploys content)
   └── Verifies configuration
```

### Network Architecture

```
                    Internet Gateway
                           │
                           ▼
                    ┌──────────────┐
                    │  Public VPC   │
                    │  (Default VPC)│
                    └──────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
    ┌────────────┐ ┌────────────┐ ┌────────────┐
    │    Dev     │ │   Staging  │ │    Prod    │
    │  Security  │ │  Security  │ │  Security  │
    │   Group    │ │   Group    │ │   Group    │
    │            │ │            │ │            │
    │ SSH: 22    │ │ SSH: 22    │ │ SSH: 22    │
    │ HTTP: 80   │ │ HTTP: 80   │ │ HTTP: 80   │
    │ HTTPS: 443 │ │ HTTPS: 443 │ │ HTTPS: 443 │
    └────────────┘ └────────────┘ └────────────┘
```

---

## Project Structure

```
terraform-ansible-devops-project/
│
├── README.md                          # This file - Main project documentation
│
├── ansible/                           # Ansible configuration management
│   ├── README.md                      # Ansible-specific documentation
│   ├── ansible.cfg                    # Ansible configuration file
│   │
│   ├── inventories/                   # Environment-specific inventories
│   │   ├── dev/
│   │   │   └── hosts                  # Development inventory
│   │   ├── stg/
│   │   │   └── hosts                  # Staging inventory
│   │   └── prod/
│   │       └── hosts                  # Production inventory
│   │
│   ├── playbooks/                     # Ansible playbooks
│   │   └── site.yml                   # Main playbook for all environments
│   │
│   ├── roles/                         # Reusable Ansible roles
│   │   ├── docker/                    # Docker installation role
│   │   │   ├── README.md
│   │   │   ├── tasks/
│   │   │   ├── handlers/
│   │   │   ├── defaults/
│   │   │   ├── vars/
│   │   │   └── meta/
│   │   │
│   │   └── nginx/                     # Nginx installation role
│   │       ├── README.md
│   │       ├── tasks/
│   │       ├── handlers/
│   │       ├── files/
│   │       │   └── index.html         # Web content to deploy
│   │       ├── defaults/
│   │       ├── vars/
│   │       └── meta/
│   │
│   └── update_inventory.sh            # Dynamic inventory update script
│
├── terraform/                         # Terraform infrastructure code
│   ├── README.md                      # Terraform-specific documentation
│   │
│   ├── bootstrap/                     # Remote state infrastructure
│   │   ├── README.md                  # Bootstrap documentation
│   │   ├── main.tf                    # S3 and DynamoDB resources
│   │   ├── providers.tf               # AWS provider configuration
│   │   ├── variables.tf               # Bootstrap variables
│   │   ├── output.tf                  # Bootstrap outputs
│   │   └── terraform.tfstate          # Local state (bootstrap only)
│   │
│   ├── modules/                       # Reusable Terraform modules
│   │   └── ec2/                       # EC2 instance module
│   │       ├── README.md              # Module documentation
│   │       ├── main.tf                # EC2, SG, key pair resources
│   │       ├── variables.tf           # Module input variables
│   │       └── outputs.tf             # Module outputs
│   │
│   ├── environments/                  # Environment-specific configs (optional)
│   │   ├── dev/
│   │   ├── stg/
│   │   └── prod/
│   │
│   ├── backend.tf                     # Remote backend configuration
│   ├── main.tf                        # Main infrastructure definition
│   ├── providers.tf                   # Provider configuration
│   ├── outputs.tf                     # Output definitions
│
│   ├── init-backend.sh                # Backend initialization helper script
│   └── devops-key.pub                 # SSH public key
│
└── devops-key                         # SSH private key (gitignored)
```

### Directory Organization Philosophy

**Separation of Concerns**: Terraform handles infrastructure provisioning, Ansible handles configuration management. This separation allows:
- Independent updates to infrastructure or configuration
- Different team members to work on different layers
- Reuse of roles/modules across projects

**Environment Isolation**: Each environment (dev, staging, prod) is managed separately with:
- Dedicated inventory files in Ansible
- Environment-specific module calls in Terraform
- Different resource sizing and configurations

**Modular Design**: 
- Terraform modules enable resource reuse
- Ansible roles enable configuration reuse
- Both can be versioned and tested independently

---

## Prerequisites

### Required Software
* Terraform
* Ansible
* AWS (EC2, S3, DynamoDB)
* Bash scripting
* Linux (Ubuntu)


### AWS Requirements

1. **AWS Account**: Active AWS account with billing enabled
2. **IAM User**: User with programmatic access and following permissions:
   - EC2 Full Access
   - S3 Full Access
   - DynamoDB Full Access
   - IAM (for key pair creation)
3. **AWS Credentials**: Configured via `aws configure` or environment variables
4. **Region**: This project uses `eu-north-1` (Stockholm) by default

---
##  Getting Started

### Detailed Setup Guide

For comprehensive step-by-step instructions, see:
- [Terraform Setup Guide](terraform/README.md)
- [Ansible Configuration Guide](ansible/README.md)

---

## Project Workflow

### Complete Deployment Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Bootstrap Remote State Infrastructure               │
│                                                             │
│ • Create S3 bucket for state storage                        │
│ • Create DynamoDB table for state locking                   │
│ • Enable S3 versioning and encryption                       │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Initialize Terraform with Remote Backend            │
│                                                             │
│ • Configure S3 backend for state storage                    │
│ • Migrate local state to remote backend                     │
│ • Enable state locking via DynamoDB                         │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Provision Infrastructure                            │
│                                                             │
│ • Create EC2 instances (dev, staging, prod)                 │
│ • Configure security groups                                 │
│ • Create SSH key pairs                                      │
│ • Output public IPs                                         │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Update Ansible Inventory                            │
│                                                             │
│ • Extract Terraform outputs (public IPs)                    │
│ • Update inventory files for each environment               │
│ • Configure SSH connection parameters                       │
│                                                             │
│ Command: ./ansible/update_inventory.sh                      │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: Test Connectivity                                   │
│                                                             │
│ • Verify SSH connectivity to all instances                  │
│ • Confirm Ansible can reach all hosts                       │
│ • Validate SSH key authentication                           │
│                                                             │
│ Command: ansible all -m ping -i inventories/<env>/hosts     │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 6: Apply Configuration                                 │
│                                                             │
│ • Install Docker on all instances                           │
│ • Install and configure Nginx                               │
│ • Deploy web content                                        │
│ • Start services                                            │
│                                                             │
│Command: ansible-playbook -i inventories/<env>/hosts site.yml│
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 7: Verification                                        │
│                                                             │
│ • Access web interface via browser                          │
│ • Verify Docker is running: docker ps                       │
│ • Check Nginx status: systemctl status nginx                │
│ • Confirm services auto-start on reboot                     │
└─────────────────────────────────────────────────────────────┘
```

### Day 2 Operations

**Making Infrastructure Changes**:
1. Modify Terraform code
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes
4. Update Ansible inventory if IPs changed
5. Re-run Ansible playbooks if configuration needs updating

**Adding a New Environment**:
1. Add new module call in `terraform/main.tf`
2. Create new inventory directory in `ansible/inventories/`
3. Run `terraform apply` to provision resources
4. Update inventory script to include new environment
5. Run Ansible playbook for new environment

**Updating Configuration**:
1. Modify Ansible roles (tasks, variables, files)
2. Run playbook with `--check` flag (dry run)
3. Apply changes with `ansible-playbook`
4. Verify changes on instances

---

## Environment Promotion Strategy

```
Code → Dev Environment (test features)
         ↓
     Staging Environment (integration testing)
         ↓
     Production Environment (live)
```

**Promotion Process**:
1. Develop and test in dev environment
2. Merge code to staging branch
3. Deploy to staging environment
4. Run automated tests
5. Manual QA verification
6. If passed, merge to production branch
7. Deploy to production

---

##  Security Considerations

### SSH Key Management

- **Private Key**: `devops-key` - Should be kept secure, never committed to Git
- **Public Key**: `devops-key.pub` - Safe to store in version control
- **Key Permissions**: Private key should have 600 permissions (`chmod 600 devops-key`)
- **Key Rotation**: Regularly rotate SSH keys, update in Terraform and re-apply

### .gitignore Essentials

```
# Private keys
devops-key
*.pem

# Terraform
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars

# Ansible
*.retry

# AWS
.aws/

# Environment files
.env
```
##  Cleanup

### Destroying Infrastructure

**WARNING**: This will permanently delete all resources. Ensure you have:
- Backed up any important data
- Exported any needed configurations
- Notified team members

```bash
# Destroy main infrastructure
cd terraform
terraform destroy

# Confirm with 'yes' when prompted
# This will:
# - Terminate all EC2 instances
# - Delete security groups
# - Remove SSH key pairs

# Optionally destroy bootstrap infrastructure
cd bootstrap
terraform destroy

# This will:
# - Delete S3 bucket (only if empty)
# - Delete DynamoDB table
```

### Manual Cleanup (if Terraform fails)

If `terraform destroy` fails, manually delete via AWS Console:

1. **EC2 Console**:
   - Terminate all instances with tags matching your project
   - Delete associated security groups
   - Delete key pairs

2. **S3 Console**:
   - Empty S3 bucket first (delete all objects)
   - Delete the bucket

3. **DynamoDB Console**:
   - Delete the state lock table

