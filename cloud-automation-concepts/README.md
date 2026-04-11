# Cloud Automation Concepts

> [!WARNING]
> **Deprecated vanaf juni 2026.** Deze repository bevat de uitwerking van de Cloud Automation Concepts specialisatie (Cloud Engineering, jaar 3). De specialisatie is afgerond en deze repository wordt niet meer bijgehouden.

> Schoolopdracht - Cloud Engineering-specialisatie
> Duo: [Stensel8](https://github.com/Stensel8) & [Hintenhaus04](https://github.com/Hintenhaus04)

## Over deze module

Geautomatiseerde productie van infrastructuur (zero-touch deployment) met Infrastructure as Code op **AWS**. Onderwerpen zijn onder andere containerisatie, orkestratie (Kubernetes) en configuratiebeheer (Terraform, Ansible, CloudFormation) in publieke, hybride en multi-cloud omgevingen.

## Leerdoelen

- (Onderling afhankelijke) resources op een geautomatiseerde manier inrichten in AWS
- Een bestaande applicatie containeriseren en op een geautomatiseerde manier uitrollen op een cloudinfrastructuur
- Orkestratie- en configuratietools gebruiken (Kubernetes, Terraform, Ansible) in een multi-cloud omgeving

## Inleverpunten

> [!NOTE]
> De weekopdrachten (Week 1-7) zijn vervallen als verplicht inleverpunt. Ze staan nog in de repo als referentie en oefenmateriaal, maar het portfolio bestaat momenteel uit de drie onderstaande assignments.


### Gerelateerde repositories

Deze module maakt gebruik van twee zelfgemaakte applicaties die samen als bewijs dienen voor de assignments:

| Repository | Rol in deze module |
|------------|-------------------|
| [Stensel8/CloudShirt](https://github.com/Stensel8/CloudShirt) | .NET-applicatie (monoliet + microservices); primaire basis voor Assignment 1 en 3 |
| [Stensel8/CloudShirt-Hugo](https://github.com/Stensel8/CloudShirt-Hugo) | Go/Hugo-variant (alleen Docker); gebruikt in Assignment 2 (Docker Swarm) |
| **[stensel8/cloud-engineering](https://github.com/stensel8/cloud-engineering/tree/main/cloud-automation-concepts)** *(deze repo)* | Schoolopdracht IaC - opdrachtkaders, CloudFormation/Terraform/Ansible en requirementstructuur |

Beide applicaties zijn gebouwd door **[Stensel8](https://github.com/Stensel8)** en **[Hintenhaus04](https://github.com/Hintenhaus04)** specifiek voor deze opdracht. Ze zijn geïnspireerd op de open-source [eShopOnWeb](https://github.com/dotnet-architecture/eShopOnWeb) demo van Microsoft en de [upstream van de docent](https://github.com/looking4ward/CloudShirt).

CloudShirt (.NET) staat als git submodule in [CloudShirt/](CloudShirt/), en volgt de `main` branch zodat de koppeling versievast blijft. Bijwerken:

```bash
git submodule update --remote --merge
```

### Tooling

- Ontwikkeld met hulp van **[Claude Code](https://claude.ai/code)** (Anthropic) als AI-assistent bij de implementatie van beide applicaties.



### Assignment 1: AWS Basics

> Bestanden in [Assignment 1 - AWS Basics/](Assignment%201%20-%20AWS%20Basics/)

Bouw een AWS CloudFormation-oplossing die alle negen leerdoelen dekt en voldoet aan de eisen van klant **CloudShirt**, een startup uit Duitsland.

**Deliverables:** CloudFormation-templates en scripts, plus een rapport (~5 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

| Requirement | Bewijs |
|---|---|
| REQ-01 - High availability over meerdere AZ's via een URL | [cloudshirt-loadbalancer.yml](Assignment%201%20-%20AWS%20Basics/cloudshirt-loadbalancer.yml) |
| REQ-02 - Autoscaling tijdens piekuren (18:00-20:00 Eastern) | [cloudshirt-asg.yml](Assignment%201%20-%20AWS%20Basics/cloudshirt-asg.yml) |
| REQ-03 - EFS voor dagelijkse opslag van webserverlogs | [cloudshirt-efs.yml](Assignment%201%20-%20AWS%20Basics/cloudshirt-efs.yml) |
| REQ-04 - RDS via IaC | [cloudshirt-rds.yml](Assignment%201%20-%20AWS%20Basics/cloudshirt-rds.yml) |
| REQ-05 - Monitoringoplossing (ELK) via IaC | [cloudshirt-elk.yml](Assignment%201%20-%20AWS%20Basics/cloudshirt-elk.yml) |
| REQ-06 - Logs zichtbaar in Elastic Stack via Filebeat (optioneel) | [cloudshirt-ec2.yml](Assignment%201%20-%20AWS%20Basics/cloudshirt-ec2.yml) |
| REQ-07 - Scriptmatige export ordertabel naar S3 | [export-orders.sh](Assignment%201%20-%20AWS%20Basics/export-orders.sh) |
| REQ-08 - AWS serverless-applicatie | [cloudshirt-s3.yml](Assignment%201%20-%20AWS%20Basics/cloudshirt-s3.yml) |

### Assignment 2: Docker in the Cloud

> Bestanden in [Assignment 2 - Docker Swarm/](Assignment%202%20-%20Docker%20Swarm/)

Bouw voort op Assignment 1. Dockeriseer de applicatie en richt een Docker-infrastructuur in op AWS.

**Deliverables:** Templates en scripts, plus een rapport (~3 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

> [!IMPORTANT]
> Assignment 2 gebruikt **Stensel8/Cloudshirt-Hugo** als applicatiebasis. De `Dockerfile` en `docker-compose.yml` staan in die repository.

| Requirement | Bewijs |
|---|---|
| REQ-08 - Applicatie is gedockeriseerd | [Dockerfile](https://github.com/Stensel8/Cloudshirt-Hugo/blob/main/Dockerfile) (Stensel8/Cloudshirt-Hugo) |
| REQ-09 - Applicatie wordt gebouwd op een Buildserver in het private subnet | [cloudshirt-swarm-buildserver.yml](Assignment%202%20-%20Docker%20Swarm/cloudshirt-swarm-buildserver.yml) |
| REQ-10 - Docker Compose voor services en uitrol | [docker-compose.yml](https://github.com/Stensel8/Cloudshirt-Hugo/blob/main/docker-compose.yml) (Stensel8/Cloudshirt-Hugo) |
| REQ-11 - Nightly builds op de Buildserver | [cloudshirt-swarm-buildserver.yml](Assignment%202%20-%20Docker%20Swarm/cloudshirt-swarm-buildserver.yml) (cron 02:00 UTC via nightly-build.sh) |
| REQ-12 - Images worden gepusht naar AWS ECR | [cloudshirt-swarm-ecr.yml](Assignment%202%20-%20Docker%20Swarm/cloudshirt-swarm-ecr.yml) + [cloudshirt-swarm-buildserver.yml](Assignment%202%20-%20Docker%20Swarm/cloudshirt-swarm-buildserver.yml) (nightly-build.sh) |
| REQ-13 - Buildserver als Swarm Manager | [cloudshirt-swarm-buildserver.yml](Assignment%202%20-%20Docker%20Swarm/cloudshirt-swarm-buildserver.yml) |
| REQ-14 - ASG-instances als Swarm Workers | [cloudshirt-swarm-asg.yml](Assignment%202%20-%20Docker%20Swarm/cloudshirt-swarm-asg.yml) |

### Assignment 3: Cloud Orchestration

> Bestanden in [Assignment 3 - Orchestration/](Assignment%203%20-%20Orchestration/)

Bouw voort op Assignments 1 en 2. Gebruik Terraform en Ansible in een multi-cloud architectuur.

**Deliverables:** Templates en scripts, plus een rapport (~3 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

| Requirement | Bewijs |
|---|---|
| REQ-15 - AWS-resources uitgerold met Terraform | [terraform/main.tf](Assignment%203%20-%20Orchestration/terraform/main.tf) roept vijf AWS-modules aan: `base_stack`, `rds-stack`, `efs_stack`, `elk_stack` en `buildserver_stack`, elk met een bijbehorende CloudFormation-template in [terraform/templates/](Assignment%203%20-%20Orchestration/terraform/templates/) |
| REQ-16 - Applicatie uitgerold op GCP via Terraform | [terraform/modules/gcp/gke_cluster/main.tf](Assignment%203%20-%20Orchestration/terraform/modules/gcp/gke_cluster/main.tf) rolt het GKE-cluster uit; [ansible/playbooks/gke_config.yml](Assignment%203%20-%20Orchestration/ansible/playbooks/gke_config.yml) deployt de applicatie op het cluster via Terraform-outputs |
| REQ-17 - Gebruikers bereiken applicatie via één extern IP-adres | [terraform/modules/gcp/loadbalancer/main.tf](Assignment%203%20-%20Orchestration/terraform/modules/gcp/loadbalancer/main.tf) maakt een `google_compute_global_address` aan met bijbehorende forwarding rule; het IP-adres wordt via `output "external_ip"` beschikbaar gesteld |
| REQ-18 - Docker-images gehost op Artifact Registry | [terraform/modules/gcp/artifact_registry/main.tf](Assignment%203%20-%20Orchestration/terraform/modules/gcp/artifact_registry/main.tf) maakt een Docker-repository aan in `europe-west4`; het imagepad wordt dynamisch samengesteld in het Ansible-playbook |
| REQ-19 - Kubernetes-cluster op GCP | [terraform/modules/gcp/gke_cluster/main.tf](Assignment%203%20-%20Orchestration/terraform/modules/gcp/gke_cluster/main.tf): GKE-cluster `cloudshirt-gke` in `europe-west4` met private nodes, Workload Identity, Calico network policy en Binary Authorization |
| REQ-20 - Kubernetes-cluster: Master met 5 replica's | [ansible/roles/vars/main.yml](Assignment%203%20-%20Orchestration/ansible/roles/vars/main.yml): `replica_count: 5`; dit wordt via [ansible/roles/gke_config/templates/deployment.yml.j2](Assignment%203%20-%20Orchestration/ansible/roles/gke_config/templates/deployment.yml.j2) ingevuld in `spec.replicas` van het Kubernetes Deployment-manifest |
| REQ-21 - Ansible configureert het Kubernetes-cluster | [ansible/playbooks/gke_config.yml](Assignment%203%20-%20Orchestration/ansible/playbooks/gke_config.yml) haalt Terraform-outputs op, stelt kubeconfig in, maakt de namespace aan, zet een RDS-secret en deployt beide services via de rol [ansible/roles/gke_config/](Assignment%203%20-%20Orchestration/ansible/roles/gke_config/); ingress via [ingress.yml.j2](Assignment%203%20-%20Orchestration/ansible/roles/gke_config/templates/ingress.yml.j2) |
| REQ-22 - Ansible verzamelt logbestanden | [ansible/roles/log_collection/tasks/main.yml](Assignment%203%20-%20Orchestration/ansible/roles/log_collection/tasks/main.yml) haalt logs op per pod via `kubernetes.core.k8s_log`, schrijft ze weg als lokale `.log`-bestanden en uploadt ze naar GCS via `gsutil cp` |

---

## Weekmateriaal (referentie)

De weekopdrachten zijn vervallen als inleverpunt, maar het lesmateriaal en de oefenbestanden blijven beschikbaar als referentie.

| Week | Onderwerp | Map |
|------|-----------|-----|
| Week 1 | Introductie & CloudFormation | [Weekopdrachten (vervallen)/Week 1/](Weekopdrachten%20%28vervallen%29/Week%201/) |
| Week 2 | Networking en Elasticity | [Weekopdrachten (vervallen)/Week 2/](Weekopdrachten%20%28vervallen%29/Week%202/) |
| Week 3 | Databases en Storage | [Weekopdrachten (vervallen)/Week 3/](Weekopdrachten%20%28vervallen%29/Week%203/) |
| Week 4 | File Storage en Backup (AWS CLI, S3, EFS) | [Weekopdrachten (vervallen)/Week 4/](Weekopdrachten%20%28vervallen%29/Week%204/) |

---
## VS Code instellen

<details>
<summary>CloudFormation en YAML linting</summary>

Het lesmateriaal van Saxion verwijst naar de extensie [cform-VSCode](https://github.com/aws-scripting-guy/cform-VSCode) van `aws-scripting‑guy`. **Installeer deze extensie niet.**  
Deze is al sinds 2022 niet meer actief onderhouden, herkent moderne CloudFormation‑syntax niet goed en kan onjuiste of verwarrende waarschuwingen geven.

Gebruik in plaats daarvan de officieel ondersteunde **CloudFormation Linter**‑extensie (`kddejong.vscode‑cfn‑lint`). Deze wordt actief beheerd en ondersteund door AWS, bevat de nieuwste resource‑typen en intrinsieke functies (`!Ref`, `!Sub`, `!GetAtt`, enzovoort) en laat fouten direct in de editor zien.

### Stap 1: extensies installeren

Bij het openen van deze repo toont VS Code meestal een popup om de “aanbevolen extensies” te installeren. Klik op **Install** om deze automatisch toe te voegen:
- `kddejong.vscode-cfn-lint` (CloudFormation‑linter)
- `redhat.vscode-yaml` (algemene YAML‑ondersteuning, vereist voor de linter)

### Stap 2: cfn-lint installeren

De `kddejong.vscode‑cfn‑lint`‑extensie werkt samen met het `cfn‑lint`‑pakket, dat je via `pip` installeert:

```bash
pip install -r requirements.txt
```

Verifieer dat het goed geïnstalleerd is:

```bash
cfn-lint --version
```

Als VS Code de `cfn‑lint`‑binary niet direct ziet, herstart de editor zodat de extensie het opnieuw kan detecteren.

</details>

<details>
<summary>AWS CLI installeren en configureren</summary>

Voor de opdrachten in deze module is de [AWS CLI](https://aws.amazon.com/cli/) nodig. Installeer deze één keer, en gebruik daarna `aws configure` of een handmatige credentials‑configuratie.

### Linux

Afhankelijk van je distributie:

```bash
# Arch Linux
sudo pacman -S aws-cli-v2

# Fedora
sudo dnf install awscli2

# Debian/Ubuntu
sudo apt install awscli
```

Controleer de installatie:

```bash
aws --version
```

Een typische uitvoer ziet er zo uit:

```text
aws-cli/2.x.x Python/3.x.x Linux/x86_64
```

Configureer daarna je AWS‑gebruiker:

- Interactief:  
  ```bash
  aws configure
  ```  
  Vul achtereenvolgens `Access Key ID`, `Secret Access Key`, `region` en `output format` in.

- Directe file‑aanpak (aanbevolen bij AWS Academy):  
  ```bash
  nano ~/.aws/credentials
  ```  
  Plak de volledige credentials zoals AWS Academy ze aangeeft:

  ```ini
  [default]
  aws_access_key_id=ASIA...
  aws_secret_access_key=...
  aws_session_token=...
  ```

> [!WARNING]
> Bij gebruik van **AWS Academy (Learner Lab)** worden de `Access Key ID`, `Secret Access Key` en `aws_session_token` bij elke nieuwe sessie opnieuw gegenereerd. Er is geen persistente toegang; herhaal de credentials‑stap na elke nieuwe sessie.  
> In productie‑omgevingen blijven de access key en secret key normaal gesproken statisch, zodat je ze maar één keer hoeft in te stellen.

![AWS credentials instellen na nieuwe sessie](../assets/aws-credentials-instellen.avif)

</details>

<details>
<summary>Windows (AWS CLI)</summary>

Op Windows kun je de AWS CLI installeren via:

- De officiële MSI‑installer via de [AWS CLI‑downloadpagina](https://awscli.amazonaws.com/AWSCLIV2.msi), of
- Via winget:

  ```powershell
  winget install -e --id Amazon.AWSCLI
  ```

Start na de installatie een nieuwe PowerShell of Command Prompt opnieuw om zeker te weten dat `aws` in de `PATH` staat.

Configureer je AWS‑gebruiker vervolgens:

- Interactief:
  ```powershell
  aws configure
  ```  
  Vul de gevraagde velden (`Access Key ID`, `Secret Access Key`, `region`, `output format`) in.

- Directe file‑aanpak (aanbevolen bij AWS Academy):  
  Open het bestand `%USERPROFILE%\.aws\credentials` in een editor (bijv. Kladblok) en plak:

  ```ini
  [default]
  aws_access_key_id=ASIA...
  aws_secret_access_key=...
  aws_session_token=...
  ```

> [!WARNING]
> Bij **AWS Academy (Learner Lab)** veranderen alle drie de credentials bij elke sessie. Herhaal de configuratiestap na elke nieuwe sessie.  
> In productie‑omgevingen zijn de access key en secret key in de regel blijvend, waardoor je ze maar één keer hoeft in te stellen.

</details>
