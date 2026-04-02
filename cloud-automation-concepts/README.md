# Cloud Automation Concepts

> Schoolopdracht - Cloud Engineering-specialisatie, Jaar 3, Q3 (5 EC)
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

> [!IMPORTANT]
> Deze module is direct afhankelijk van de Stensel8/CloudShirt repository. De implementatie en bewijsvoering worden bijgehouden in code, configuratie en documentatie in die repository:
> https://github.com/stensel8/CloudShirt

### Cross-referentie met CloudShirt

CloudShirt is de applicatiebasis voor deze module:

- Oorsprong: geforkte/basisvariant welke oorspronkelijk is ontwikkeld door een docent.
- Doorontwikkeling: omgebouwd en gemoderniseerd door mij (Stensel8). De applicatie is hierdoor inzetbaar voor zowel monolithische als gecontaineriseerde deployments, en voldoet hierdoor aan de eisen.
- Toepassing: gebruikt in de drie assignments binnen Cloud Automation Concepts om requirements aantoonbaar af te vinken.

Samenhang tussen de repositories:

- [CloudShirt](https://github.com/stensel8/CloudShirt): applicatie en deployment-uitwerking.
- [cloud-automation-concepts](https://github.com/stensel8/cloud-engineering/tree/main/cloud-automation-concepts): opdrachtkaders en requirementstructuur.

CloudShirt staat nu als git submodule in [CloudShirt/](CloudShirt/), en volgt de `main` branch zodat de koppeling expliciet en versievast blijft.

Bijwerken kan later met `git submodule update --remote --merge`, zodat de submodule naar de nieuwste `main`-commit opschuift.

Je zou dit kunnen zien als een platform en een applicatie, welke beide in hun eigen repository staan, maar elkaar onderling nodig hebben voor de uitvoering van de opdrachten. Dat is het idee van microservices.



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

> Bestanden in [Assignment 2 - Docker/](Assignment%202%20-%20Docker/)

Bouw voort op Assignment 1. Dockeriseer de applicatie en richt een Docker-infrastructuur in op AWS.

**Deliverables:** Templates en scripts, plus een rapport (~3 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

| Requirement | Bewijs |
|---|---|
| REQ-08 - Applicatie is gedockeriseerd |  |
| REQ-09 - Applicatie wordt gebouwd op een Buildserver in het private subnet |  |
| REQ-10 - Docker Compose voor services en uitrol |  |
| REQ-11 - Nightly builds op de Buildserver |  |
| REQ-12 - Images worden gepusht naar AWS ECR |  |
| REQ-13 - Buildserver als Swarm Manager |  |
| REQ-14 - ASG-instances als Swarm Workers |  |

### Assignment 3: Cloud Orchestration

> Bestanden in [Assignment 3 - Orchestration/](Assignment%203%20-%20Orchestration/)

Bouw voort op Assignments 1 en 2. Gebruik Terraform en Ansible in een multi-cloud architectuur.

**Deliverables:** Templates en scripts, plus een rapport (~3 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

| Requirement | Bewijs |
|---|---|
| REQ-15 - AWS-resources uitgerold met Terraform |  |
| REQ-16 - Applicatie uitgerold op GCP via Terraform |  |
| REQ-17 - Gebruikers bereiken applicatie via één extern IP-adres |  |
| REQ-18 - Docker-images gehost op Artifact Registry |  |
| REQ-19 - Kubernetes-cluster op GCP |  |
| REQ-20 - Kubernetes-cluster: Master met 5 replica's |  |
| REQ-21 - Ansible configureert het Kubernetes-cluster |  |
| REQ-22 - Ansible verzamelt logbestanden |  |

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

### CloudFormation Linter

Het lesmateriaal van Saxion verwijst naar de extensie [cform-VSCode](https://github.com/aws-scripting-guy/cform-VSCode) van aws-scripting-guy. **Installeer die niet.** De extensie is sinds 2022 niet meer onderhouden, herkent moderne CloudFormation-syntax niet en geeft foutieve of ontbrekende feedback.

Gebruik in plaats daarvan de officieel ondersteunde **CloudFormation Linter** (`kddejong.vscode-cfn-lint`). Deze extensie wordt actief onderhouden door AWS, kent alle huidige resource-typen en intrinsieke functies (`!Ref`, `!Sub`, `!GetAtt`, enzovoort), en toont fouten direct in de editor.

**Stap 1: extensies installeren**

Bij het openen van deze repo toont VS Code automatisch een popup om de aanbevolen extensies te installeren. Klik op *Install*. Dit installeert:

- `kddejong.vscode-cfn-lint` (CloudFormation Linter)
- `redhat.vscode-yaml` (YAML-ondersteuning, vereist door de linter)

**Stap 2: cfn-lint installeren**

De extensie werkt samen met `cfn-lint`, dat je apart installeert via pip:

```bash
pip install -r requirements.txt
```

Verifieer daarna:

```bash
cfn-lint --version
```

Herstart VS Code als de extensie cfn-lint na installatie niet automatisch detecteert.

---

## AWS CLI installeren

De opdrachten in deze module maken gebruik van de [AWS CLI](https://aws.amazon.com/cli/). Installeer deze eenmalig via onderstaande instructies.

<details>
<summary>Linux</summary>

```bash
# Arch
sudo pacman -S aws-cli-v2

# Fedora
sudo dnf install awscli2

# Debian
sudo apt install awscli
```

Verifieer de installatie:

```bash
aws --version
```

Verwachte uitvoer (versienummers kunnen afwijken):

```
aws-cli/2.x.x Python/3.x.x Linux/x86_64
```

Configureer daarna je AWS-credentials via `aws configure` (interactief, vraagt elk veld apart) of plak de volledige inhoud direct in `~/.aws/credentials` (sneller bij AWS Academy):

**Optie 1: via aws configure**

```bash
aws configure
```

Vul je Access Key ID, Secret Access Key, regio en uitvoerformaat in wanneer daarom gevraagd wordt.

**Optie 2: direct in het bestand plakken (aanbevolen bij AWS Academy)**

```bash
nano ~/.aws/credentials
```

Plak de volledige credentials zoals AWS Academy ze aanlevert:

```ini
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

> [!WARNING]
> Bij gebruik van **AWS Academy (Learner Lab)** worden alle drie de credentials (access key, secret key én session token) bij elke nieuwe sessie opnieuw gegenereerd. Er is geen persistentie omdat dit een tijdelijke studentomgeving is. Herhaal bovenstaande stap na elke nieuwe sessie.
>
> In een echte productieomgeving zijn de access key en secret key persistent en hoef je ze maar eenmalig in te stellen.

![AWS credentials instellen na nieuwe sessie](../assets/aws-credentials-instellen.avif)

</details>

<details>
<summary>Windows</summary>

Download en installeer via de [officiële MSI-installer](https://awscli.amazonaws.com/AWSCLIV2.msi), of via winget:

```powershell
winget install -e --id Amazon.AWSCLI
```

Herstart de terminal na de installatie zodat `aws` beschikbaar is.

Configureer daarna je AWS-credentials via `aws configure` (interactief, vraagt elk veld apart) of plak de volledige inhoud direct in `%USERPROFILE%\.aws\credentials` (sneller bij AWS Academy):

**Optie 1: via aws configure**

```powershell
aws configure
```

Vul je Access Key ID, Secret Access Key, regio en uitvoerformaat in wanneer daarom gevraagd wordt.

**Optie 2: direct in het bestand plakken (aanbevolen bij AWS Academy)**

Open `%USERPROFILE%\.aws\credentials` in Kladblok of een andere editor en plak de volledige credentials zoals AWS Academy ze aanlevert:

```ini
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

> [!WARNING]
> Bij gebruik van **AWS Academy (Learner Lab)** worden alle drie de credentials (access key, secret key én session token) bij elke nieuwe sessie opnieuw gegenereerd. Er is geen persistentie omdat dit een tijdelijke studentomgeving is. Herhaal bovenstaande stap na elke nieuwe sessie.
>
> In een echte productieomgeving zijn de access key en secret key persistent en hoef je ze maar eenmalig in te stellen.

![AWS credentials instellen na nieuwe sessie](../assets/aws-credentials-instellen.avif)

</details>
