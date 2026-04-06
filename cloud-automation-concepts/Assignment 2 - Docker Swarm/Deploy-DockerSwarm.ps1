<#
.SYNOPSIS
    Deployt alle CloudFormation-stacks voor de Cloudshirt-Hugo (Docker Swarm) omgeving.

.DESCRIPTION
    Dit script leest AWS-credentials uit een lokaal aws.txt-bestand,
    stelt de omgevingsvariabelen in en deployt alle stacks in de
    juiste volgorde via de AWS CLI.

    Stacks worden aangemaakt als ze nog niet bestaan, of bijgewerkt
    als ze al bestaan.

    Deployment-volgorde:
      1. cloudshirt-swarm-network     -- VPC, subnetten, NAT, security groups
      2. cloudshirt-swarm-ecr         -- ECR repository
      3. cloudshirt-swarm-buildserver -- Buildserver (Swarm Manager)
      4. cloudshirt-swarm-alb         -- Application Load Balancer
      5. cloudshirt-swarm-asg         -- Auto Scaling Group (Swarm Workers)

    Opmerking: IAM wordt niet uitgerold via een aparte stack. De LabInstanceProfile
    is een vooraf aangemaakte rol van AWS Academy die direct wordt gebruikt.
    Verbinding met instances gaat via SSM Session Manager.

.PARAMETER Region
    AWS-regio. Standaard: us-east-1 (vereist door AWS Academy).

.EXAMPLE
    .\Deploy-DockerSwarm.ps1

.NOTES
    Vereisten:
    - AWS CLI v2 geinstalleerd
    - aws.txt aanwezig in dezelfde map (zie README voor formaat)
    - aws.txt staat in .gitignore - commit dit bestand NOOIT
#>

[CmdletBinding()]
param (
    [string]$Region = "us-east-1"
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
# Hulpfunctie: deploy een CloudFormation-stack
#
# Maakt de stack aan als hij nog niet bestaat; werkt hem bij als hij al bestaat.
# Wacht tot de operatie voltooid is voordat de functie terugkeert.
# ---------------------------------------------------------------------------
function Invoke-StackDeployment {
    [CmdletBinding()]
    param (
        # Naam van de CloudFormation-stack (bijv. "cloudshirt-swarm-network")
        [Parameter(Mandatory)][string]$StackName,

        # Pad naar het CloudFormation-templatebestand
        [Parameter(Mandatory)][string]$TemplateFile
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
# Stap 4: deployment uitvoeren in de juiste volgorde
#
# De volgorde is belangrijk: latere stacks importeren outputs van eerdere
# stacks via !ImportValue. Een stack die nog niet bestaat kan niet worden
# geimporteerd.
# ---------------------------------------------------------------------------
Write-Section "Deployment starten"

# 1. Netwerk-basisinfrastructuur
#    Alle andere stacks zijn hiervan afhankelijk.
Write-Output "Stap 1/5 - Netwerk"
Invoke-StackDeployment -StackName "cloudshirt-swarm-network" -TemplateFile ".\cloudshirt-swarm-network.yml"

# 2. ECR-repository voor Docker-images
Write-Output "Stap 2/5 - ECR"
Invoke-StackDeployment -StackName "cloudshirt-swarm-ecr" -TemplateFile ".\cloudshirt-swarm-ecr.yml"

# 3. Buildserver (Swarm Manager)
#    Gebruikt de vooraf aangemaakte LabInstanceProfile van AWS Academy.
#    Initialiseert de Swarm en slaat join-token op in SSM.
Write-Output "Stap 3/5 - Buildserver (Swarm Manager)"
Invoke-StackDeployment -StackName "cloudshirt-swarm-buildserver" -TemplateFile ".\cloudshirt-swarm-buildserver.yml"

# 4. Application Load Balancer
Write-Output "Stap 4/5 - Application Load Balancer"
Invoke-StackDeployment -StackName "cloudshirt-swarm-alb" -TemplateFile ".\cloudshirt-swarm-alb.yml"

# 5. Auto Scaling Group (Swarm Workers)
#    Afhankelijk van ALB target group en SSM-parameters van de Buildserver.
Write-Output "Stap 5/5 - Auto Scaling Group (Swarm Workers)"
Invoke-StackDeployment -StackName "cloudshirt-swarm-asg" -TemplateFile ".\cloudshirt-swarm-asg.yml"

# ---------------------------------------------------------------------------
# Klaar
# ---------------------------------------------------------------------------
Write-Section "Deployment voltooid"
Write-Output "Alle stacks zijn succesvol gedeployt."
Write-Output ""
Write-Output "Vereisten afgevinkt:"
Write-Output "  REQ-08  Applicatie is gedockeriseerd (Dockerfile in CloudShirt-Hugo)"
Write-Output "  REQ-09  Buildserver staat in het private subnet (geen publiek IP)"
Write-Output "  REQ-10  Docker Compose voor services en uitrol (docker-compose.swarm.yml)"
Write-Output "  REQ-11  Nightly builds op de Buildserver (cron 02:00 UTC)"
Write-Output "  REQ-12  Images worden gepusht naar ECR (nightly-build.sh)"
Write-Output "  REQ-13  Buildserver als Swarm Manager (initialiseert Swarm, beheert join-token)"
Write-Output "  REQ-14  ASG-instances als Swarm Workers (joinen via SSM-token)"
Write-Output ""

# ALB-URL ophalen en tonen
$AlbDns = aws cloudformation describe-stacks `
    --stack-name "cloudshirt-swarm-alb" `
    --query "Stacks[0].Outputs[?OutputKey=='ALBDNSName'].OutputValue" `
    --output text 2>$null

if (-not [string]::IsNullOrWhiteSpace($AlbDns)) {
    Write-Output "Cloudshirt-Hugo applicatie-URL:"
    Write-Output "  http://$AlbDns"
} else {
    Write-Output "Haal de ALB-URL op via:"
    Write-Output "  aws cloudformation describe-stacks --stack-name cloudshirt-swarm-alb --query 'Stacks[0].Outputs'"
}

# ALB target health tonen voor snelle troubleshooting
$TargetGroupArn = aws cloudformation describe-stacks `
    --stack-name "cloudshirt-swarm-alb" `
    --query "Stacks[0].Outputs[?OutputKey=='TargetGroupArn'].OutputValue" `
    --output text 2>$null

if (-not [string]::IsNullOrWhiteSpace($TargetGroupArn)) {
    Write-Output ""
    Write-Output "ALB target health:"
    aws elbv2 describe-target-health `
        --target-group-arn $TargetGroupArn `
        --query "TargetHealthDescriptions[].{Instance:Target.Id,State:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}" `
        --output table
}

Write-Output ""
Write-Output "Volgende stappen:"
Write-Output "  1. Wacht 2-5 minuten tot workers Ready zijn en ALB health checks groen worden."
Write-Output "  2. Verbind via SSM Session Manager met de Buildserver en voer uit:"
Write-Output "       docker node ls"
Write-Output "  3. Controleer of de service draait:"
Write-Output "       docker service ls && docker service ps cloudshirt_web"
