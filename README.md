[![PR Checks](https://github.com/Stensel8/cloud-engineering/actions/workflows/pr-checks.yml/badge.svg)](https://github.com/Stensel8/cloud-engineering/actions/workflows/pr-checks.yml)

> [!NOTE]
> Deze repository wordt primair in het **Nederlands** bijgehouden.

---

# Cloud Engineering

Deze repository wordt bijgehouden door [Sten Tijhuis](https://github.com/Stensel8) en [Wout Achterhuis](https://github.com/Hintenhaus04) en bevat de gedeelde modules van de HBO-specialisatie *Cloud Engineering* (Q3).

[![GitHub](https://img.shields.io/badge/GitHub-Stensel8%2Fcloud--engineering-181717?logo=github&logoColor=white)](https://github.com/Stensel8/cloud-engineering)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-web-services&logoColor=white)](https://aws.amazon.com/)

## Modules

| Module | EC | Kwartaal | Map |
|--------|-----|----------|-----|
| Cloud Automation Concepts | 5 EC | Q3 | [cloud-automation-concepts/](cloud-automation-concepts/) |
| Architecting the Cloud | 5 EC | Q3 | [architecting-the-cloud/](architecting-the-cloud/) |

> **Public Cloud Concepts** (5 EC, Q3) is een individuele module en staat in een aparte repository: [Stensel8/public-cloud-concepts](https://github.com/Stensel8/public-cloud-concepts).

## AWS CLI installeren

De opdrachten in deze repository maken gebruik van de [AWS CLI](https://aws.amazon.com/cli/). Installeer deze eenmalig via onderstaande instructies.

<details>
<summary>Linux (inclusief CachyOS / Arch-gebaseerd)</summary>

```bash
sudo pacman -S aws-cli-v2
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

**Optie 1 — via aws configure:**

```bash
aws configure
```

Vul je Access Key ID, Secret Access Key, regio en uitvoerformaat in wanneer daarom gevraagd wordt.

**Optie 2 — direct in het bestand plakken (aanbevolen bij AWS Academy):**

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

![AWS credentials instellen na nieuwe sessie](assets/aws-credentials-instellen.avif)

</details>

<details>
<summary>Windows</summary>

Download en installeer via de [officiële MSI-installer](https://awscli.amazonaws.com/AWSCLIV2.msi), of via winget:

```powershell
winget install -e --id Amazon.AWSCLI
```

Herstart de terminal na de installatie zodat `aws` beschikbaar is.

Configureer daarna je AWS-credentials via `aws configure` (interactief, vraagt elk veld apart) of plak de volledige inhoud direct in `%USERPROFILE%\.aws\credentials` (sneller bij AWS Academy):

**Optie 1 — via aws configure:**

```powershell
aws configure
```

Vul je Access Key ID, Secret Access Key, regio en uitvoerformaat in wanneer daarom gevraagd wordt.

**Optie 2 — direct in het bestand plakken (aanbevolen bij AWS Academy):**

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

![AWS credentials instellen na nieuwe sessie](assets/aws-credentials-instellen.avif)

</details>

---

## Afbeeldingen

Alle afbeeldingen in deze repository gebruiken het [AVIF](https://en.wikipedia.org/wiki/AVIF)-formaat: open, royalty-free en compacter dan PNG of JPEG bij gelijke kwaliteit.

Batch-converteer PNG/JPG screenshots naar AVIF (converteert en verwijdert originelen):

```bash
find . -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | while read -r f; do avifenc -q 80 -s 6 "$f" "${f%.*}.avif" && rm "$f"; done
```

Installeer `avifenc` eerst via `sudo pacman -S libavif` (Arch/CachyOS) of `sudo apt install libavif-bin` (Debian/Ubuntu).

## Disclaimer

Dit is een lopend project voor educatieve doeleinden. Code, configuraties en documentatie kunnen gedurende de cursus nog veranderen.

---

*Laatst bijgewerkt: maart 2026*
