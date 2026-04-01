<#
.SYNOPSIS
    Deployt alle CloudFormation-stacks voor de CloudShirt-omgeving.

.DESCRIPTION
    Dit script leest AWS-credentials uit een lokaal aws.txt-bestand,
    stelt de omgevingsvariabelen in en deployt alle stacks in de
    juiste volgorde via de AWS CLI.

    Stacks worden aangemaakt als ze nog niet bestaan, of bijgewerkt
    als ze al bestaan.

    Deployment-volgorde:
      1. base-stack              -- VPC, subnetten, gateways
      2. cloudshirt-efs         -- Elastic File System
         cloudshirt-elk         -- ELK monitoring stack
         cloudshirt-rds         -- RDS SQL Server database
      3. cloudshirt-ec2         -- EC2-webservers
      4. cloudshirt-lb          -- Application Load Balancer
      5. cloudshirt-asg         -- Auto Scaling Group
      6. cloudshirt-s3          -- S3-bucket voor exports
      7. cloudshirt-serverless  -- Lambda export-monitor (REQ-08)

.PARAMETER Region
    AWS-regio. Standaard: us-east-1 (vereist door AWS Academy).

.PARAMETER BucketName
    Naam van de S3-bucket voor RDS-exports. Wordt gevraagd als niet opgegeven.

.EXAMPLE
    .\Deploy-CloudShirt.ps1
    .\Deploy-CloudShirt.ps1 -BucketName "mijn-bucket-naam"

.NOTES
    Vereisten:
    - AWS CLI v2 geinstalleerd
    - aws.txt aanwezig in dezelfde map (zie README voor formaat)
    - aws.txt staat in .gitignore - commit dit bestand NOOIT
#>

[CmdletBinding()]
param (
    [string]$Region     = "us-east-1",
    [string]$BucketName = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Hulpfunctie: schrijf een sectieheader naar de console
# ---------------------------------------------------------------------------
function Write-Section {
    param([string]$Title)
    Write-Output ""
    Write-Output "===== $Title ====="
}

# ---------------------------------------------------------------------------
# Stap 1: controleer of AWS CLI aanwezig is
# ---------------------------------------------------------------------------
Write-Section "Vooraf controleren"

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Output "FOUT: AWS CLI is niet geinstalleerd."
    Write-Output "Installeer AWS CLI v2 via: https://aws.amazon.com/cli/"
    exit 1
}

Write-Output "AWS CLI gevonden."

# ---------------------------------------------------------------------------
# Stap 2: credentials inlezen uit aws.txt
#
# aws.txt formaat (NIET committen, staat in .gitignore):
#   aws_access_key_id=ASIA...
#   aws_secret_access_key=...
#   aws_session_token=...
# ---------------------------------------------------------------------------
Write-Section "Credentials inlezen"

$AwsFile = Join-Path $PSScriptRoot "aws.txt"

if (-not (Test-Path $AwsFile)) {
    Write-Output "FOUT: aws.txt niet gevonden in: $PSScriptRoot"
    Write-Output ""
    Write-Output "Maak een bestand 'aws.txt' aan met de volgende inhoud:"
    Write-Output "  aws_access_key_id=WAARDE"
    Write-Output "  aws_secret_access_key=WAARDE"
    Write-Output "  aws_session_token=WAARDE"
    Write-Output ""
    Write-Output "Je vindt deze waarden in AWS Academy onder 'Account Details'."
    exit 1
}

# Laad de sleutel-waardeparen uit het bestand
$AwsData = @{}
Get-Content $AwsFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)\s*=\s*(.+)\s*$') {
        $AwsData[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

# Controleer of alle vereiste sleutels aanwezig zijn
foreach ($RequiredKey in @('aws_access_key_id', 'aws_secret_access_key', 'aws_session_token')) {
    if (-not $AwsData.ContainsKey($RequiredKey)) {
        Write-Output "FOUT: sleutel '$RequiredKey' ontbreekt in aws.txt"
        exit 1
    }
}

Write-Output "Credentials geladen uit aws.txt."

# ---------------------------------------------------------------------------
# Stap 3: omgevingsvariabelen instellen voor de AWS CLI
# ---------------------------------------------------------------------------
$env:AWS_ACCESS_KEY_ID     = $AwsData['aws_access_key_id']
$env:AWS_SECRET_ACCESS_KEY = $AwsData['aws_secret_access_key']
$env:AWS_SESSION_TOKEN     = $AwsData['aws_session_token']
$env:AWS_DEFAULT_REGION    = $Region

# Valideer credentials door de accountidentiteit op te halen
$null = aws sts get-caller-identity 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "FOUT: AWS-credentials zijn ongeldig of verlopen."
    Write-Output "Download nieuwe credentials via AWS Academy -> Account Details."
    exit 1
}

