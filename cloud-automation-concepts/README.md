# Cloud Automation Concepts

> Schoolopdracht - Cloud Engineering-specialisatie, Jaar 3, Q3 (5 EC)
> Duo: [Stensel8](https://github.com/Stensel8) & [Hintenhaus04](https://github.com/Hintenhaus04)

## Over deze module

Geautomatiseerde productie van infrastructuur (zero-touch deployment) met Infrastructure as Code op **AWS**. Onderwerpen zijn onder andere containerisatie, orkestratie (Kubernetes) en configuratiebeheer (Terraform, Ansible, CloudFormation) in publieke, hybride en multi-cloud omgevingen.

## Leerdoelen

- (Onderling afhankelijke) resources op een geautomatiseerde manier inrichten in AWS
- Een bestaande applicatie containeriseren en op een geautomatiseerde manier uitrollen op een cloudinfrastructuur
- Orkestratie- en configuratietools gebruiken (Kubernetes, Terraform, Ansible) in een multi-cloud omgeving

## Cursusstructuur

| Week | Onderwerp | Map |
|------|-----------|-----|
| Week 1 | Introductie & CloudFormation | [Week 1/](Week%201/) |

Meer weken worden toegevoegd naarmate de cursus vordert.

---

## VS Code instellen

### CloudFormation Linter

Het lesmateriaal van Saxion verwijst naar de extensie [cform-VSCode](https://github.com/aws-scripting-guy/cform-VSCode) van aws-scripting-guy. **Installeer die niet.** De extensie is sinds 2017 niet meer onderhouden, herkent moderne CloudFormation-syntax niet en geeft foutieve of ontbrekende feedback.

Gebruik in plaats daarvan de officieel ondersteunde **CloudFormation Linter** (`kddejong.vscode-cfn-lint`). Deze extensie wordt actief onderhouden door AWS, kent alle huidige resource-typen en intrinsieke functies (`!Ref`, `!Sub`, `!GetAtt`, enzovoort), en toont fouten direct in de editor.

**Stap 1 — Extensies installeren**

Bij het openen van deze repo toont VS Code automatisch een popup om de aanbevolen extensies te installeren. Klik op *Install*. Dit installeert:

- `kddejong.vscode-cfn-lint` — CloudFormation Linter
- `redhat.vscode-yaml` — YAML-ondersteuning (vereist door de linter)

**Stap 2 — cfn-lint installeren**

De extensie heeft het `cfn-lint` commando-regelprogramma nodig. Installeer het via pip:

```bash
pip install -r requirements.txt
```

Verifieer daarna:

```bash
cfn-lint --version
```

Herstart VS Code als de extensie cfn-lint nog niet automatisch oppikt.

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
