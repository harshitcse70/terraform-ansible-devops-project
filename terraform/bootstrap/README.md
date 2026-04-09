# Terraform Bootstrap Documentation

Detailed guide to setting up remote state infrastructure for Terraform.

---

##  Overview

The bootstrap process creates the foundational infrastructure needed for Terraform remote state management. This is a **one-time setup** that must be completed before using remote backends in  main Terraform configuration.

### The Chicken-and-Egg Problem

```
Problem:
  Terraform needs S3 backend to store state
     ↓
  But S3 doesn't exist yet
     ↓
  Can't create S3 with Terraform if Terraform needs S3 to work!

Solution:
  Bootstrap creates S3 and DynamoDB using LOCAL state
     ↓
  Main Terraform then uses these resources as REMOTE backend
```

---

##  What Bootstrap Creates

### 1. S3 Bucket

**Purpose**: Store Terraform state files for team collaboration

**Features Enabled**:
- **Versioning**: Keep history of state changes
- **Encryption**: AES256 server-side encryption
- **Public Access Block**: Prevent accidental exposure
- **Unique Naming**: Random suffix ensures global uniqueness

### 2. DynamoDB Table

**Purpose**: Provide state locking to prevent concurrent modifications

**Features**:
- **On-Demand Billing**: Pay only for what you use
- **LockID Key**: Required attribute for Terraform locking
- **No Cost When Idle**: Minimal cost for state locking operations

---

##  File Structure

```
bootstrap/
├── README.md                    # This file
├── main.tf                      # S3 and DynamoDB resources
├── providers.tf                 # AWS provider configuration
├── variables.tf                 # Input variables
├── output.tf                    # Bucket and table names
├── terraform.tfstate            # Local state file (critical!)
└── terraform.tfstate.backup     # State backup
```

---

---

##  Usage

### Step 1: Navigate to Bootstrap Directory

```bash
cd terraform/bootstrap
```

### Step 2: Initialize Terraform

```bash
terraform init
```

**Expected Output**:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding hashicorp/random versions matching "~> 3.0"...
- Installing hashicorp/aws v5.x.x...
- Installing hashicorp/random v3.x.x...

Terraform has been successfully initialized!
```

### Step 3: Review Plan

```bash
terraform plan
```

**Expected Output**:
```
Terraform will perform the following actions:

  # aws_dynamodb_table.terraform_locks will be created
  + resource "aws_dynamodb_table" "terraform_locks" {
      + name         = "terraform-locks-abc12345"
      + billing_mode = "PAY_PER_REQUEST"
      ...
    }

  # aws_s3_bucket.terraform_state will be created
  + resource "aws_s3_bucket" "terraform_state" {
      + bucket = "terraform-state-def67890"
      ...
    }

Plan: 7 to add, 0 to change, 0 to destroy.
```

### Step 4: Apply Configuration

```bash
terraform apply
```

**Prompts**:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

**Expected Output**:
```
aws_s3_bucket.terraform_state: Creating...
aws_dynamodb_table.terraform_locks: Creating...
aws_s3_bucket.terraform_state: Creation complete after 3s
aws_dynamodb_table.terraform_locks: Creation complete after 5s

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "terraform-state-abc12345"
dynamodb_table_name = "terraform-locks-def67890"
region = "eu-north-1"
backend_config = <<EOT
terraform init \
  -backend-config="bucket=terraform-state-abc12345" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=eu-north-1" \
  -backend-config="dynamodb_table=terraform-locks-def67890" \
  -backend-config="encrypt=true"
EOT
```

### Step 5: Save Outputs

```bash
# Save backend configuration
terraform output -raw backend_config > ../init-backend.sh
chmod +x ../init-backend.sh

