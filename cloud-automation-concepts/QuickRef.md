# Quick Reference — Cloud Engineering Assignments

---

## Assignment 1 — AWS Basics (CloudFormation)

### Architectuur

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  VPC  10.0.0.0/16                                       │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐  ← public subnets │
│  │ ALB          │──▶│ ALB          │                   │
│  └──────┬───────┘    └──────────────┘                   │
│         │ verdeelt verkeer                              │
│  ┌──────▼───────────────────────┐   ← private subnets   │
│  │  EC2 Web 1    EC2 Web 2      │   (.NET + nginx)      │
│  │  (AZ1)        (AZ2)          │                       │
│  └──────┬────────────┬──────────┘                       │
│         │            │                                  │
│         ▼            ▼                                  │
│  ┌────────────┐  ┌─────────┐  ┌───────────┐             │
│  │ RDS        │  │ EFS     │  │ ELK Stack │             │
│  │ PostgreSQL │  │ (logs)  │  │ (Kibana)  │             │
│  └────────────┘  └─────────┘  └───────────┘             │
│                                                         │
│  ASG (schaalt EC2 extra bij piek 18-20 ET)              │
│  S3 (order exports) ──▶ Lambda ──▶ SNS melding         │
└─────────────────────────────────────────────────────────┘
```

### Stack deploy-volgorde

| # | Stack | Wat |
|---|---|---|
| 1 | `cloudshirt-network` | VPC, subnets, IGW, NAT, security groups |
| 2 | `cloudshirt-efs` | Gedeeld bestandssysteem (logs) |
| 2 | `cloudshirt-elk` | Elasticsearch + Logstash + Kibana (EC2) |
| 2 | `cloudshirt-rds` | PostgreSQL via Secrets Manager |
| 3 | `cloudshirt-ec2` | 2 webservers via LaunchTemplate |
| 4 | `cloudshirt-s3` | S3-bucket voor order-exports |
| 5 | `cloudshirt-lb` | Application Load Balancer |
| 6 | `cloudshirt-asg` | Auto Scaling Group |
| 7 | `cloudshirt-serverless` | Lambda + SNS + SQS + EventBridge |

### Deploy-commando (per stack)

```bash
aws cloudformation deploy \
  --template-file cloudshirt-network.yml \
  --stack-name cloudshirt-network \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

---

## Assignment 2 — Docker Swarm (CloudFormation)

### Architectuur

```
Internet
    │
    ▼
┌──────────────────────────────────────────────────────────┐
│  VPC  10.0.0.0/16                                        │
│                                                          │
│  ┌─────────────────────────┐  ← public subnets           │
│  │        ALB              │                             │
│  └────────────┬────────────┘                             │
│               │                                          │
│  ┌────────────▼────────────┐  ← private subnets          │
│  │  ASG Worker Nodes (2-4) │  Docker Swarm Workers       │
│  └────────────▲────────────┘                             │
│               │ swarm join (SSM token)                   │
│  ┌────────────┴────────────┐  ← private subnet           │
│  │  Buildserver            │  Swarm Manager              │
│  │  (EC2, t3.medium)       │  nightly build @ 02:00 UTC  │
│  └────────────┬────────────┘                             │
│               │ push images                              │
│  ┌────────────▼────────────┐                             │
│  │  ECR Repository         │  cloudshirt + cloudshirt-api│
│  └─────────────────────────┘                             │
│                                                          │
│  SSM Parameter Store: /cloudshirt/swarm/worker-token     │
│                        /cloudshirt/swarm/manager-ip      │
└──────────────────────────────────────────────────────────┘
```

### Stack deploy-volgorde

| # | Stack | Wat |
|---|---|---|
| 1 | `cloudshirt-swarm-network` | VPC, subnets, NAT, security groups |
| 2 | `cloudshirt-swarm-ecr` | ECR repository |
| 3 | `cloudshirt-swarm-buildserver` | EC2 Swarm Manager + nightly build |
| 4 | `cloudshirt-swarm-alb` | Application Load Balancer |
| 5 | `cloudshirt-swarm-asg` | ASG Worker Nodes |

### Belangrijke Docker Swarm commando's

```bash
# Swarm initialiseren (op manager)
docker swarm init --advertise-addr <PRIVATE_IP>

# Worker-token opvragen
docker swarm join-token worker -q

# Worker laten joinen (op worker node)
docker swarm join --token <TOKEN> <MANAGER_IP>:2377

# Stack deployen vanuit compose file
docker stack deploy --with-registry-auth -c docker-compose.swarm.yml cloudshirt

# Services bekijken
docker service ls
docker node ls

# Rolling update van een service
docker service update \
  --with-registry-auth \
  --image <ECR_URI>:<TAG> \
  --update-parallelism 1 \
  --update-delay 30s \
  cloudshirt_web

# ECR inloggen
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com
```

---

## Assignment 3 — Orchestration (Terraform + Ansible, GCP + AWS)

### Architectuur

```
┌─────────────────────────────────────────────────────────────┐
│  Terraform                                                  │
│                                                             │
│  ┌─── GCP ───────────────────┐  ┌─── AWS ────────────────┐  │
│  │  network                  │  │  base_stack (VPC etc.) │  │
│  │    ↓                      │  │    ↓ (parallel)        │  │
│  │  artifact_registry (ECR)  │  │  rds_stack             │  │
│  │    ↓                      │  │  efs_stack             │  │
│  │  gke_cluster (Kubernetes) │  │  elk_stack             │  │
│  │    ↓                      │  │    ↓ (alle klaar)      │  │
│  │  loadbalancer             │  │  buildserver_stack     │  │
│  └───────────────────────────┘  └────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Ansible                                                    │
│                                                             │
│  gke_config.yml    → configureert GKE cluster               │
│  log_collector.yml → configureert log-verzameling           │
└─────────────────────────────────────────────────────────────┘
```

