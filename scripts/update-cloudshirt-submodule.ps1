[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$SubmodulePath = "cloud-automation-concepts/CloudShirt",
    [string]$SubmoduleBranch = "main",
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $RepositoryRoot ".gitmodules"))) {
    throw "Geen .gitmodules gevonden in $RepositoryRoot"
}

Push-Location $RepositoryRoot
try {
    Write-Output "Submodule '$SubmodulePath' wordt bijgewerkt naar de laatste '$SubmoduleBranch'..."

    $oldCommitRaw = & git -C $RepositoryRoot rev-parse "HEAD:$SubmodulePath" 2>$null
    $oldCommit = ([string]$oldCommitRaw).Trim()

    & git -C $RepositoryRoot submodule update --init --remote -- $SubmodulePath
    if ($LASTEXITCODE -ne 0) {
        throw "Bijwerken van submodule '$SubmodulePath' is mislukt."
    }

    $newCommitRaw = & git -C (Join-Path $RepositoryRoot $SubmodulePath) rev-parse HEAD 2>$null
    $newCommit = ([string]$newCommitRaw).Trim()
    if ([string]::IsNullOrWhiteSpace($newCommit)) {
        throw "Nieuwe submodule-commit voor '$SubmodulePath' kon niet worden bepaald."
    }

    # Stage alleen de submodule-pointer (en .gitmodules als dat gewijzigd is)
    & git -C $RepositoryRoot add -- $SubmodulePath
    if ($LASTEXITCODE -ne 0) {
        throw "Stagen van submodulepad '$SubmodulePath' is mislukt."
    }

    & git -C $RepositoryRoot diff --quiet -- .gitmodules
    if ($LASTEXITCODE -ne 0) {
        & git -C $RepositoryRoot add -- .gitmodules
        if ($LASTEXITCODE -ne 0) {
            throw "Stagen van .gitmodules is mislukt."
        }
    }

    $staged = (& git -C $RepositoryRoot diff --cached --name-only -- $SubmodulePath .gitmodules 2>$null)
    if (-not $staged) {
        Write-Output "Geen submodulewijzigingen gevonden; niets om te committen."
        return
    }

    if ($oldCommit -eq $newCommit) {
        Write-Output "Submodule staat al op de laatste commit van '$SubmoduleBranch'; niets om te committen."
        return
    }

    $shortNew = $newCommit.Substring(0, 7)
    $shortOld = if ($oldCommit.Length -ge 7) { $oldCommit.Substring(0, 7) } else { "none" }
    $message = "chore(submodule): bump CloudShirt $shortOld -> $shortNew"

    & git -C $RepositoryRoot commit -m $message -- $SubmodulePath .gitmodules
    if ($LASTEXITCODE -ne 0) {
        throw "Commit voor submodule-update is mislukt."
    }

    Write-Output "Submodule-update gecommit: $shortOld -> $shortNew"

    if ($Push) {
        & git -C $RepositoryRoot push
        if ($LASTEXITCODE -ne 0) {
            throw "Push is mislukt."
        }
        Write-Output "Commit is gepusht naar remote."
    }
}
finally {
    Pop-Location
}
