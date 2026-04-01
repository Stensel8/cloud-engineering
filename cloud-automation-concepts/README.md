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
> De weekopdrachten (Week 1-4) zijn vervallen als inleverpunt. Ze staan nog in de repo als referentie en oefenmateriaal, maar het portfolio bestaat uit de drie onderstaande assignments.

### Assignment 1: AWS Basics

> Bestanden in [Assignment 1 - AWS Basics/](Assignment%201%20-%20AWS%20Basics/)

Bouw een AWS CloudFormation-oplossing die alle negen leerdoelen dekt en voldoet aan de eisen van klant **CloudShirt**, een startup uit Duitsland.

**Deliverables:** CloudFormation-templates en scripts, plus een rapport (~5 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

| Requirement | Omschrijving |
|-------------|-------------|
| REQ-01 | CloudShirt .NET-applicatie (of andere webapplicatie) is highly available over meerdere AZ's via één URL |
| REQ-02 | Automatisch schalen tijdens piekuren (18:00-20:00 Eastern) |
| REQ-03 | EFS wordt gebruikt voor dagelijkse opslag van applicatie-/webserverlogbestanden |
| REQ-04 | RDS-database ingericht via IaC |
| REQ-05 | Monitoringoplossing (ELK Stack v8.x of alternatief) ingericht via IaC |
| REQ-06 | *(Optioneel, meer punten)* Logs zichtbaar in Elastic Stack via FileBeat |
| REQ-07 | Scriptmatige export van de ordertabel naar een S3-bucket |
| REQ-08 | AWS serverless-applicatie aangemaakt, bij voorkeur nuttig in de eigen omgeving |

### Assignment 2: Docker in the Cloud

> Bestanden in [Assignment 2 - Docker/](Assignment%202%20-%20Docker/)

Bouw voort op Assignment 1. Dockeriseer de applicatie en richt een Docker-infrastructuur in op AWS.

**Deliverables:** Templates en scripts, plus een rapport (~3 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

| Requirement | Omschrijving |
|-------------|-------------|
| REQ-08 | De CloudShirt .NET-applicatie (of andere applicatie) is gedockeriseerd |
| REQ-09 | De applicatie wordt gebouwd op een aparte EC2-instance in het private subnet (Buildserver) |
| REQ-10 | Docker Compose wordt gebruikt om services te definiëren en uit te rollen |
| REQ-11 | Applicatie-images worden 's nachts gebouwd op de Buildserver (nightly builds) |
| REQ-12 | Applicatie-images worden gepusht naar AWS ECR of Docker Hub tijdens de nightly builds |
| REQ-13 | De Buildserver is geconfigureerd als master in een Docker Swarm-cluster |
| REQ-14 | De instances in de ASG zijn geconfigureerd als workers in het Docker Swarm-cluster |

### Assignment 3: Cloud Orchestration

> Bestanden in [Assignment 3 - Orchestration/](Assignment%203%20-%20Orchestration/)

Bouw voort op Assignments 1 en 2. Gebruik Terraform en Ansible in een multi-cloud architectuur.

**Deliverables:** Templates en scripts, plus een rapport (~3 pagina's) over leerdoelen, requirements, keuzes, uitrol en aanbevelingen.

| Requirement | Omschrijving |
|-------------|-------------|
| REQ-15 | AWS-resources worden uitgerold met Terraform |
| REQ-16 | Een applicatie wordt uitgerold op GCP of AWS via Terraform (Docker Compose en/of RDS mag worden gebruikt) |
| REQ-17 | Gebruikers bereiken de applicatie via één extern IP-adres |
| REQ-18 | Docker-images worden gehost op Artifact Registry of AWS ECR |
| REQ-19 | Een Kubernetes-cluster wordt op een geautomatiseerde manier uitgerold op GCP of AWS (GKE of AKS mag worden gebruikt) |
| REQ-20 | Het Kubernetes-cluster bestaat uit een Master die 5 replica's van de applicatie aanstuurt |
| REQ-21 | Ansible wordt gebruikt voor de configuratie van het Kubernetes-cluster |
| REQ-22 | Ansible wordt gebruikt om logbestanden op te halen van de applicatie op AWS of GCP |

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
