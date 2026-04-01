<#
.SYNOPSIS
    Verwijdert alle CloudFormation-stacks van de CloudShirt-omgeving.

.DESCRIPTION
    Verwijdert de opgegeven stacks in de juiste volgorde (omgekeerd aan de
    deployment-volgorde). Stacks die niet bestaan worden overgeslagen.

    Let op: S3-buckets met inhoud worden NIET automatisch verwijderd door
    CloudFormation. Verwijder de bucket-inhoud eerst via de AWS Console
    of via: aws s3 rm s3://<bucketnaam> --recursive

.PARAMETER Region
    AWS-regio. Standaard: us-east-1.

.PARAMETER StacksToRemove
    Lijst van te verwijderen stack-namen. Standaard alle stacks, in de
    juiste volgorde (afhankelijkheden eerst).

.EXAMPLE
    .\Remove-CloudShirt.ps1
    .\Remove-CloudShirt.ps1 -StacksToRemove @("cloudshirt-asg", "cloudshirt-lb")

.NOTES
    Vereisten:
    - AWS CLI v2 geconfigureerd (credentials ingesteld als omgevingsvariabelen
      of via aws configure)
#>

[CmdletBinding()]
param (
    [string]$Region = "us-east-1",

    # Omgekeerde volgorde ten opzichte van deployment:
    # stacks met afhankelijkheden worden als eerste verwijderd
    [string[]]$StacksToRemove = @(
        "cloudshirt-s3",
        "cloudshirt-asg",
        "cloudshirt-lb",
        "cloudshirt-ec2",
        "cloudshirt-rds",
        "cloudshirt-elk",
        "cloudshirt-efs",
        "cloudshirt-network"
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Hulpfunctie: schrijf een sectieheader naar de console
# ---------------------------------------------------------------------------
function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "===== $Title =====" -ForegroundColor Magenta
}

# ---------------------------------------------------------------------------
# Stap 1: controleer of AWS-credentials beschikbaar zijn
# ---------------------------------------------------------------------------
Write-Section "Vooraf controleren"

$null = aws sts get-caller-identity 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "FOUT: geen geldige AWS-credentials gevonden." -ForegroundColor Red
    Write-Host "Stel credentials in via omgevingsvariabelen of aws configure." -ForegroundColor Yellow
    exit 1
}

Write-Host "AWS-credentials gevonden." -ForegroundColor Green

# ---------------------------------------------------------------------------
# Stap 2: bevestiging vragen voordat er iets verwijderd wordt
# ---------------------------------------------------------------------------
Write-Section "Bevestiging vereist"

Write-Host "De volgende stacks worden verwijderd:" -ForegroundColor Yellow
$StacksToRemove | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
Write-Host ""
Write-Host "LET OP: S3-buckets met inhoud worden NIET automatisch verwijderd." -ForegroundColor Red
Write-Host "        Leeg de bucket eerst met:" -ForegroundColor Red
Write-Host "        aws s3 rm s3://<bucketnaam> --recursive" -ForegroundColor Red
Write-Host ""

$Confirm = Read-Host "Weet je het zeker? Typ 'ja' om door te gaan"
if ($Confirm -ne "ja") {
    Write-Host "Afgebroken." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Hulpfunctie: verwijder één CloudFormation-stack
#
# Controleert eerst of de stack bestaat. Als dat niet zo is, wordt de stack
# overgeslagen. Anders wordt de stack verwijderd en gewacht tot hij weg is.
# ---------------------------------------------------------------------------
function Remove-Stack {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$StackName
    )

    Write-Host ""
    Write-Host "  → $StackName" -ForegroundColor Cyan

    # Controleer of de stack bestaat voordat we proberen te verwijderen
    $null = aws cloudformation describe-stacks --stack-name $StackName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    Bestaat niet, overgeslagen." -ForegroundColor DarkGray
        return
    }

    # Verwijder de stack
    aws cloudformation delete-stack --stack-name $StackName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FOUT: verwijderen mislukt." -ForegroundColor Red
        return
    }

    Write-Host "    Wachten op verwijdering..." -ForegroundColor DarkGray
    aws cloudformation wait stack-delete-complete --stack-name $StackName
    Write-Host "    Verwijderd." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Stap 3: stacks verwijderen in de opgegeven volgorde
# ---------------------------------------------------------------------------
Write-Section "Stacks verwijderen"

foreach ($StackName in $StacksToRemove) {
    Remove-Stack -StackName $StackName
}

# ---------------------------------------------------------------------------
# Klaar
# ---------------------------------------------------------------------------
Write-Section "Verwijdering voltooid"
Write-Host "Alle opgegeven stacks zijn verwijderd (indien aanwezig)." -ForegroundColor Green
