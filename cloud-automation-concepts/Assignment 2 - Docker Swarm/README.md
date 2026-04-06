# Assignment 2: Docker in the Cloud

## Over deze opdracht

Dit was degene die we tot nu toe het beste voor elkaar hebben gekregen. Dit zal ook waarschijnlijk de demo gaan worden.

De opdracht was om de applicatie te dockeriseren en in een Docker Swarm-cluster op AWS te draaien. Hiervoor hebben we een aparte variant van de applicatie gebruikt: [Stensel8/CloudShirt-Hugo](https://github.com/Stensel8/CloudShirt-Hugo). Dit is een lichtere versie die beter geschikt is voor containergebruik.

De hele infrastructuur rolt uit via één PowerShell-script. De Buildserver bouwt de Docker-image, pusht die naar ECR en beheert het Swarm-cluster. De worker-servers starten automatisch op als Swarm-worker en koppelen aan de manager.

## Leerdoelen

Het leerdoel was: een bestaande applicatie dockeriseren en op een geautomatiseerde manier uitrollen op een cloudinfrastructuur.

**Behaald.** De applicatie draait als Docker-container in een Swarm-cluster, uitgerold via CloudFormation-templates en een deploy-script. De Buildserver doet nachtelijk automatisch een nieuwe build en pusht die naar ECR.

## Requirements

| Requirement | Status | Bewijs |
|---|---|---|
| REQ-08: Applicatie is gedockeriseerd | Behaald | `Dockerfile` in Stensel8/CloudShirt-Hugo |
| REQ-09: Applicatie gebouwd op een Buildserver in het private subnet | Behaald | `cloudshirt-swarm-buildserver.yml`: de Buildserver heeft geen publiek IP en is alleen intern bereikbaar |
| REQ-10: Docker Compose voor services en uitrol | Behaald | `docker-compose.yml` in Stensel8/CloudShirt-Hugo |
| REQ-11: Nachtelijke builds op de Buildserver | Behaald | Cronjob om 02:00 UTC voert `nightly-build.sh` uit |
| REQ-12: Images worden gepusht naar ECR tijdens de nachtelijke build | Behaald | Buildserver pusht de image naar de ECR-repository na elke succesvolle build |
| REQ-13: Buildserver als Swarm Manager | Behaald | Buildserver initialiseert de Swarm en slaat het join-token op in SSM |
| REQ-14: ASG-instances als Swarm Workers | Behaald | Worker-instances halen het join-token op uit SSM en sluiten zich automatisch aan bij de Swarm |

## Keuzes

De Buildserver staat in het private subnet en heeft geen publiek IP-adres. Je kunt er alleen via SSM Session Manager bij. Dit is veiliger dan een publieke server.

Het Swarm-join-token slaan we op in SSM Parameter Store. Zo hoeft het token niet hardcoded in de templates te staan en kunnen worker-servers het veilig ophalen bij het opstarten.

ECR is de image-registry, gekoppeld aan dezelfde AWS-omgeving. Dat scheelt externe credentials en de images staan dicht bij de servers die ze ophalen.

We gebruiken de `LabInstanceProfile` van AWS Academy voor de IAM-rechten. Eigen rollen aanmaken is niet mogelijk in de leeromgeving, maar de bestaande rol heeft genoeg rechten voor ECR, SSM en de load balancer.

## Uitrollen

Je hebt nodig: AWS CLI v2 en PowerShell 7+.

Maak een `aws.txt`-bestand aan met de credentials van AWS Academy:

```
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

> Dit bestand staat in `.gitignore` en mag nooit gecommit worden.

Start het deploy-script:

```powershell
.\Deploy-DockerSwarm.ps1
```

Het script rolt de stacks uit in volgorde: netwerk, ECR, Buildserver, load balancer en workers. Na afloop toont het de URL van de load balancer.

Wacht 2 tot 5 minuten totdat de workers de Swarm zijn ingetreden en de health checks groen worden.

Je kunt de status checken via SSM Session Manager op de Buildserver:

```bash
docker node ls
docker service ls
docker service ps cloudshirt_web
```

Opruimen:

```powershell
.\Remove-DockerSwarm.ps1
```

## Demo

<video src="Demo.webm" controls width="100%"></video>

## Bewijs

![CloudFormation stacks](Bewijs%20van%20uitvoering%20-%20Cloudformation%20stacks.avif)

De CloudFormation-stacks zijn succesvol aangemaakt in AWS.

![Docker applicatie](Bewijs%20van%20uitvoering%20-%20Docker%20applicatie.avif)

De CloudShirt-Hugo applicatie draait als Docker Swarm-service.

## Stacks

| Stack | Wat doet het |
|---|---|
| `cloudshirt-swarm-network` | Netwerk: VPC, subnetten, NAT, security groups |
| `cloudshirt-swarm-ecr` | ECR-repository voor Docker-images |
| `cloudshirt-swarm-buildserver` | Buildserver als Swarm Manager, doet nachtelijke builds |
| `cloudshirt-swarm-alb` | Load balancer met health checks |
| `cloudshirt-swarm-asg` | Auto Scaling Group als Swarm Workers |

## Aanbevelingen

Voor een productieomgeving gaat mijn voorkeur uit naar Kubernetes, bijvoorbeeld via Amazon EKS. Dat biedt meer mogelijkheden voor schaalbaarheid, beheer en ecosysteem-integraties.

HTTPS staat nu niet aan op de load balancer. In productie zou je een certificaat koppelen.

Als een nachtelijke build mislukt, is er nu geen melding. Een notificatie via e-mail of Slack bij een mislukte build zou handig zijn.