### Terraform commando's

```bash
terraform init            # providers downloaden
terraform plan            # wat gaat er veranderen?
terraform apply           # uitrollen (bevestigen met yes)
terraform apply -auto-approve  # zonder bevestiging
terraform destroy         # alles verwijderen
terraform output          # outputs tonen
```

### Ansible commando's

```bash
ansible-playbook -i inventory playbooks/gke_config.yml
ansible-playbook -i inventory playbooks/log_collector.yml
ansible all -m ping       # verbinding testen
```

---

## CloudFormation Intrinsic Functions — spiekbriefje

| Syntax | Gebruik | Voorbeeld |
|---|---|---|
| `!Ref X` | Waarde van parameter / ID van resource | `!Ref InstanceType` |
| `!Sub "..."` | String met `${variabele}` erin | `!Sub "${AWS::StackName}:Output"` |
| `!GetAtt R.Attr` | Attribuut van resource | `!GetAtt Instance.PrivateIp` |
| `!ImportValue naam` | Output uit andere stack | `!ImportValue cloudshirt-network:VPC` |
| `Fn::Base64` | Base64 coderen (altijd voor UserData) | `Fn::Base64: !Sub \|` |
| `!Select [i, lijst]` | Element uit lijst | `!Select [0, !GetAZs ""]` |
| `!Join [sep, lijst]` | Lijst samenvoegen | `!Join [",", [a, b]]` → `"a,b"` |

### Pseudo-parameters (altijd beschikbaar)

| Naam | Waarde |
|---|---|
| `AWS::Region` | `us-east-1` |
| `AWS::AccountId` | jouw account ID |
| `AWS::StackName` | naam van de huidige stack |

### Cross-stack exports (patroon)

```yaml
# Stack A: exporteer
Outputs:
  MyVPC:
    Value: !Ref VPC
    Export:
      Name: !Sub "${AWS::StackName}:VPC"   # → "cloudshirt-network:VPC"

# Stack B: importeer
VpcId: !ImportValue cloudshirt-network:VPC
```

---

## SSM Parameter Store commando's

```bash
# Waarde opslaan
aws ssm put-parameter \
  --name "/cloudshirt/swarm/worker-token" \
  --value "$TOKEN" \
  --type SecureString \
  --overwrite

# Waarde ophalen
aws ssm get-parameter \
  --name "/cloudshirt/swarm/worker-token" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text
```

---

## Diagnose & Verbinding — Handige commando's

### Verbinding maken met EC2

```bash
# Via SSH
ssh -i ~/.ssh/my-key.pem ec2-user@<PUBLIC_IP>

# Via SSM Session Manager (geen SSH/Bastion nodig)
aws ssm start-session --target <INSTANCE_ID>

# Instance ID opzoeken via naam-tag
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=buildserver" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text
```

### Docker Swarm — status

```bash
# Nodes in de swarm (manager/worker + status)
docker node ls

# Alle services + replica-status
docker service ls

# Taken per service (op welke node draait wat?)
docker service ps cloudshirt_web
docker service ps cloudshirt_web --no-trunc   # volledige foutmelding tonen

# Stack-overzicht
docker stack ps cloudshirt          # alle taken
docker stack services cloudshirt    # services in de stack

# Containers op deze node
docker ps                           # draaiende containers
docker ps -a                        # inclusief gestopte containers
```

### Docker logs

```bash
# Logs van een service (swarm — streamt over alle replicas)
docker service logs cloudshirt_web
docker service logs --tail 100 -f cloudshirt_web   # laatste 100, live meevolgen

# Logs van een specifieke container
docker logs <CONTAINER_ID>
docker logs --tail 50 -f <CONTAINER_ID>
```

### Systeemlogs (journalctl)

```bash
# Docker daemon logs
journalctl -u docker -f

# Specifieke service, live
journalctl -u nginx --since today -f

# Laatste N regels
journalctl -n 100

# Tijdsvenster
journalctl --since "1 hour ago"

# CloudFormation UserData output (bootstrap-fouten opsporen)
journalctl -u cloud-init -f
cat /var/log/cloud-init-output.log
```

### CloudFormation stack status

```bash
# Overzicht van alle stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE \
  --query "StackSummaries[].{Name:StackName,Status:StackStatus}" \
  --output table

# Events van een stack (debug bij CREATE_FAILED / ROLLBACK)
aws cloudformation describe-stack-events \
  --stack-name cloudshirt-ec2 \
  --query "StackEvents[?contains(ResourceStatus,'FAILED')]" \
  --output table

# Outputs van een stack ophalen
aws cloudformation describe-stacks \
  --stack-name cloudshirt-network \
  --query "Stacks[0].Outputs" \
  --output table
```

### EC2 & ASG overzicht

```bash
# Alle draaiende instanties (naam, IP, state)
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key=='Name']|[0].Value,IP:PrivateIpAddress,State:State.Name}" \
  --output table

# ASG — huidige capaciteit
aws autoscaling describe-auto-scaling-groups \
  --query "AutoScalingGroups[].{Name:AutoScalingGroupName,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Running:length(Instances)}" \
  --output table
```

