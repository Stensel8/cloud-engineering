# DeleteCFStackDocker.ps1
param(
    [string]$Region = "us-east-1",
    [string[]]$StacksToDelete = @(
        "asg-stack",
        "alb-stack",
        "buildserver-stack",
        "rds-stack",
        "efs-stack",
        "elk-stack",
        "base-stack"
    )
)

# ===== Controleer of AWS CLI aanwezig is =====
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Output "AWS CLI is niet geinstalleerd. Installeer eerst AWS CLI v2."
    exit 1
}

# Controleer of credentials geldig zijn
$null = aws sts get-caller-identity --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "Fout: geen geldige AWS-credentials gevonden."
    Write-Output "Voer eerst het deployscript uit of stel tijdelijke credentials in."
    exit 1
}

Write-Output "AWS CLI geverifieerd, verder met het verwijderen van stacks..."

# ===== Functie om stack te verwijderen =====
function Remove-Stack {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$StackName
    )

    Write-Output ">>> Verwijderen stack: $StackName"

    # Controleer of stack bestaat
    $null = aws cloudformation describe-stacks --region $Region --stack-name $StackName 2>$null

    if ($LASTEXITCODE -eq 0) {
        if ($PSCmdlet.ShouldProcess($StackName, "Delete CloudFormation stack")) {
            aws cloudformation delete-stack `
                --region $Region `
                --stack-name $StackName
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Output "Wachten tot stack $StackName volledig verwijderd is..."
            aws cloudformation wait stack-delete-complete --region $Region --stack-name $StackName
            Write-Output "Stack $StackName verwijderd."
        } else {
            Write-Output "Fout bij het starten van verwijderen voor $StackName."
        }
    } else {
        Write-Output "Stack $StackName bestaat niet, overslaan."
    }
}

# ===== Verwijder stacks in juiste volgorde =====
foreach ($stack in $StacksToDelete) {
    Remove-Stack -StackName $stack
}

Write-Output "Alle opgegeven stacks zijn verwijderd (indien aanwezig)."
