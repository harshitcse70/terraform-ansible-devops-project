# Ansible Configuration Management Documentation

Comprehensive guide to the Ansible configuration management setup for automated server provisioning across multi-environment infrastructure.

---


##  Overview

This Ansible configuration automates the setup and configuration of EC2 instances provisioned by Terraform. It implements a role-based architecture that installs and configures Docker and Nginx across development, staging, and production environments.

### What This Ansible Setup Does

1. **Connects** to EC2 instances using SSH with dynamic inventory
2. **Installs** Docker for containerized application deployment
3. **Configures** Nginx as a web server with custom content
4. **Ensures** services are enabled and running
5. **Maintains** idempotent configuration (safe to run multiple times)

### Why Ansible?

- **Agentless**: No need to install agents on target servers
- **Idempotent**: Safe to run multiple times without side effects
- **Declarative**: Describe desired state, Ansible makes it happen
- **SSH-Based**: Uses standard SSH for secure communication
- **YAML Syntax**: Easy to read and write configurations
- **Extensive Modules**: Pre-built modules for common tasks

---

## Architecture

### Configuration Management Flow

```
┌─────────────────────────────────────────────────────────────┐
│              Control Node (Your Machine)                    │
│                                                             │
│  ┌───────────────────────────────────────────────────  ┐    │
│  │              Ansible Engine                         │    │
│  │                                                     │    │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────┐    │    │
│  │  │  Playbooks  │→ │  Inventory   │→ │  Roles   │    │    │
│  │  └─────────────┘  └──────────────┘  └──────────┘    │    │
│  │                                                     │    │
│  │  ansible-playbook -i inventories/dev/hosts site.yml │    │
│  └──────────────────────────────────────────────────── ┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ SSH (Port 22)
                            ↓
┌───────────────────────────────────────────────────────── ─┐
│                    Managed Nodes (EC2)                    │
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │     Dev      │  │   Staging    │  │     Prod     │     │
│  │              │  │              │  │              │     │
│  │ Before:      │  │ Before:      │  │ Before:      │     │
│  │ • Plain OS   │  │ • Plain OS   │  │ • Plain OS   │     │
│  │              │  │              │  │              │     │
│  │ After:       │  │ After:       │  │ After:       │     │
│  │ • Docker     │  │ • Docker     │  │ • Docker     │     │
│  │ • Nginx      │  │ • Nginx      │  │ • Nginx      │     │
│  │ • Web Content│  │ • Web Content│  │ • Web Content│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└───────────────────────────────────────────────────────────┘
```

### Role Execution Flow

```
Playbook (site.yml)
    ↓
Apply to all hosts
    ↓
┌───────────────────────────────────────┐
│         Docker Role                    │
├───────────────────────────────────────┤
│ 1. Update apt cache                   │
│ 2. Install prerequisites              │
│ 3. Add Docker GPG key                 │
│ 4. Add Docker repository              │
│ 5. Install Docker                     │
│ 6. Start Docker service               │
│ 7. Enable Docker on boot              │
│ 8. Add user to docker group           │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│         Nginx Role                     │
├───────────────────────────────────────┤
│ 1. Install Nginx                      │
│ 2. Copy custom index.html             │
│ 3. Start Nginx service                │
│ 4. Enable Nginx on boot               │
└───────────────────────────────────────┘
    ↓
Configuration Complete
```

---

##  Directory Structure

```
ansible/
├── README.md                    # This file
│
├── ansible.cfg                  # Ansible configuration
│
├── inventories/                 # Environment-specific hosts
│   ├── dev/
│   │   └── hosts               # Development inventory
│   ├── stg/
│   │   └── hosts               # Staging inventory
│   └── prod/
│       └── hosts               # Production inventory
│
├── playbooks/                   # Ansible playbooks
│   └── site.yml                # Main playbook for configuration
│
├── roles/                       # Reusable Ansible roles
│   ├── docker/                 # Docker installation role
│   │   ├── README.md
│   │   ├── tasks/
│   │   │   └── main.yml       # Docker installation tasks
│   │   ├── handlers/
│   │   │   └── main.yml       # Service restart handlers
│   │   ├── defaults/
│   │   │   └── main.yml       # Default variables
│   │   ├── vars/
│   │   │   └── main.yml       # Role-specific variables
│   │   ├── meta/
│   │   │   └── main.yml       # Role metadata
│   │   ├── files/             # Static files
│   │   └── templates/         # Jinja2 templates
│   │
│   └── nginx/                  # Nginx installation role
│       ├── README.md
│       ├── tasks/
│       │   └── main.yml       # Nginx installation tasks
│       ├── handlers/
│       │   └── main.yml       # Service restart handlers
│       ├── files/
│       │   └── index.html     # Custom web content
│       ├── defaults/
│       │   └── main.yml       # Default variables
│       ├── vars/
│       │   └── main.yml       # Role-specific variables
│       ├── meta/
│       │   └── main.yml       # Role metadata
│       └── templates/         # Jinja2 templates
│
└── update_inventory.sh          # Dynamic inventory updater
```

