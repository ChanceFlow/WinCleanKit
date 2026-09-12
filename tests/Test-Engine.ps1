<#
.SYNOPSIS
    Engine behaviour tests. Changes nothing (every call is -Plan or -DryRun).

.DESCRIPTION
    These lock down the behaviours that make the tool safe to hand to a user:
    preview never writes, -Only is authoritative, -Skip wins, and the preset
    hierarchy holds. Runs on Windows PowerShell 5.1 and PowerShell 7+.

.EXAMPLE
    .\tests\Test-Engine.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$eng  = Join-Path $root 'src/WinCleanKit.ps1'
$menu = Join-Path $root 'src/menu/menu.ps1'

$pass = 0; $fail = 0
function Check([string]$Name, [bool]$Ok, [string]$Detail = '') {
    if ($Ok) { $script:pass++; Write-Host ("  [PASS] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" } else { '' })) -ForegroundColor Green }
    else     { $script:fail++; Write-Host ("  [FAIL] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" } else { '' })) -ForegroundColor Red }
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("wck-test-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$blank = Join-Path $tmp 'blank.txt'; New-Item -ItemType File -Path $blank -Force | Out-Null

function Invoke-Host {
    # Redirect to files instead of merging streams: `2>&1 | Out-String` can wrap
    # stderr lines in error-record formatting and corrupt otherwise good output.
    param([string]$Script, [string[]]$ScriptArgs)
    $so = Join-Path $tmp 'out.txt'
    $se = Join-Path $tmp 'err.txt'
    $p = Start-Process -FilePath 'powershell' -PassThru -Wait -NoNewWindow `
            -RedirectStandardOutput $so -RedirectStandardError $se `
            -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script) + $ScriptArgs)
    [pscustomobject]@{
        Exit  = $p.ExitCode
        Out   = (Get-Content $so -Raw -ErrorAction SilentlyContinue)
        Err   = (Get-Content $se -Raw -ErrorAction SilentlyContinue)
        Text  = ((Get-Content $so -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content $se -Raw -ErrorAction SilentlyContinue))
    }
}
function Engine-Plan([string[]]$EngineArgs) {
    (Invoke-Host -Script $eng -ScriptArgs (@('-Plan', '-NoPrompt') + $EngineArgs)).Text
}
function Engine-Count([string[]]$EngineArgs) {
    $r = Invoke-Host -Script $eng -ScriptArgs (@('-Plan', '-NoPrompt') + $EngineArgs)
    $m = [regex]::Match($r.Out, 'Selected\s*:\s*(\d+)')
    if ($m.Success) { [int]$m.Groups[1].Value } else { 0 }
}
function Menu-Sel([string[]]$MenuArgs) {
    , @(& powershell -NoProfile -ExecutionPolicy Bypass -File $menu -Mode sel -Lang en @MenuArgs)
}