# Save for reference
terraform output > bootstrap-outputs.txt
```

---

## Security Features

### S3 Bucket Security

**1. Encryption at Rest**:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**2. Public Access Block**:
```hcl
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  block_public_acls       = true  # Block public ACLs
  block_public_policy     = true  # Block public policies
  ignore_public_acls      = true  # Ignore existing public ACLs
  restrict_public_buckets = true  # Restrict public bucket access
}
```

**3. Versioning for Recovery**:
```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  versioning_configuration {
    status = "Enabled"
  }
}
```

### DynamoDB Security

**1. Point-in-Time Recovery**:
```hcl
resource "aws_dynamodb_table_point_in_time_recovery" "terraform_locks" {
  point_in_time_recovery {
    enabled = true
  }
}
```

**2. Prevent Deletion**:
```hcl
lifecycle {
  prevent_destroy = true
}
```


##  State Management

### Local State File

**Critical**: The bootstrap state is stored **locally** in `terraform.tfstate`.

```
bootstrap/terraform.tfstate  ← IMPORTANT FILE!
```

**Why Local State?**:
- Bootstrap creates the remote state infrastructure
- Can't use remote state before it exists
- This is the only place where local state is acceptable

**Backup Strategy**:
```bash
# Manual backup
cp terraform.tfstate terraform.tfstate.manual-backup

# Add to version control (carefully)
# Only if using private repository
git add terraform.tfstate
git commit -m "Backup bootstrap state"

# Cloud backup
aws s3 cp terraform.tfstate s3://your-backup-bucket/bootstrap-state/
```

**Recovery**:
```bash
# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Or restore from version control
git checkout terraform.tfstate

# Or restore from cloud
aws s3 cp s3://your-backup-bucket/bootstrap-state/terraform.tfstate .
```

---

## Updating Bootstrap

### Adding Resources

```bash
# Edit main.tf to add resources
vim main.tf

# Plan changes
terraform plan

# Apply changes
terraform apply
```



## Destroying Bootstrap (Cleanup)

### Pre-Destruction Checklist

Before destroying bootstrap resources:

1. **Destroy main infrastructure first**:
```bash
cd ../
terraform destroy
```

2. **Verify no resources depend on bootstrap**:
```bash
# Check for any remote state references
grep -r "terraform-state" .
```

3. **Backup state file**:
```bash
cd bootstrap
cp terraform.tfstate bootstrap-state-backup-$(date +%Y%m%d).tfstate
```

4. **Empty S3 bucket** (if versioning enabled):
```bash
# Get bucket name
BUCKET=$(terraform output -raw bucket_name)

# Delete all versions
aws s3api list-object-versions \
  --bucket $BUCKET \
  --output json \
  --query 'Versions[].{Key:Key,VersionId:VersionId}' \
  | jq -r '.[] | "--key \(.Key) --version-id \(.VersionId)"' \
  | xargs -I {} aws s3api delete-object --bucket $BUCKET {}

# Delete all delete markers
aws s3api list-object-versions \
  --bucket $BUCKET \
  --output json \
  --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \
  | jq -r '.[] | "--key \(.Key) --version-id \(.VersionId)"' \
  | xargs -I {} aws s3api delete-object --bucket $BUCKET {}
```

### Destruction Process

```bash
# Remove lifecycle protection
# Edit main.tf and comment out or remove:
# lifecycle {
#   prevent_destroy = true
# }

# Refresh state
terraform refresh

# Plan destruction
terraform plan -destroy

# Destroy resources
terraform destroy
```

**Expected Output**:
```
aws_s3_bucket_lifecycle_configuration.terraform_state: Destroying...
aws_s3_bucket_versioning.terraform_state: Destroying...
aws_s3_bucket_public_access_block.terraform_state: Destroying...
aws_s3_bucket_server_side_encryption_configuration.terraform_state: Destroying...
aws_dynamodb_table_point_in_time_recovery.terraform_locks: Destroying...
aws_s3_bucket.terraform_state: Destroying...
aws_dynamodb_table.terraform_locks: Destroying...

Destroy complete! Resources: 7 destroyed.
```

---
