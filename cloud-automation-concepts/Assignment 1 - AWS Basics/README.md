# Assignment 1: AWS Basics

## Leerdoelen

De module heeft de volgende leerdoelen geformuleerd:

- (Onderling afhankelijke) resources op een geautomatiseerde manier inrichten in AWS.

**Behaald.** Alle AWS-resources zijn ingericht via CloudFormation-templates die via een PowerShell-script in de juiste volgorde worden uitgerold. Stacks importeren elkaars outputs via `!ImportValue`, waardoor de afhankelijkheden expliciet en reproduceerbaar zijn.

## Requirements

| Requirement | Status | Bewijs |
|---|---|---|
| REQ-01: High availability over meerdere AZ's via een URL | Behaald | `cloudshirt-ec2.yml` (twee instances over AZ-a en AZ-b), `cloudshirt-loadbalancer.yml` (ALB met sticky sessions) |
| REQ-02: Autoscaling tijdens piekuren (18:00-20:00 Eastern) | Behaald | `cloudshirt-asg.yml` (scheduled scaling: scale-out 18:00, scale-in 20:30 ET) |
| REQ-03: EFS voor dagelijkse opslag van webserverlogs | Behaald | `cloudshirt-efs.yml` (EFS mount op `/mnt/efs/logs`, nginx-logs worden hier naartoe geschreven) |
| REQ-04: RDS via IaC | Behaald | `cloudshirt-rds.yml` (PostgreSQL 16 via Secrets Manager, multi-AZ subnet group) |
| REQ-05: Monitoringoplossing (ELK) via IaC | Behaald | `cloudshirt-elk.yml` (Elasticsearch + Logstash + Kibana op één EC2-instance) |
| REQ-06: Logs zichtbaar in Elastic Stack via Filebeat | Behaald | Filebeat-configuratie in `config/filebeat-system.yml`, geinstalleerd via UserData in `cloudshirt-ec2.yml` |
| REQ-07: Scriptmatige export ordertabel naar S3 | Behaald | `export-orders.sh` (psql-dump, dagelijks via cron om 02:00) |
| REQ-08: AWS serverless-applicatie | Behaald | `cloudshirt-serverless.yml` (Lambda + EventBridge-regel, controleert of S3-export aanwezig is en stuurt SNS-notificatie) |

## Belangrijkste keuzes

**CloudFormation als IaC-tool.** Gekozen omdat de opdracht expliciet AWS-kennis vereist en CloudFormation native in AWS is geintegreerd. Geen extra tooling nodig.

**Deployment via PowerShell-script (`Deploy-CloudShirt.ps1`).** Het script detecteert automatisch of een stack al bestaat en doet dan een update in plaats van een nieuwe aanmaak. Stacks in `ROLLBACK_COMPLETE` worden automatisch verwijderd en opnieuw aangemaakt. Zo is het script volledig idempotent.

**Config-bestanden in S3.** Nginx-configuratie, Filebeat-config en het systemd-unit-bestand staan als losse bestanden in Git onder `config/`. Het deploy-script uploadt ze naar S3; de EC2-instances halen ze op via `aws s3 cp` in hun UserData. Dit voorkomt heredoc-problemen in YAML en maakt de configuratie onafhankelijk van de templategrootte.

**ELK op een aparte EC2-instance.** ELK is resource-intensief. Door het op een los instance te draaien, heeft de webserver geen last van het resource-gebruik van Elasticsearch en Logstash.

**LabRole voor Lambda.** AWS Academy laat studenten geen nieuwe IAM-rollen aanmaken. De bestaande `LabRole` beschikt over de benodigde S3- en SNS-rechten en wordt als parameter meegegeven aan het script.

