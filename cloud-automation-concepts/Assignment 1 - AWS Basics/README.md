# Assignment 1: AWS Basics

## Over deze opdracht

De opdracht was om de CloudShirt-webshop volledig geautomatiseerd in AWS uit te rollen, met alles wat daarbij hoort: een database, opslag, monitoring, load balancing en schaalbaarheid.

Dat klinkt misschien eenvoudig, maar de originele CloudShirt-applicatie bleek helemaal niet klaar te zijn voor een AWS-omgeving. Er waren allerlei problemen: de applicatie kon niet connecten met een externe database, configuratie was hardcoded, en de deployment-documentatie was onvolledig.

Na veel uitzoekwerk hebben we besloten om een eigen fork te maken van de applicatie, onder [Stensel8/CloudShirt](https://github.com/Stensel8/CloudShirt). Daar hebben we de nodige aanpassingen en fixes in aangebracht, zodat de app wel goed uitgerold kon worden. Na heel wat gedoe is dit uiteindelijk gelukt, en dat is ook meteen het grootste leermoment van deze opdracht.

De hele AWS-infrastructuur is beschreven in CloudFormation-templates en wordt uitgerold via een PowerShell-script (`Deploy-CloudShirt.ps1`). Alles draait geautomatiseerd: je hoeft alleen de credentials neer te zetten en het script te starten.

## Leerdoelen

Het leerdoel was: resources op een geautomatiseerde manier inrichten in AWS, inclusief onderlinge afhankelijkheden.

**Behaald.** Alle stacks importeren elkaars outputs, zodat de volgorde van uitrollen gegarandeerd goed is. Het script wacht ook na elke stap op de bevestiging vanuit AWS voordat de volgende stap start.

## Requirements

| Requirement | Status | Bewijs |
|---|---|---|
| REQ-01: Hoge beschikbaarheid over meerdere zones via één URL | Behaald | Twee webservers in aparte beschikbaarheidszones, verdeeld via een load balancer met sticky sessions |
| REQ-02: Automatisch opschalen tijdens piektijden (18:00-20:00 Eastern) | Behaald | Auto Scaling Group met een geplande actie: opschalen om 18:00, terugschalen om 20:30 |
| REQ-03: EFS voor het dagelijks opslaan van webserverlogs | Behaald | EFS-bestandssysteem gekoppeld op de webservers; nginx schrijft logs naar dit gedeelde systeem |
| REQ-04: RDS-database via IaC | Behaald | PostgreSQL 18-database uitgerold via CloudFormation, wachtwoord opgeslagen in Secrets Manager |
| REQ-05: Monitoringoplossing (ELK Stack v8.x) via IaC | Behaald | Elasticsearch, Logstash en Kibana uitgerold via een aparte CloudFormation-stack |
| REQ-06: Logs zichtbaar in Kibana via Filebeat (optioneel) | Behaald | Filebeat geinstalleerd op de webservers; stuurt logs door naar Logstash |
| REQ-07: Scriptmatige export van de ordertabel naar S3 | Behaald | `export-orders.sh` doet dagelijks om 02:00 een export via psql naar de S3-bucket |
| REQ-08: Serverless applicatie in AWS | Behaald | Lambda-functie die via een timer controleert of de dagelijkse export aanwezig is en een melding stuurt als dat niet zo is |

## Keuzes

We hebben alles in CloudFormation geschreven omdat dat de standaard AWS-aanpak is en geen extra tools vereist. De stacks zijn opgedeeld per verantwoordelijkheid (netwerk, database, opslag, webservers, enzovoort), zodat je ze ook los van elkaar kunt bijwerken.

Configuratiebestanden voor nginx en Filebeat staan als losse bestanden in Git onder `config/`. Het deploy-script uploadt ze naar S3, waarna de servers ze bij het opstarten ophalen. Dit is overzichtelijker dan alles in de templates stoppen.

ELK draait op een aparte server omdat het anders te veel geheugen zou vreten van de webservers.

Voor de serverless Lambda hebben we de al bestaande `LabRole` van AWS Academy gebruikt, omdat je in de leeromgeving geen eigen IAM-rollen kunt aanmaken.

## Demo

<video src="Demo.webm" controls width="100%"></video>

## Bewijs

![Succesvolle deployment via script](Script%20van%20assignment%201%20toont%20succesvolle%20deployment.avif)

Het deploy-script rolt alle stacks succesvol uit en geeft de URL van de load balancer terug.

![CloudShirt applicatie draait](Cloudshirt%20assignment%201%20draait..avif)

De CloudShirt-applicatie is bereikbaar via de load balancer.

![Aankoop doen in de CloudShirt-app](Het%20doen%20van%20een%20aankoop%20in%20de%20CloudShirt-app.avif)

Een aankoop wordt afgerond in de winkelwagen.

## Uitrollen

Je hebt nodig: AWS CLI v2 en PowerShell 7+.

Maak een `aws.txt`-bestand aan in deze map met de credentials van AWS Academy:

```
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

> Dit bestand staat in `.gitignore` en mag nooit gecommit worden.

Start daarna het deploy-script:

```powershell
.\Deploy-CloudShirt.ps1
```

Het script vraagt om een naam voor de S3-bucket (of gebruikt een standaardnaam). Daarna rolt het alles automatisch uit in de juiste volgorde en uploadt het de configuratiebestanden naar S3.

Wacht na afloop 15 tot 20 minuten. De webservers bouwen de .NET-applicatie nog op de achtergrond. Daarna is de app bereikbaar via de URL die het script toont.

Opruimen:

```powershell
.\Remove-CloudShirt.ps1
```

## Stacks

| Stack | Wat doet het |
|---|---|
| `cloudshirt-network` | Netwerk: VPC, subnetten, gateways, security groups |
| `cloudshirt-efs` | Gedeeld bestandssysteem voor logs |
| `cloudshirt-elk` | Monitoring: Elasticsearch, Logstash en Kibana |
| `cloudshirt-rds` | PostgreSQL-database via Secrets Manager |
| `cloudshirt-s3` | S3-bucket voor exports en configuratiebestanden |
| `cloudshirt-ec2` | Twee webservers in aparte beschikbaarheidszones |
| `cloudshirt-lb` | Load balancer met sticky sessions |
| `cloudshirt-asg` | Auto Scaling Group met geplande opschaling |
| `cloudshirt-serverless` | Lambda die dagelijks controleert of de export is geslaagd |

## Aanbevelingen

HTTPS staat nu niet aan. In een echte productieomgeving zou je een certificaat aan de load balancer koppelen.

ELK vereist vrij veel handmatig beheer. Voor een productieomgeving zou je kijken naar een beheerde monitoringdienst zodat je dat onderhoud kwijt bent.

De database-wachtwoorden worden nu niet automatisch gewisseld. Dat is voor een schoolopdracht prima, maar in productie zou je automatische rotatie aanzetten.
