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
    Write-Output ""
    Write-Output "===== $Title ====="
}

# ---------------------------------------------------------------------------
# Stap 1: credentials inlezen uit aws.txt (indien aanwezig)
#
# aws.txt formaat (NIET committen, staat in .gitignore):
#   aws_access_key_id=ASIA...
#   aws_secret_access_key=...
#   aws_session_token=...
# ---------------------------------------------------------------------------
Write-Section "Vooraf controleren"

$AwsFile = Join-Path $PSScriptRoot "aws.txt"

if (Test-Path $AwsFile) {
    $AwsData = @{}
    Get-Content $AwsFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)\s*=\s*(.+)\s*$') {
            $AwsData[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }

    if ($AwsData.ContainsKey('aws_access_key_id') -and
        $AwsData.ContainsKey('aws_secret_access_key') -and
        $AwsData.ContainsKey('aws_session_token')) {

        $env:AWS_ACCESS_KEY_ID     = $AwsData['aws_access_key_id']
        $env:AWS_SECRET_ACCESS_KEY = $AwsData['aws_secret_access_key']
        $env:AWS_SESSION_TOKEN     = $AwsData['aws_session_token']
        $env:AWS_DEFAULT_REGION    = $Region
        Write-Output "Credentials geladen uit aws.txt."
    }
}

$null = aws sts get-caller-identity --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "FOUT: geen geldige AWS-credentials gevonden."
    Write-Output "Zorg dat aws.txt aanwezig is of stel credentials in via omgevingsvariabelen."
    exit 1
}

Write-Output "AWS-credentials gevonden."

# ---------------------------------------------------------------------------
# Stap 2: bevestiging vragen voordat er iets verwijderd wordt
# ---------------------------------------------------------------------------
Write-Section "Bevestiging vereist"

Write-Output "De volgende stacks worden verwijderd:"
$StacksToRemove | ForEach-Object { Write-Output "  - $_" }
Write-Output ""
Write-Output "LET OP: S3-buckets met inhoud worden NIET automatisch verwijderd."
Write-Output "        Leeg de bucket eerst met:"
Write-Output "        aws s3 rm s3://<bucketnaam> --recursive"
Write-Output ""

$Confirm = Read-Host "Weet je het zeker? Typ 'ja' om door te gaan"
if ($Confirm -ne "ja") {
    Write-Output "Afgebroken."
    exit 0
}

# ---------------------------------------------------------------------------
# Hulpfunctie: verwijder een CloudFormation-stack
#
# Controleert eerst of de stack bestaat. Als dat niet zo is, wordt de stack
# overgeslagen. Anders wordt de stack verwijderd en gewacht tot hij weg is.
# ---------------------------------------------------------------------------
function Remove-Stack {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)][string]$StackName
    )

    Write-Output ""
    Write-Output "  -> $StackName"

    # Controleer of de stack bestaat voordat we proberen te verwijderen
    $null = aws cloudformation describe-stacks --region $Region --stack-name $StackName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "    Bestaat niet, overgeslagen."
        return
    }

    # Verwijder de stack
    if ($PSCmdlet.ShouldProcess($StackName, "Delete CloudFormation stack")) {
        aws cloudformation delete-stack --region $Region --stack-name $StackName
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Output "    FOUT: verwijderen mislukt."
        return
    }

    Write-Output "    Wachten op verwijdering..."
    aws cloudformation wait stack-delete-complete --region $Region --stack-name $StackName
    Write-Output "    Verwijderd."
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
Write-Output "Alle opgegeven stacks zijn verwijderd (indien aanwezig)."
