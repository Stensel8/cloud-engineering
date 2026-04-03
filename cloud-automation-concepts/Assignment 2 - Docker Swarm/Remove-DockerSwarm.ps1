<#
.SYNOPSIS
    Verwijdert alle CloudFormation-stacks van de CloudShirt Docker Swarm-omgeving.

.DESCRIPTION
    Verwijdert de stacks in de juiste volgorde (omgekeerd aan deployment).
    Stacks die niet bestaan worden overgeslagen.

.PARAMETER Region
    AWS-regio. Standaard: us-east-1.

.PARAMETER StacksToRemove
    Lijst van te verwijderen stack-namen. Standaard alle stacks in de
    juiste volgorde (afhankelijkheden eerst).

.EXAMPLE
    .\Remove-DockerSwarm.ps1
    .\Remove-DockerSwarm.ps1 -StacksToRemove @("cloudshirt-swarm-asg")

.NOTES
    Vereisten:
    - AWS CLI v2 geconfigureerd (credentials ingesteld als omgevingsvariabelen
      of via aws.txt in dezelfde map)
#>

[CmdletBinding()]
param (
    [string]$Region = "us-east-1",

    # Omgekeerde volgorde ten opzichte van deployment:
    # stacks met afhankelijkheden worden als eerste verwijderd
    [string[]]$StacksToRemove = @(
        "cloudshirt-swarm-asg",         # ASG workers (afhankelijk van ALB en netwerk)
        "cloudshirt-swarm-alb",         # ALB (afhankelijk van netwerk)
        "cloudshirt-swarm-buildserver", # Buildserver (afhankelijk van netwerk, IAM, ECR)
        "cloudshirt-swarm-iam",         # IAM rol en profile
        "cloudshirt-swarm-ecr",         # ECR repository
        "cloudshirt-swarm-network"      # Netwerk (als laatste, alles hangt hiervan af)
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

$Confirm = Read-Host "Weet je het zeker? Typ 'ja' om door te gaan"
if ($Confirm -ne "ja") {
    Write-Output "Afgebroken."
    exit 0
}

# ---------------------------------------------------------------------------
# Hulpfunctie: verwijder een CloudFormation-stack
# ---------------------------------------------------------------------------
function Remove-Stack {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)][string]$StackName
    )

    Write-Output ""
    Write-Output "  -> $StackName"

    $null = aws cloudformation describe-stacks --region $Region --stack-name $StackName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "    Bestaat niet, overgeslagen."
        return
    }

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