try {
    Write-Host ''
    Write-Host '=== preset counts ===' -ForegroundColor Cyan
    $nCons = Engine-Count @('-Preset', 'conservative')
    $nBal  = Engine-Count @('-Preset', 'balanced')
    $nAgg  = Engine-Count @('-Preset', 'aggressive')
    Check 'conservative resolves' ($nCons -gt 0) "count=$nCons"
    Check 'preset hierarchy holds' ($nCons -lt $nBal -and $nBal -lt $nAgg) "$nCons < $nBal < $nAgg"

    Write-Host ''
    Write-Host '=== -Only is authoritative, not additive ===' -ForegroundColor Cyan
    Check 'single id' ((Engine-Count @('-Preset', 'balanced', '-Only', 'ads.cdm.silent-install')) -eq 1)
    Check 'comma bundle splits' ((Engine-Count @('-Preset', 'balanced', '-Only', 'ads.cdm.silent-install,apps.maps')) -eq 2)
    Check 'only does not union with preset' ((Engine-Count @('-Preset', 'aggressive', '-Only', 'ads.cdm.silent-install')) -eq 1) 'aggressive has 74 actions; -Only must still yield 1'
    Check 'unknown id yields nothing' ((Engine-Count @('-Preset', 'balanced', '-Only', 'no.such.id')) -eq 0)
    $catCount = Engine-Count @('-Preset', 'balanced', '-Only', 'telemetry')
    Check 'category id expands' ($catCount -gt 1) "telemetry resolved to $catCount"

    Write-Host ''
    Write-Host '=== -Skip wins over -Only and preset ===' -ForegroundColor Cyan
    Check 'skip beats only' ((Engine-Count @('-Preset', 'balanced', '-Only', 'ads.cdm.silent-install,apps.maps', '-Skip', 'apps.maps')) -eq 1)
    Check 'skip subtracts from preset' ((Engine-Count @('-Preset', 'balanced', '-Skip', 'telemetry')) -lt $nBal)

    Write-Host ''
    Write-Host '=== -FromFile ===' -ForegroundColor Cyan
    $sel = Join-Path $tmp 'sel.txt'
    [IO.File]::WriteAllText($sel, "ads.cdm.silent-install`napps.maps`nprivacy.advertising-id`n", (New-Object Text.UTF8Encoding($false)))
    Check 'reads three ids' ((Engine-Count @('-Preset', 'conservative', '-FromFile', $sel)) -eq 3)
    $sel2 = Join-Path $tmp 'sel2.txt'
    [IO.File]::WriteAllText($sel2, "# a comment`n`nads.cdm.silent-install`n   apps.maps   `n", (New-Object Text.UTF8Encoding($false)))
    Check 'ignores comments and blank lines' ((Engine-Count @('-Preset', 'conservative', '-FromFile', $sel2)) -eq 2)
    Check 'skip still wins over fromfile' ((Engine-Count @('-Preset', 'conservative', '-FromFile', $sel, '-Skip', 'apps.maps')) -eq 2)

    Write-Host ''
    Write-Host '=== deselection survives the round trip (the important one) ===' -ForegroundColor Cyan
    # This is the exact path the .bat takes: resolve in the menu, hand the list to
    # the engine. If -Only were additive, deselected items would come back.
    Set-StrictMode -Off
    $minusFile = Join-Path $tmp 'minus.txt'
    $base = Menu-Sel @('-Preset', 'balanced', '-PlusFile', $blank, '-MinusFile', $blank)
    $drop = @($base | Select-Object -First 10)
    [IO.File]::WriteAllText($minusFile, (($drop -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))
    $after = Menu-Sel @('-Preset', 'balanced', '-PlusFile', $blank, '-MinusFile', $minusFile)
    Check 'menu honours the removals' ($after.Count -eq $base.Count - 10) "$($base.Count) - 10 = $($after.Count)"

    $rt = Join-Path $tmp 'roundtrip.txt'
    [IO.File]::WriteAllText($rt, (($after -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))
    $engineCount = Engine-Count @('-Preset', 'balanced', '-FromFile', $rt)
    Check 'engine matches the menu exactly' ($engineCount -eq $after.Count) "menu=$($after.Count) engine=$engineCount"
    $readded = @($drop | Where-Object { $after -contains $_ })
    Check 'no removed item came back' ($readded.Count -eq 0) ("re-added: " + ($readded -join ', '))
    Set-StrictMode -Version 2.0

    Write-Host ''
    Write-Host '=== preview and dry run must not change anything ===' -ForegroundColor Cyan
    $planOut = Engine-Plan @('-Preset', 'conservative')
    Check 'plan says it is a preview' ($planOut -match 'PREVIEW ONLY|Preview only') 'must warn that nothing was changed'
    Check 'plan offers no restore script' (-not ($planOut -match 'Restore:'))

    $before = @(Get-ChildItem ([Environment]::GetFolderPath('Desktop')) -Directory -Filter 'WinCleanKit-*' -ErrorAction SilentlyContinue).Count
    $dryRun = Invoke-Host -Script $eng -ScriptArgs @('-Apply', '-DryRun', '-NoPrompt',
                    '-Only', 'ads.cdm.silent-install,telemetry.svc.diagtrack', '-Language', 'en')
    $dryOut = $dryRun.Text
    $afterCount = @(Get-ChildItem ([Environment]::GetFolderPath('Desktop')) -Directory -Filter 'WinCleanKit-*' -ErrorAction SilentlyContinue).Count
    Check 'dry run reports would-apply' ($dryOut -match 'would') 'preview path executed'
    Check 'dry run created no restore point' ($afterCount -eq $before) "$before -> $afterCount"
    Check 'dry run wrote no restore script line' (-not ($dryOut -match 'Restore:'))

    Write-Host ''
    Write-Host '=== bilingual output ===' -ForegroundColor Cyan
    $zh = Engine-Plan @('-Preset', 'conservative', '-Language', 'zh')
    $en = Engine-Plan @('-Preset', 'conservative', '-Language', 'en')
    Check 'zh output contains Chinese' ($zh -match '[\u4e00-\u9fff]') 'Chinese strings decoded correctly'
    Check 'en output contains no Chinese titles' (-not ($en -match '[\u4e00-\u9fff]{3,}')) 'English fallback works'
    Check 'zh and en select the same actions' ((Engine-Count @('-Preset', 'conservative', '-Language', 'zh')) -eq (Engine-Count @('-Preset', 'conservative', '-Language', 'en')))
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks)" -f $pass) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