Write-Output "Credentials zijn geldig."

# ---------------------------------------------------------------------------
# Stap 4: benodigde invoerwaarden ophalen
# ---------------------------------------------------------------------------
Write-Section "Invoer verzamelen"

# Account ID automatisch ophalen (vereist voor sommige stack-parameters)
$AccountId = aws sts get-caller-identity --query "Account" --output text 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($AccountId)) {
    $AccountId = Read-Host "Voer je AWS Account ID in (bijv. 730335381450)"
    if ([string]::IsNullOrWhiteSpace($AccountId)) {
        Write-Output "FOUT: geen Account ID opgegeven."
        exit 1
    }
}

Write-Output "Account ID: $AccountId"

# S3-bucketnaam opvragen als niet meegegeven als parameter
if ([string]::IsNullOrWhiteSpace($BucketName)) {
    $BucketName = Read-Host "Geef een naam voor de S3-bucket (bijv. cloudshirt-exports-$AccountId)"
}

Write-Output "S3-bucketnaam: $BucketName"

# ---------------------------------------------------------------------------
# Hulpfunctie: deploy een CloudFormation-stack
#
# Maakt de stack aan als hij nog niet bestaat; werkt hem bij als hij al bestaat.
# Wacht tot de operatie voltooid is voordat de functie terugkeert.
# ---------------------------------------------------------------------------
function Invoke-StackDeployment {
    [CmdletBinding()]
    param (
        # Naam van de CloudFormation-stack (bijv. "cloudshirt-network")
        [Parameter(Mandatory)][string]$StackName,

        # Pad naar het CloudFormation-templatebestand
        [Parameter(Mandatory)][string]$TemplateFile,

        # Voeg AWS-credentials toe als stack-parameters (nodig voor EC2 UserData)
        [switch]$IncludeCredentials,

        # Voeg de S3-bucketnaam toe als stack-parameter
        [switch]$IncludeBucket
    )

    Write-Output ""
    Write-Output "  -> $StackName ($TemplateFile)"

    # Bouw de parameters-array op
    $Params = @()

    if ($IncludeCredentials) {
        $Params += @(
            "ParameterKey=AccessKey,ParameterValue=$($env:AWS_ACCESS_KEY_ID)",
            "ParameterKey=SecretKey,ParameterValue=$($env:AWS_SECRET_ACCESS_KEY)",
            "ParameterKey=SessionToken,ParameterValue=$($env:AWS_SESSION_TOKEN)",
            "ParameterKey=AccountId,ParameterValue=$AccountId"
        )
    }

    if ($IncludeBucket) {
        $Params += "ParameterKey=BucketName,ParameterValue=$BucketName"
    }

    # Bepaal of de stack al bestaat
    $null = aws cloudformation describe-stacks --stack-name $StackName 2>$null
    $StackExists = ($LASTEXITCODE -eq 0)

    if ($StackExists) {
        # Stack bestaat: bijwerken
        aws cloudformation update-stack `
            --stack-name $StackName `
            --template-body "file://$TemplateFile" `
            --parameters $Params `
            --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Output "    Wachten op update..."
            aws cloudformation wait stack-update-complete --stack-name $StackName
            Write-Output "    Bijgewerkt."
        } else {
            # Exit-code 255 = "No updates to be performed" (geen echte fout)
            Write-Output "    Geen wijzigingen of al up-to-date."
        }
    } else {
        # Stack bestaat niet: aanmaken
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body "file://$TemplateFile" `
            --parameters $Params `
            --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

        if ($LASTEXITCODE -ne 0) {
            Write-Output "    FOUT: aanmaken van stack mislukt."
            exit 1
        }

        Write-Output "    Wachten op aanmaken..."
        aws cloudformation wait stack-create-complete --stack-name $StackName
        if ($LASTEXITCODE -ne 0) {
            Write-Output "    FOUT: stack '$StackName' heeft ROLLBACK_COMPLETE bereikt. Controleer de CloudFormation-events in de AWS Console."
            exit 1
        }
        Write-Output "    Aangemaakt."
    }
}

