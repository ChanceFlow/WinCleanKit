@{
    # PSScriptAnalyzer ruleset for WinCleanKit.
    #
    # Every exclusion below is a deliberate, measured decision, not a way to make
    # the gate pass. Rules that point at real problems are kept enabled even when
    # satisfying them needs work — PSReviewUnusedParameter, PSUseApprovedVerbs,
    # PSUseSingularNouns and PSUseShouldProcessForStateChangingFunctions are all
    # active, and the code satisfies them or suppresses them at the call site with
    # a Justification.
    #
    # See docs/LINTING.md for the current finding counts and the reasoning.

    Severity    = @('Error', 'Warning')

    ExcludeRules = @(
        # 86 findings. This is an interactive console application: coloured
        # terminal output IS the interface, and the engine is invoked as a script
        # rather than as a pipeline citizen. Write-Host is the correct tool.
        # Suppressed per function inside the source as well.
        'PSAvoidUsingWriteHost',

        # 33 findings. Every one is a call to one of the Write-* console helpers
        # (Write-Info "text") or Get-OptProp, all of which take a single mandatory
        # string. Positional use is unambiguous and reads better than
        # `-Text "..."` at ~90 call sites.
        'PSAvoidUsingPositionalParameters'
    )

    Rules = @{
        # Keep aliases out of the source entirely.
        PSAvoidUsingCmdletAliases = @{ Enable = $true }

        # Windows PowerShell 5.1 is the supported floor, so PS7-only syntax must
        # be caught here rather than at a user's machine.
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }

        # Colon-separated variable names, unapproved verbs and unused parameters
        # are all genuine defects; ensure they are reported rather than skipped.
        PSReviewUnusedParameter  = @{ Enable = $true }
        PSUseApprovedVerbs       = @{ Enable = $true }
        PSUseSingularNouns       = @{ Enable = $true }
        PSUseDeclaredVarsMoreThanAssignments = @{ Enable = $true }
    }
}
