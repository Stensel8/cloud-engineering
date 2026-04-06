# Assignment 2: Docker in the Cloud

## Leerdoelen

De module heeft de volgende leerdoelen geformuleerd:

- Een bestaande applicatie containeriseren en op een geautomatiseerde manier uitrollen op een cloudinfrastructuur.

**Behaald.** De CloudShirt-Hugo applicatie is gedockeriseerd via een meertraps Dockerfile. De infrastructuur (netwerk, ECR, buildserver, ALB en worker-instances) wordt volledig via CloudFormation uitgerold met een PowerShell-script. De buildserver initialiseert Docker Swarm, bouwt de image en pusht die naar ECR. Worker-instances sluiten zich automatisch aan als Swarm-workers via een join-token uit SSM.

## Requirements

| Requirement | Status | Bewijs |
|---|---|---|
| REQ-08: Applicatie is gedockeriseerd | Behaald | `Dockerfile` in Stensel8/Cloudshirt-Hugo |
| REQ-09: Applicatie gebouwd op een Buildserver in het private subnet | Behaald | `cloudshirt-swarm-buildserver.yml` (private subnet, geen publiek IP) |
| REQ-10: Docker Compose voor services en uitrol | Behaald | `docker-compose.yml` in Stensel8/Cloudshirt-Hugo |
| REQ-11: Nightly builds op de Buildserver | Behaald | Cronjob om 02:00 UTC in `cloudshirt-swarm-buildserver.yml` voert `nightly-build.sh` uit |
| REQ-12: Images worden gepusht naar AWS ECR | Behaald | Buildserver pusht image naar ECR via `docker push` in de nightly-build |
| REQ-13: Buildserver als Swarm Manager | Behaald | Buildserver voert `docker swarm init` uit en slaat join-token op in SSM Parameter Store |
| REQ-14: ASG-instances als Swarm Workers | Behaald | `cloudshirt-swarm-asg.yml` (worker-instances halen join-token op uit SSM en voeren `docker swarm join` uit) |

## Belangrijkste keuzes

**Docker Swarm in plaats van Kubernetes.** De opdracht vraagt om een Swarm-opstelling. Swarm is eenvoudiger te beheren dan Kubernetes voor een kleine opstelling: minder configuratie, geen aparte control plane-nodes en native ondersteuning in Docker.

**Buildserver in het private subnet.** De buildserver heeft geen publiek IP-adres. Beheer gaat via SSM Session Manager. Dit verkleint het aanvalsoppervlak.

**SSM Parameter Store voor het join-token.** Het Docker Swarm-join-token wordt na `docker swarm init` in SSM opgeslagen. Worker-instances halen het token op via de AWS SDK. Zo wordt het token nooit in plaintext in de template of userdata geschreven.

**ECR als image-registry.** Gekozen omdat ECR native in AWS is geintegreerd, geen externe credentials nodig heeft voor EC2-instances met de juiste IAM-rol, en de images in dezelfde regio staan als de workers (lage latency bij pulls).

**LabInstanceProfile voor IAM.** AWS Academy staat geen aanmaak van nieuwe IAM-rollen toe. De vooraf aangemaakte `LabInstanceProfile` beschikt over voldoende rechten voor ECR, SSM en CloudWatch.

**ALB voor het externe eindpunt.** Een Application Load Balancer verdeelt verkeer over de Swarm-workers. Health checks op `/healthz` zorgen ervoor dat alleen gezonde instances verkeer ontvangen.

**Deployment via PowerShell-script.** Hetzelfde patroon als Assignment 1: het script detecteert bestaande stacks, werkt ze bij of maakt ze opnieuw aan, en wacht op voltooiing voordat de volgende stap start.

## Uitrol

**Vereisten:**
- AWS CLI v2
- PowerShell 7+
- Een `aws.txt`-bestand in de assignment-map (zie formaat hieronder)

**Formaat `aws.txt`:**
```
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

> Dit bestand staat in `.gitignore` en mag nooit gecommit worden.

**Deployment uitvoeren:**
```powershell
.\Deploy-DockerSwarm.ps1
```

Of met een vooraf ingesteld key pair (optioneel, SSH):
```powershell
.\Deploy-DockerSwarm.ps1 -KeyName "mijn-keypair"
```

Het script voert de volgende stappen uit in volgorde:

1. Netwerk: VPC, subnetten, NAT-gateway, security groups (`cloudshirt-swarm-network`).
2. ECR: Docker image-registry (`cloudshirt-swarm-ecr`).
3. Buildserver: Swarm Manager in het private subnet, initialiseert Swarm en voert de eerste build uit (`cloudshirt-swarm-buildserver`).
4. Load Balancer: ALB met health checks (`cloudshirt-swarm-alb`).
5. Workers: Auto Scaling Group die join-token uit SSM ophaalt en als Swarm-worker start (`cloudshirt-swarm-asg`).

**Na de deployment:**

Wacht 2-5 minuten totdat de worker-instances de Swarm zijn ingetreden en de ALB-health checks groen worden. Controleer de Swarm-status via SSM:

```bash
docker node ls
docker service ls
docker service ps cloudshirt_web
```

**Omgeving opruimen:**
```powershell
.\Remove-DockerSwarm.ps1
```

## Bewijs

![CloudFormation stacks](Bewijs%20van%20uitvoering%20-%20Cloudformation%20stacks.png)

De CloudFormation-stacks zijn succesvol aangemaakt in AWS.

![Docker applicatie](Bewijs%20van%20uitvoering%20-%20Docker%20applicatie.png)

De CloudShirt-Hugo applicatie draait als Docker Swarm-service bovenop de worker-instances.

## Stacks

| Stack | Inhoud |
|---|---|
| `cloudshirt-swarm-network` | VPC, subnetten, NAT-gateway, security groups |
| `cloudshirt-swarm-ecr` | ECR-repository voor Docker-images |
| `cloudshirt-swarm-buildserver` | EC2-instance als Swarm Manager, nightly build, SSM-join-token |
| `cloudshirt-swarm-alb` | Application Load Balancer met health checks |
| `cloudshirt-swarm-asg` | Auto Scaling Group als Swarm Workers |

## Aanbevelingen

**Gescheiden build- en runtime-omgevingen.** Nu bouwt de buildserver ook de image voor zichzelf. In productie is een aparte CI/CD-pipeline (AWS CodePipeline of GitHub Actions) verstandiger zodat de buildserver geen productieverkeer verwerkt.

**Image-scanning in ECR inschakelen.** ECR ondersteunt automatische vulnerability scanning via Amazon Inspector. Dit is nu niet ingeschakeld. In productie wordt `scanOnPush: true` ingesteld op de repository.

**Swarm vervangen door ECS of EKS.** Docker Swarm wordt niet meer actief ontwikkeld. Voor nieuwe productiesystemen is Amazon ECS (beheerd, eenvoudig) of EKS (Kubernetes, meer controle) een betere keuze.

**HTTPS op de ALB.** Verkeer tussen client en ALB gaat nu over HTTP. In productie wordt een ACM-certificaat gekoppeld en wordt HTTP naar HTTPS geredirect.

**Nightly build-notificaties.** Als de nightly build mislukt, is er nu geen melding. In productie wordt een CloudWatch Alarm of SNS-notificatie op de cron-jobuitvoer ingesteld.
