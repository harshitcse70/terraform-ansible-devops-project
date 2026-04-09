# EC2 Module Documentation

Reusable Terraform module for creating EC2 instances with security groups and SSH key pairs.

---

## Overview:
- EC2 instance with specified configuration
- Security group with configurable firewall rules
- SSH key pair for authentication
- Comprehensive tagging for organization

### Module Philosophy

**Reusability**: One module, multiple uses across environments
**Flexibility**: Parameterized for different configurations
**Best Practices**: Follows AWS and Terraform recommendations
**Simplicity**: Easy to understand and modify

---

##  Architecture

```
┌─────────────────────────────────────────┐
│          EC2 Module                     │
├─────────────────────────────────────────┤
│                                         │
│  ┌────────────────────────────────┐     │
│  │     EC2 Instance               │     │
│  │  • AMI                         │     │
│  │  • Instance Type               │     │
│  │  • Key Pair ──────────┐        │     │
│  │  • Security Group ─────┼───┐   │     │
│  │  • Tags                │   │   │     │
│  └────────────────────────┼───┼───┘     │
│                           │   │         │
│  ┌────────────────────────▼───┐         │
│  │     Security Group          │        │
│  │  • Ingress Rules:           │        │
│  │    - SSH (22)               │        │
│  │    - HTTP (80)              │        │
│  │    - HTTPS (443)            │        │
│  │  • Egress Rules:            │        │
│  │    - All outbound           │        │
│  └─────────────────────────────┘        │
│                                         │
│  ┌─────────────────────────────┐        │
│  │     SSH Key Pair            │        │
│  │  • Public Key Upload        │        │
│  │  • AWS Key Registration     │        │
│  └─────────────────────────────┘        │
│                                         │
└─────────────────────────────────────────┘
```

---

##  File Structure

```
modules/ec2/
├── README.md          # This file
├── main.tf           # Resource definitions
├── variables.tf      # Input variables
└── outputs.tf        # Output values
```

---