---

##  Core Concepts

### 1. Idempotency

**Definition**: Running the same playbook multiple times produces the same result without unintended side effects.

**Example**:
```yaml
# This task is idempotent
- name: Install Nginx
  apt:
    name: nginx
    state: present
```

**Why It Matters**:
- Safe to run repeatedly
- No configuration drift
- Predictable outcomes
- Easy rollback and recovery

### 2. Declarative Configuration

**Declarative** (Ansible):
```yaml
- name: Ensure Nginx is running
  service:
    name: nginx
    state: started
    enabled: yes
```

**Imperative** (Bash):
```bash
systemctl start nginx
systemctl enable nginx
```

**Ansible Approach**:
- Define desired state ("running")
- Ansible determines actions needed
- Only makes changes if necessary


### 3. Roles

**Roles** organize playbooks into reusable components:

```
Role Structure:
roles/
└── docker/
    ├── tasks/        # What to do
    ├── handlers/     # Event-driven actions
    ├── defaults/     # Default variables
    ├── vars/         # Role variables
    ├── files/        # Static files
    ├── templates/    # Jinja2 templates
    └── meta/         # Role dependencies
```

**Benefits**:
- Reusability across projects
- Clear organization
- Independent testing
- Version control
- Sharing via Ansible Galaxy

### 4. Handlers

**Handlers** are tasks triggered by notifications:

```yaml
# Task that notifies handler
- name: Update Nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: restart nginx

# Handler (only runs if notified)
handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```

**Handler Characteristics**:
- Run only once per playbook
- Run at the end of play
- Only run if notified
- Prevent unnecessary service restarts



---

---

##  Playbooks

### Main Playbook

**File**: `playbooks/site.yml`

---

##  Roles

### Docker Role

**Purpose**: Install and configure Docker on target hosts

**Location**: `roles/docker/`

**Tasks** (`tasks/main.yml`):

```
```

### Nginx Role

**Purpose**: Install and configure Nginx web server

**Location**: `roles/nginx/`

**Tasks** (`tasks/main.yml`):

```
```


##  Dynamic Inventory Integration

### Update Inventory Script

**File**: `update_inventory.sh`
**Usage**:
```bash
chmod +x update_inventory.sh
./update_inventory.sh
```

### Why Dynamic Inventory?

**Benefits**:
1. **Automation**: No manual IP updates
2. **Accuracy**: Always uses current infrastructure state
3. **Integration**: Seamless Terraform → Ansible workflow
4. **Efficiency**: Reduces human error
5. **Scalability**: Easy to extend for more environments

**How It Works**:
```
Terraform → Creates EC2 → Outputs IPs → Script reads outputs → Updates inventory → Ansible uses inventory
```

---

##  Workflow

### Complete Ansible Workflow

```
┌─────────────────────────────────────────────────────────┐
│ 1. Update Inventory (After Terraform Apply)             │
│                                                         │
│ cd ansible                                              │
│ ./update_inventory.sh                                   │
│ # Fetches IPs from Terraform outputs                    │
│ # Updates all inventory files                           │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Test Connectivity                                    │
│                                                         │
│ ansible all -m ping -i inventories/dev/hosts            │
│ # Verifies SSH connectivity                             │
│ # Confirms authentication works                         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Syntax Check (Optional but Recommended)              │
│                                                         │
│ ansible-playbook playbooks/site.yml --syntax-check      │
│ # Validates YAML syntax                                 │
│ # Catches errors before execution                       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 4. Dry Run (Check Mode)                                 │
│                                                         │
│ ansible-playbook -i inventories/dev/hosts \             │
│   playbooks/site.yml --check --diff                     │
│ # Shows what would change                               │
│ # No actual changes made                                │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 5. Apply Configuration                                  │
│                                                         │
│ ansible-playbook -i inventories/dev/hosts \             │
│   playbooks/site.yml                                    │
│ # Applies configuration                                 │
│ # Installs Docker and Nginx                             │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 6. Verify Configuration                                 │
│                                                         │
│ # Check Docker                                          │
│ ansible all -i inventories/dev/hosts \                  │
│   -m command -a "docker --version"                      │
│                                                         │
│ # Check Nginx                                           │
│ ansible all -i inventories/dev/hosts \                  │
│   -m service -a "name=nginx state=started"              │
│                                                         │
│ # Access web interface                                  │
│ curl http://<instance-ip>                               │
└─────────────────────────────────────────────────────────┘
```

### Repeat for Other Environments

```bash
# Staging
ansible-playbook -i inventories/stg/hosts playbooks/site.yml

# Production
ansible-playbook -i inventories/prod/hosts playbooks/site.yml
```

---
