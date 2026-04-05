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
      1. cloudshirt-network     -- VPC, subnetten, gateways, security groups
      2. cloudshirt-efs         -- Elastic File System
         cloudshirt-elk         -- ELK monitoring stack
         cloudshirt-rds         -- RDS PostgreSQL database
      3. cloudshirt-ec2         -- EC2-webservers
      4. cloudshirt-s3          -- S3-bucket voor exports
      5. cloudshirt-lb          -- Application Load Balancer
      6. cloudshirt-asg         -- Auto Scaling Group
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

# S3-bucketnaam opvragen; standaard op account-ID gebaseerde naam zodat die uniek is
$DefaultBucketName = "cloudshirt-exports-$AccountId"
if ([string]::IsNullOrWhiteSpace($BucketName)) {
    $BucketName = Read-Host "Geef een naam voor de S3-bucket (Enter = $DefaultBucketName)"
    if ([string]::IsNullOrWhiteSpace($BucketName)) {
        $BucketName = $DefaultBucketName
    }
}

Write-Output "S3-bucketnaam: $BucketName"

# AWS Academy levert meestal een bestaande LabRole die de Lambda kan gebruiken
$LambdaRoleArn = "arn:aws:iam::${AccountId}:role/LabRole"
Write-Output "Lambda-role ARN: $LambdaRoleArn"

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
        [switch]$IncludeBucket,

        # Voeg de Lambda-role-ARN toe als stack-parameter
        [switch]$IncludeLambdaRole,

        # Voeg de ALB logbucket-parameter toe (alleen voor loadbalancer-stack)
        [switch]$IncludeLogBucket
    )

    Write-Output ""
    Write-Output "  -> $StackName ($TemplateFile)"

    # Los templatepad op relatief aan de scriptlocatie, niet aan de huidige shellmap
    $ResolvedTemplateFile = if ([System.IO.Path]::IsPathRooted($TemplateFile)) {
        $TemplateFile
    } else {
        Join-Path $PSScriptRoot $TemplateFile
    }

    if (-not (Test-Path $ResolvedTemplateFile)) {
        Write-Output "    FOUT: templatebestand niet gevonden: $ResolvedTemplateFile"
        exit 1
    }

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

    if ($IncludeLambdaRole) {
        $Params += "ParameterKey=LambdaRoleArn,ParameterValue=$LambdaRoleArn"
    }

    if ($IncludeLogBucket) {
        $Params += "ParameterKey=LogBucketName,ParameterValue=$BucketName"
    }

    # Bepaal of de stack al bestaat en in welke status hij staat
    $StackStatus = aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].StackStatus" --output text 2>$null
    $StackExists = ($LASTEXITCODE -eq 0)

    if ($StackExists -and $StackStatus -eq "ROLLBACK_COMPLETE") {
        Write-Output "    Stack staat in ROLLBACK_COMPLETE; verwijderen en opnieuw aanmaken..."

        aws cloudformation delete-stack --stack-name $StackName
        if ($LASTEXITCODE -ne 0) {
            Write-Output "    FOUT: verwijderen van rollback-stack '$StackName' mislukt."
            exit 1
        }

        aws cloudformation wait stack-delete-complete --stack-name $StackName
        if ($LASTEXITCODE -ne 0) {
            Write-Output "    FOUT: wachten op verwijderen van '$StackName' mislukt."
            exit 1
        }

        $StackExists = $false
    }

    if ($StackExists) {
        # Stack bestaat: bijwerken
        $UpdateOutput = aws cloudformation update-stack `
            --stack-name $StackName `
            --template-body "file://$ResolvedTemplateFile" `
            --parameters $Params `
            --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Output "    Wachten op update..."
            aws cloudformation wait stack-update-complete --stack-name $StackName
            Write-Output "    Bijgewerkt."
        } else {
            if ($UpdateOutput -match "No updates are to be performed") {
                Write-Output "    Geen wijzigingen of al up-to-date."
            } else {
                Write-Output "    FOUT: update van stack '$StackName' mislukt."
                Write-Output "    AWS melding: $UpdateOutput"
                exit 1
            }
        }
    } else {
        # Stack bestaat niet: aanmaken
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body "file://$ResolvedTemplateFile" `
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
Write-Output "Stap 1/7 - Netwerk"
Invoke-StackDeployment -StackName "cloudshirt-network" -TemplateFile ".\cloudshirt-network.yml"

# 2. Gedeelde services (afhankelijk van het netwerk)
#    S3 staat hier ook: de bucket moet bestaan voordat config-bestanden geupload worden
#    en voordat EC2 ze ophaalt via 'aws s3 cp'.
Write-Output "Stap 2/7 - Gedeelde services (EFS, ELK, RDS, S3)"
Invoke-StackDeployment -StackName "cloudshirt-efs" -TemplateFile ".\cloudshirt-efs.yml"
Invoke-StackDeployment -StackName "cloudshirt-elk" -TemplateFile ".\cloudshirt-elk.yml"
Invoke-StackDeployment -StackName "cloudshirt-rds" -TemplateFile ".\cloudshirt-rds.yml"
Invoke-StackDeployment -StackName "cloudshirt-s3"  -TemplateFile ".\cloudshirt-s3.yml" `
    -IncludeBucket

# 2b. Config-bestanden uploaden naar S3
#     EC2 en ASG-instances halen deze op via 'aws s3 cp' in hun UserData.
#     Zo staan ze als losse bestanden in Git, zonder heredoc-problemen in de YAML.
Write-Section "Config-bestanden uploaden naar S3"
$ConfigDir = Join-Path $PSScriptRoot "config"

foreach ($ConfigFile in @("nginx-cloudshirt.conf", "cloudshirt.service", "filebeat-system.yml", "elastic.repo")) {
    $LocalPath = Join-Path $ConfigDir $ConfigFile
    if (-not (Test-Path $LocalPath)) {
        Write-Output "FOUT: config-bestand niet gevonden: $LocalPath"
        exit 1
    }
    aws s3 cp $LocalPath "s3://$BucketName/config/$ConfigFile" --region $Region
    if ($LASTEXITCODE -ne 0) {
        Write-Output "FOUT: uploaden van '$ConfigFile' naar S3 mislukt."
        exit 1
    }
    Write-Output "  Geupload: config/$ConfigFile"
}

# 3. EC2-webservers (afhankelijk van EFS, ELK, RDS en S3 met config-bestanden)
Write-Output "Stap 3/7 - EC2-webservers"
Invoke-StackDeployment -StackName "cloudshirt-ec2" -TemplateFile ".\cloudshirt-ec2.yml" `
    -IncludeCredentials -IncludeBucket

# 4. Load Balancer (afhankelijk van de EC2-instances als target)
Write-Output "Stap 4/7 - Load Balancer"
Invoke-StackDeployment -StackName "cloudshirt-lb" -TemplateFile ".\cloudshirt-loadbalancer.yml"

# 5. Auto Scaling Group (afhankelijk van LB-target group en alle gedeelde services)
Write-Output "Stap 5/7 - Auto Scaling Group"
Invoke-StackDeployment -StackName "cloudshirt-asg" -TemplateFile ".\cloudshirt-asg.yml" `
    -IncludeCredentials -IncludeBucket

# 6. Lambda export-monitor (REQ-08): afhankelijk van cloudshirt-s3 (bucket moet bestaan)
Write-Output "Stap 6/7 - Lambda export-monitor"
Invoke-StackDeployment -StackName "cloudshirt-serverless" -TemplateFile ".\cloudshirt-serverless.yml" `
    -IncludeBucket -IncludeLambdaRole

# ---------------------------------------------------------------------------
# Klaar
# ---------------------------------------------------------------------------
Write-Section "Deployment voltooid"
Write-Output "Alle stacks zijn succesvol gedeployt."
Write-Output ""
Write-Output "Vereisten afgevinkt:"
Write-Output "  REQ-01  HA over meerdere AZ's met ALB"
Write-Output "  REQ-02  Auto Scaling spike-traffic (18-20 ET, scheduled)"
Write-Output "  REQ-03  EFS voor gedeelde logbestanden (nginx-logs)"
Write-Output "  REQ-04  RDS PostgreSQL 16 via CloudFormation (IaC)"
Write-Output "  REQ-05  ELK Stack v8.x (Elasticsearch, Logstash, Kibana)"
Write-Output "  REQ-06  Filebeat -> Logstash centrale logverwerking"
Write-Output "  REQ-07  Dagelijkse psql order-export naar S3 (cron 02:00)"
Write-Output "  REQ-08  Serverless Lambda export-monitor via EventBridge"
Write-Output ""

# ALB-URL ophalen en tonen
$AlbDns = aws cloudformation describe-stacks `
    --stack-name "cloudshirt-lb" `
    --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNSName'].OutputValue" `
    --output text 2>$null

if (-not [string]::IsNullOrWhiteSpace($AlbDns)) {
    Write-Output "CloudShirt applicatie-URL:"
    Write-Output "  http://$AlbDns"
} else {
    Write-Output "Haal de ALB-URL op via:"
    Write-Output "  aws cloudformation describe-stacks --stack-name cloudshirt-lb --query 'Stacks[0].Outputs'"
}

# Target health tonen voor snelle troubleshooting
$TargetGroupArn = aws cloudformation describe-stacks `
    --stack-name "cloudshirt-lb" `
    --query "Stacks[0].Outputs[?OutputKey=='WebTargetGroup'].OutputValue" `
    --output text 2>$null

if (-not [string]::IsNullOrWhiteSpace($TargetGroupArn)) {
    Write-Output ""
    Write-Output "ALB target health:"
    aws elbv2 describe-target-health `
        --target-group-arn $TargetGroupArn `
        --query "TargetHealthDescriptions[].{Instance:Target.Id,Status:TargetHealth.State,Reden:TargetHealth.Reason}" `
        --output table
}