**Secrets Manager voor de database-wachtwoorden.** RDS-wachtwoorden worden niet als plaintext in de template of UserData opgeslagen, maar als een Secrets Manager-secret. EC2-instances halen het wachtwoord op via de AWS SDK bij de eerste start.

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
.\Deploy-CloudShirt.ps1
```

Of met een vooraf ingestelde S3-bucketnaam:
```powershell
.\Deploy-CloudShirt.ps1 -BucketName "mijn-bucket-naam"
```

Het script voert de volgende stappen uit:

1. Controleert of AWS CLI aanwezig is.
2. Leest credentials uit `aws.txt` en valideert ze via STS.
3. Vraagt om de S3-bucketnaam (of gebruikt een standaardnaam op basis van het account-ID).
4. Deployt de stacks in de juiste volgorde: netwerk, EFS/ELK/RDS/S3, EC2, load balancer, ASG en Lambda.
5. Uploadt config-bestanden en scripts naar S3.
6. Toont de ALB-URL, target health en Lambda-naam na afloop.

**Na de deployment:**

Wacht 15-20 minuten totdat de EC2-instances de .NET-applicatie hebben gecompileerd en gestart. Open daarna de ALB-URL in een browser.

**Omgeving opruimen:**
```powershell
.\Remove-CloudShirt.ps1
```

## Demo

<video src="Demo.webm" controls width="100%"></video>

## Bewijs

![Succesvolle deployment via script](Script%20van%20assignment%201%20toont%20succesvolle%20deployment.png)

Het deployment-script maakt alle CloudFormation-stacks succesvol aan en toont de ALB-URL.

![CloudShirt applicatie draait](Cloudshirt%20assignment%201%20draait..png)

De CloudShirt-applicatie is bereikbaar via de Load Balancer.

![Aankoop doen in de CloudShirt-app](Het%20doen%20van%20een%20aankoop%20in%20de%20CloudShirt-app.png)

Een aankoop wordt afgerond in de winkelwagen.

## Stacks

| Stack | Inhoud |
|---|---|
| `cloudshirt-network` | VPC, subnets, internet gateway, NAT gateway, security groups |
| `cloudshirt-efs` | Elastic File System voor gedeelde nginx-logs (REQ-03) |
| `cloudshirt-elk` | ELK Stack v8.x: Elasticsearch, Logstash, Kibana (REQ-05) |
| `cloudshirt-rds` | PostgreSQL 16 via Secrets Manager (REQ-04) |
| `cloudshirt-s3` | S3-bucket voor RDS-exports en config-bestanden |
| `cloudshirt-ec2` | Twee webservers in AZ-a en AZ-b met Filebeat (REQ-01, REQ-06) |
| `cloudshirt-lb` | Application Load Balancer met sticky sessions (REQ-01) |
| `cloudshirt-asg` | Auto Scaling Group met scheduled scaling (REQ-02) |
| `cloudshirt-serverless` | Lambda export-monitor via EventBridge (REQ-08) |

## Aanbevelingen

**HTTPS aanzetten.** Op dit moment draait de applicatie over HTTP. In een productieomgeving wordt een ACM-certificaat aan de ALB gekoppeld en wordt HTTP naar HTTPS geredirect.

**ELK vervangen door CloudWatch + OpenSearch Serverless.** De huidige ELK-stack draait op een losse EC2-instance met handmatig beheer. CloudWatch Logs met een OpenSearch Serverless-domain is volledig beheerd, schaalt automatisch en vereist geen onderhoud.

**Secrets Manager roteren.** De database-wachtwoorden in Secrets Manager worden nu niet automatisch geroteerd. In productie wordt automatische rotatie ingeschakeld via een Lambda-rotator.

**ALB access logs naar S3.** ALB-logs zijn nu niet opgeslagen. In productie worden access logs naar S3 geschreven voor auditing en troubleshooting.

**Aparte staging-omgeving.** Er is nu geen staging-omgeving. Voor een productieomgeving worden twee aparte CloudFormation-stacks (staging en productie) ingericht met hetzelfde deploy-script maar andere parameterwaardes.