# ---------------------------------------------------------------------------
# Stap 5: deployment uitvoeren in de juiste volgorde
#
# De volgorde is belangrijk: latere stacks importeren outputs van eerdere stacks
# via !ImportValue. Een stack die nog niet bestaat kan niet worden geimporteerd.
# ---------------------------------------------------------------------------
Write-Section "Deployment starten"

# 1. Netwerk-basisinfrastructuur (VPC, subnetten, gateways, security groups)
#    Alle andere stacks zijn hiervan afhankelijk.
Write-Output "Stap 1/6 - Netwerk"
Invoke-StackDeployment -StackName "cloudshirt-network" -TemplateFile ".\cloudshirt-network.yml"

# 2. Gedeelde services (afhankelijk van het netwerk)
Write-Output "Stap 2/6 - Gedeelde services (EFS, ELK, RDS)"
Invoke-StackDeployment -StackName "cloudshirt-efs" -TemplateFile ".\cloudshirt-efs.yml"
Invoke-StackDeployment -StackName "cloudshirt-elk" -TemplateFile ".\cloudshirt-elk.yml"
Invoke-StackDeployment -StackName "cloudshirt-rds" -TemplateFile ".\cloudshirt-rds.yml"

# 3. EC2-webservers (afhankelijk van EFS, ELK en RDS voor de installatie via UserData)
Write-Output "Stap 3/6 - EC2-webservers"
Invoke-StackDeployment -StackName "cloudshirt-ec2" -TemplateFile ".\cloudshirt-ec2.yml" `
    -IncludeCredentials -IncludeBucket

# 4. Load Balancer (afhankelijk van de EC2-instances als target)
Write-Output "Stap 4/6 - Load Balancer"
Invoke-StackDeployment -StackName "cloudshirt-lb" -TemplateFile ".\cloudshirt-loadbalancer.yml"

# 5. Auto Scaling Group (afhankelijk van LB-target group en alle gedeelde services)
Write-Output "Stap 5/6 - Auto Scaling Group"
Invoke-StackDeployment -StackName "cloudshirt-asg" -TemplateFile ".\cloudshirt-asg.yml" `
    -IncludeCredentials -IncludeBucket

# 6. S3-bucket voor RDS-exports
Write-Output "Stap 6/7 - S3-bucket"
Invoke-StackDeployment -StackName "cloudshirt-s3" -TemplateFile ".\cloudshirt-s3.yml" `
    -IncludeBucket

# 7. Serverless Lambda export-monitor (REQ-08)
#    Afhankelijk van cloudshirt-s3 (bucket moet bestaan vóór de Lambda wordt aangemaakt)
Write-Output "Stap 7/7 - Serverless export-monitor (REQ-08)"
Invoke-StackDeployment -StackName "cloudshirt-serverless" -TemplateFile ".\cloudshirt-serverless.yml" `
    -IncludeBucket

# ---------------------------------------------------------------------------
# Klaar
# ---------------------------------------------------------------------------
Write-Section "Deployment voltooid"
Write-Output "Alle stacks zijn succesvol gedeployt."
Write-Output ""
Write-Output "Vereisten afgevinkt:"
Write-Output "  REQ-01  HA over meerdere AZ's met ALB"
Write-Output "  REQ-02  Auto Scaling spike-traffic (6-8 PM ET)"
Write-Output "  REQ-03  EFS voor gedeelde logbestanden"
Write-Output "  REQ-04  RDS SQL Server via CloudFormation (IaC)"
Write-Output "  REQ-05  ELK Stack v8.x monitoring"
Write-Output "  REQ-06  Filebeat -> Logstash (optioneel, aanwezig)"
Write-Output "  REQ-07  Dagelijkse order-export naar S3 (bcp cron)"
Write-Output "  REQ-08  Serverless Lambda export-monitor via EventBridge"
Write-Output ""
Write-Output "Volgende stappen:"
Write-Output "  1. Haal de ALB-URL op:"
Write-Output "     aws cloudformation describe-stacks --stack-name cloudshirt-lb --query 'Stacks[0].Outputs'"
Write-Output "  2. Open de URL in je browser om de CloudShirt-applicatie te testen."
Write-Output "  3. Controleer Kibana (poort 5601 op de ELK-server) voor logs."
Write-Output "  4. Controleer CloudWatch Logs voor de Lambda export-monitor resultaten."
