# Assignment 1 - AWS Basics

Bewijs van uitvoering voor de deployment via [Deploy-CloudShirt.ps1](Deploy-CloudShirt.ps1).

## Resultaat

Alle CloudFormation-stacks zijn succesvol uitgerold in AWS Academy. De applicatie is bereikbaar via de ALB-URL en verwerkt bestellingen via RDS PostgreSQL. De Lambda-export-monitor draait op schema via EventBridge.

De deployment kan opnieuw worden uitgevoerd door voor de Lambda de bestaande `LabRole` te gebruiken in plaats van zelf een IAM-role aan te maken.

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

- `cloudshirt-network`: VPC, subnets, security groups
- `cloudshirt-efs`: gedeeld bestandssysteem voor logs (REQ-03)
- `cloudshirt-elk`: ELK Stack voor centrale logging (REQ-05, REQ-06)
- `cloudshirt-rds`: PostgreSQL 18 via Secrets Manager (REQ-04)
- `cloudshirt-s3`: S3-bucket voor RDS-exports en config-bestanden
- `cloudshirt-ec2`: twee webservers over twee AZ's (REQ-01)
- `cloudshirt-lb`: Application Load Balancer met sticky sessions (REQ-01)
- `cloudshirt-asg`: Auto Scaling Group met scheduled scaling (REQ-02)
- `cloudshirt-serverless`: Lambda export-monitor via EventBridge (REQ-08)
