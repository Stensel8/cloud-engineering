# Assignment 1 - AWS Basics

Korte bewijsreadme voor de deployment via [Deploy-CloudShirt.ps1](Deploy-CloudShirt.ps1).

## Resultaat

De deployment kan opnieuw worden uitgevoerd in AWS Academy door voor de Lambda de bestaande LabRole te gebruiken in plaats van zelf een IAM-role aan te maken.

## Bewijs

![Succesvolle deployment via script](Script%20van%20assignment%201%20toont%20succesvolle%20deployment.png)

![CloudShirt applicatie draait](Cloudshirt%20assignment%201%20draait..png)

![Aankoop doen in de CloudShirt-app](Het%20doen%20van%20een%20aankoop%20in%20de%20CloudShirt-app.png)

De eerste afbeelding toont het deployment-script dat alle CloudFormation-stacks succesvol aanmaakt. De tweede afbeelding laat de draaiende CloudShirt-applicatie zien. De derde afbeelding toont een aankoop in de winkelwagen.

## Stacks

- `cloudshirt-network`: VPC, subnets, security groups
- `cloudshirt-efs`: gedeeld bestandssysteem voor logs (REQ-03)
- `cloudshirt-elk`: ELK Stack voor centrale logging (REQ-05, REQ-06)
- `cloudshirt-rds`: PostgreSQL 18 via Secrets Manager (REQ-04)
- `cloudshirt-s3`: S3-bucket voor RDS-exports en config-bestanden
- `cloudshirt-ec2`: twee webservers over twee AZ's (REQ-01)
- `cloudshirt-lb`: Application Load Balancer met sticky sessions (REQ-01)
- `cloudshirt-asg`: Auto Scaling Group met scheduled scaling (REQ-02)
- `cloudshirt-serverless`: Lambda export-monitor via EventBridge (REQ-08)
