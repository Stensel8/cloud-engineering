# Assignment 3: Cloud Orchestration

## Leerdoelen

De module heeft de volgende leerdoelen geformuleerd:

- Orkestratie- en configuratietools gebruiken (Kubernetes, Terraform, Ansible) in een multi-cloud omgeving.

**Behaald.** AWS-resources worden uitgerold via Terraform-modules die de bestaande CloudFormation-templates aanroepen. GCP-resources (netwerk, Artifact Registry, GKE-cluster en globale load balancer) worden volledig door Terraform beheerd. Ansible configureert het GKE-cluster en verzamelt logbestanden naar GCS.

## Requirements

| Requirement | Status | Bewijs |
|---|---|---|
| REQ-15: AWS-resources uitgerold met Terraform | Behaald | `terraform/modules/aws/` (base_stack, rds-stack, efs_stack, elk_stack, buildserver_stack) |
| REQ-16: Applicatie uitgerold op GCP via Terraform | Behaald | `terraform/modules/gcp/gke_cluster/` deployt het GKE-cluster; `ansible/playbooks/gke_config.yml` rolt de applicatie uit |
| REQ-17: Gebruikers bereiken applicatie via één extern IP-adres | Behaald | `terraform/modules/gcp/loadbalancer/` (Google Cloud Global HTTP Load Balancer met statisch extern IP) |
| REQ-18: Docker-images gehost op Artifact Registry | Behaald | `terraform/modules/gcp/artifact_registry/` (Docker-format repository in `europe-west4`) |
| REQ-19: Kubernetes-cluster op GCP | Behaald | `terraform/modules/gcp/gke_cluster/` (GKE Autopilot-compatibel cluster in `europe-west4`) |
| REQ-20: Kubernetes-cluster met 5 replica's | Behaald | `ansible/playbooks/gke_config.yml` (variabele `replica_count: 5`) |
| REQ-21: Ansible configureert het Kubernetes-cluster | Behaald | `ansible/playbooks/gke_config.yml` + `ansible/roles/gke_config/` (namespace, secrets, deployments, services, Ingress) |
| REQ-22: Ansible verzamelt logbestanden | Behaald | `ansible/playbooks/log_collector.yml` (kubectl logs per pod, upload naar GCS via gsutil) |

## Belangrijkste keuzes

**Terraform wraps CloudFormation.** De AWS-modules in Terraform roepen de bestaande CloudFormation-templates aan via de `aws_cloudformation_stack`-resource. Zo hoeven de templates niet opnieuw geschreven te worden en blijven ze de enige bron van waarheid voor de AWS-resources. Terraform beheert de levenscyclus (aanmaken, bijwerken, verwijderen).

**Multi-cloud: AWS voor backend, GCP voor de applicatielaag.** AWS beheert de databronnen (RDS, EFS) en de ELK-monitoring. GCP beheert de containerinfrastructuur (GKE) en de image-registry (Artifact Registry). Dit sluit aan bij het multi-cloud leerdoel van de module.

**GKE met private nodes.** Worker-nodes in het GKE-cluster hebben geen publieke IP-adressen (`enable_private_nodes = true`). Beheer loopt via de privé Control Plane. De master-IP is beperkt tot het interne VPC-subnet en tijdelijk voor alle adressen opengesteld voor labgebruik (`allow-all-lab`).

**Google Cloud Global HTTP Load Balancer.** Gekozen voor een statisch wereldwijd IP-adres. De load balancer distribueert verkeer naar de GKE-backend-service. Alle gebruikers bereiken de applicatie via dit ene IP-adres (REQ-17).

**Artifact Registry in dezelfde regio als GKE.** Zowel Artifact Registry als het GKE-cluster draaien in `europe-west4`. Image pulls blijven binnen de regio, wat de latency verlaagt en geen egress-kosten genereert.

**Terraform outputs als bron voor Ansible.** Het Ansible-playbook voert `terraform output -json` uit om waarden zoals het GKE-clusternaam, GCP-project en RDS-endpoint op te halen. Zo is er geen handmatige parameter-overdracht nodig tussen de twee tools.

**SNS-notificaties voor CloudFormation-events.** Alle Terraform-beheerde CloudFormation-stacks kunnen een SNS-topic-ARN meekrijgen. Dit is optioneel (lege string = uitgeschakeld), maar maakt het eenvoudig om stack-events naar e-mail of Slack te sturen.

