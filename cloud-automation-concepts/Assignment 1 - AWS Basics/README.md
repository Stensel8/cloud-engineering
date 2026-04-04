# Assignment 1 - AWS Basics

Korte bewijsreadme voor de deployment via [Deploy-CloudShirt.ps1](Deploy-CloudShirt.ps1).

## Resultaat

De deployment kan opnieuw worden uitgevoerd in AWS Academy door voor de Lambda de bestaande LabRole te gebruiken in plaats van zelf een IAM-role aan te maken.

## Bewijs uit de run

- `cloudshirt-network` aangemaakt
- `cloudshirt-efs` aangemaakt
- `cloudshirt-elk` aangemaakt
- `cloudshirt-rds` aangemaakt
- `cloudshirt-ec2` aangemaakt
- `cloudshirt-s3` aangemaakt
- `cloudshirt-lb` aangemaakt
- `cloudshirt-asg` aangemaakt
- `cloudshirt-serverless` gebruikt de bestaande LabRole-ARN uit de omgeving

## Werkwijze

De Lambda in `cloudshirt-serverless.yml` gebruikt een bestaande IAM-role via `LambdaRoleArn`. In AWS Academy wordt die standaard ingevuld met `arn:aws:iam::<account-id>:role/LabRole`, zodat CloudFormation geen nieuwe role hoeft te creëren.