# Lambda-functienaam tonen
$LambdaName = aws cloudformation describe-stacks `
    --stack-name "cloudshirt-serverless" `
    --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionName'].OutputValue" `
    --output text 2>$null

if (-not [string]::IsNullOrWhiteSpace($LambdaName)) {
    $SnsArn = aws cloudformation describe-stacks `
        --stack-name "cloudshirt-serverless" `
        --query "Stacks[0].Outputs[?OutputKey=='SNSTopicArn'].OutputValue" `
        --output text 2>$null

    Write-Output ""
    Write-Output "Serverless Lambda (REQ-08):"
    Write-Output "  Functienaam : $LambdaName"
    Write-Output "  SNS-topic   : $SnsArn"
    Write-Output "  Logs        : aws logs tail /aws/lambda/$LambdaName --follow"
    Write-Output "  Testen      : aws lambda invoke --function-name $LambdaName /tmp/lambda-out.json; cat /tmp/lambda-out.json"
}

Write-Output ""
Write-Output "Volgende stappen:"
Write-Output "  1. Wacht 15-20 minuten totdat de EC2-instances de .NET-app hebben gebouwd."
Write-Output "  2. Open de applicatie-URL hierboven in je browser."
Write-Output "  3. Controleer Kibana op http://<ELK-IP>:5601 voor logs."
Write-Output "  4. Bekijk CloudWatch Logs van de Lambda voor export-monitor resultaten."
Write-Output ""
Write-Output "Logs bekijken op een instance (vervang INSTANCE_ID):"
Write-Output "  aws ec2 get-console-output --instance-id INSTANCE_ID --output text"