**Logverzameling naar GCS.** Ansible haalt via `kubectl logs` de logs op van alle pods in de `cloudshirt`-namespace en uploadt ze als losse bestanden naar een GCS-bucket via `gsutil`. Dit is een eenvoudige en auditeerbare aanpak voor log-archivering.

## Uitrol

**Vereisten:**
- Terraform 1.6+
- Google Cloud SDK (`gcloud`, `gsutil`)
- `kubectl`
- Ansible met de `kubernetes.core`-collectie
- Een GCP-serviceaccount-sleutel als JSON-bestand
- AWS-credentials (via omgevingsvariabelen of een profiel)

**Stap 1: variabelen instellen**

Maak een `terraform.tfvars`-bestand aan in de `terraform/`-map:

```hcl
project_id               = "jouw-gcp-project-id"
gcp_region               = "europe-west4"
gcp_repo_name            = "cloudshirt-docker"
db_password              = "jouw-database-wachtwoord"
gcp_service_account_json = "<base64-encoded service account JSON>"
cfn_notification_sns_arn = ""
```

Het serviceaccount-JSON-bestand base64-encoderen (Linux/Mac):
```bash
base64 -w 0 jouw-key.json
```

Windows (PowerShell):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("jouw-key.json"))
```

**Stap 2: Terraform uitvoeren**

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Dit rolt de volgende resources uit:

- **AWS:** base-stack (VPC, subnetten, security groups), RDS, EFS, ELK-stack en buildserver via CloudFormation.
- **GCP:** VPC-netwerk, Artifact Registry-repository, GKE-cluster en globale HTTP load balancer.

**Stap 3: Ansible uitvoeren**

Nadat Terraform klaar is, wordt het GKE-cluster geconfigureerd via Ansible:

```bash
cd ansible
ansible-playbook playbooks/gke_config.yml
```

Dit playbook:
1. Haalt Terraform-outputs op (clusternaam, project, region, RDS-endpoint).
2. Authenticeert bij GCP via het serviceaccount.
3. Haalt GKE-credentials op via `gcloud`.
4. Maakt de `cloudshirt`-namespace aan.
5. Slaat het RDS-verbindingsstring op als Kubernetes-secret.
6. Rolt de CloudShirt-deployments uit met 5 replica's (via de `gke_config`-rol).

**Stap 4: logverzameling (optioneel)**

```bash
ansible-playbook playbooks/log_collector.yml
```

Dit playbook haalt de logs op van alle pods in de `cloudshirt`-namespace en uploadt ze naar GCS.

**Infrastructuur verwijderen:**
```bash
cd terraform
terraform destroy
```

> Let op: de CloudFormation-stacks die Terraform beheert, worden ook verwijderd. Verwijder eerst handmatig de data (RDS-snapshots, EFS-bestanden) als je die wilt bewaren.

## Aanbevelingen

**Terraform remote state.** Nu wordt de Terraform-state lokaal opgeslagen. In een teamomgeving wordt de state opgeslagen in een S3-bucket (AWS) of GCS-bucket (GCP) met state-locking via DynamoDB of GCS-versioning.

**Secrets via Vault of Secret Manager.** Het database-wachtwoord en het serviceaccount-JSON worden nu als Terraform-variabele meegegeven. In productie worden deze waarden opgehaald uit HashiCorp Vault, AWS Secrets Manager of GCP Secret Manager.

**HTTPS op de GCP load balancer.** De huidige load balancer gebruikt HTTP. In productie wordt een Google-beheerd SSL-certificaat gekoppeld via `google_compute_managed_ssl_certificate` en wordt HTTP naar HTTPS geredirect.

**GKE Workload Identity.** De pods in het GKE-cluster gebruiken nu geen service-account-koppeling voor toegang tot GCP-services. Workload Identity vervangt het opslaan van serviceaccount-sleutels in Kubernetes-secrets.

**CI/CD voor de image-build.** Het bouwen en pushen van Docker-images naar Artifact Registry is nu een handmatige stap (via de buildserver). In productie neemt een Cloud Build-trigger of GitHub Actions-workflow dit over bij elke push naar de `main`-branch.

**Ansible-inventaris dynamisch genereren.** Het huidige `inventory`-bestand is statisch. Bij gebruik van auto-scaling of wisselende node-adressen is een dynamische inventaris (via `gcloud` of de GCP Ansible-plugin) nauwkeuriger.
