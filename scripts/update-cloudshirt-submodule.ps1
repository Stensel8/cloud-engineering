[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$SubmodulePath = "cloud-automation-concepts/CloudShirt",
    [string]$HugoSubmodulePath = "cloud-automation-concepts/CloudShirt-Hugo",
    [string]$SubmoduleBranch = "main",
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-TrimmedString {
    param(
        [AllowNull()]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return "$Value".Trim()
}

function Test-IsGitCommitHash {
    param(
        [string]$Value
    )

    return $Value -match '^[0-9a-fA-F]{40}$'
}

if (-not (Test-Path (Join-Path $RepositoryRoot ".gitmodules"))) {
    throw "Geen .gitmodules gevonden in $RepositoryRoot"
}

Push-Location $RepositoryRoot
try {
    $submodules = @(
        @{
            Name   = "CloudShirt"
            Path   = $SubmodulePath
            Url    = "https://github.com/Stensel8/CloudShirt.git"
            Branch = $SubmoduleBranch
        },
        @{
            Name   = "CloudShirt-Hugo"
            Path   = $HugoSubmodulePath
            Url    = "https://github.com/Stensel8/CloudShirt-Hugo.git"
            Branch = $SubmoduleBranch
        }
    )

    $results = @()

    foreach ($submodule in $submodules) {
        $name = $submodule.Name
        $path = $submodule.Path
        $url = $submodule.Url
        $branch = $submodule.Branch

        Write-Output "Submodule '$name' op '$path' wordt gecontroleerd en bijgewerkt naar '$branch'..."

        $oldCommitRaw = & git -C $RepositoryRoot rev-parse "HEAD:$path" 2>$null
        $oldCommitExitCode = $LASTEXITCODE
        $oldCommit = ConvertTo-TrimmedString -Value $oldCommitRaw
        if ($oldCommitExitCode -ne 0 -or -not (Test-IsGitCommitHash -Value $oldCommit)) {
            $oldCommit = ""
        }

        $configuredUrlRaw = & git -C $RepositoryRoot config -f .gitmodules --get "submodule.$path.url" 2>$null
        $configuredUrl = ConvertTo-TrimmedString -Value $configuredUrlRaw

        if ([string]::IsNullOrWhiteSpace($configuredUrl)) {
            & git -C $RepositoryRoot submodule add -b $branch $url $path
            if ($LASTEXITCODE -ne 0) {
                throw "Toevoegen van submodule '$name' op '$path' is mislukt."
            }
        }
        else {
            if ($configuredUrl -ne $url) {
                & git -C $RepositoryRoot submodule set-url -- $path $url
                if ($LASTEXITCODE -ne 0) {
                    throw "Instellen van remote URL voor submodule '$name' is mislukt."
                }
            }

            & git -C $RepositoryRoot config -f .gitmodules "submodule.$path.branch" $branch
            if ($LASTEXITCODE -ne 0) {
                throw "Instellen van branch voor submodule '$name' is mislukt."
            }
        }

        & git -C $RepositoryRoot submodule update --init --remote -- $path
        if ($LASTEXITCODE -ne 0) {
            throw "Bijwerken van submodule '$name' op '$path' is mislukt."
        }

        $newCommitRaw = & git -C (Join-Path $RepositoryRoot $path) rev-parse HEAD 2>$null
        $newCommit = ConvertTo-TrimmedString -Value $newCommitRaw
        if (-not (Test-IsGitCommitHash -Value $newCommit)) {
            throw "Nieuwe submodule-commit voor '$name' kon niet worden bepaald."
        }

        & git -C $RepositoryRoot add -- $path
        if ($LASTEXITCODE -ne 0) {
            throw "Stagen van submodulepad '$path' is mislukt."
        }

        $results += [PSCustomObject]@{
            Name      = $name
            Path      = $path
            OldCommit = $oldCommit
            NewCommit = $newCommit
            Changed   = ($oldCommit -ne $newCommit)
        }
    }

    & git -C $RepositoryRoot diff --quiet -- .gitmodules
    if ($LASTEXITCODE -ne 0) {
        & git -C $RepositoryRoot add -- .gitmodules
        if ($LASTEXITCODE -ne 0) {
            throw "Stagen van .gitmodules is mislukt."
        }
    }

    $staged = (& git -C $RepositoryRoot diff --cached --name-only -- $SubmodulePath $HugoSubmodulePath .gitmodules 2>$null)
    if (-not $staged) {
        Write-Output "Geen submodulewijzigingen gevonden; niets om te committen."
        return
    }

    $changedModules = @($results | Where-Object { $_.Changed })
    if ($changedModules.Count -eq 1) {
        $item = $changedModules[0]
        $shortNew = $item.NewCommit.Substring(0, 7)
        $shortOld = if ($item.OldCommit.Length -ge 7) { $item.OldCommit.Substring(0, 7) } else { "none" }
        $message = "chore(submodule): bump $($item.Name) $shortOld -> $shortNew"
    }
    else {
        $names = @($submodules | ForEach-Object { $_.Name }) -join ", "
        $message = "chore(submodule): update $names"
    }

    & git -C $RepositoryRoot commit -m $message -- $SubmodulePath $HugoSubmodulePath .gitmodules
    if ($LASTEXITCODE -ne 0) {
        throw "Commit voor submodule-update is mislukt."
    }

    Write-Output "Submodule-update gecommit: $message"

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
