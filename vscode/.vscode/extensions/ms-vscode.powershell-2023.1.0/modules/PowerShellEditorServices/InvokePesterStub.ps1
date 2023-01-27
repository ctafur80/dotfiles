#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Stub around Invoke-Pester command used by VSCode PowerShell extension.
.DESCRIPTION
    The stub checks the version of Pester and if >= 4.6.0, invokes Pester
    using the LineNumber parameter (if specified). Otherwise, it invokes
    using the TestName parameter (if specified). If the All parameter
    is specified, then all the tests are invoked in the specifed file.
    Finally, if none of these three parameters are specified, all tests
    are invoked and a warning is issued indicating what the user can do
    to allow invocation of individual Describe blocks.
.EXAMPLE
    PS C:\> .\InvokePesterStub.ps1 ~\project\test\foo.tests.ps1 -LineNumber 14
    Invokes a specific test by line number in the specified file.
.EXAMPLE
    PS C:\> .\InvokePesterStub.ps1 ~\project\test\foo.tests.ps1 -TestName 'Foo Tests'
    Invokes a specific test by test name in the specified file.
.EXAMPLE
    PS C:\> .\InvokePesterStub.ps1 ~\project\test\foo.tests.ps1 -All
    Invokes all tests in the specified file.
.INPUTS
    None
.OUTPUTS
    None
#>
param(
    # Specifies the path to the test script.
    [Parameter(Position=0, Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ScriptPath,

    # Specifies the name of the test taken from the Describe block's name.
    [Parameter()]
    [string]
    $TestName,

    # Specifies the starting line number of the DescribeBlock.  This feature requires
    # Pester 4.6.0 or higher.
    [Parameter()]
    [ValidatePattern('\d*')]
    [string]
    $LineNumber,

    # If specified, executes all the tests in the specified test script.
    [Parameter()]
    [switch]
    $All,

    [Parameter()]
    [switch] $MinimumVersion5,

    [Parameter(Mandatory)]
    [string] $Output,

    [Parameter()]
    [string] $OutputPath
)

$pesterModule = Microsoft.PowerShell.Core\Get-Module Pester
# add one line, so the subsequent output is not shifted to the side
Write-Output ''

if (!$pesterModule) {
    Write-Output "Importing Pester module..."
    if ($MinimumVersion5) {
        $pesterModule = Microsoft.PowerShell.Core\Import-Module Pester -ErrorAction Ignore -PassThru -MinimumVersion 5.0.0
    }

    if (!$pesterModule) {
        $pesterModule = Microsoft.PowerShell.Core\Import-Module Pester -ErrorAction Ignore -PassThru
    }

    if (!$pesterModule) {
        Write-Warning "Failed to import Pester. You must install Pester module to run or debug Pester tests."
        Write-Warning "$(if ($MinimumVersion5) {"Recommended version to install is Pester 5.0.0 or newer. "})You can install Pester by executing: Install-Module Pester$(if ($MinimumVersion5) {" -MinimumVersion 5.0.0" }) -Scope CurrentUser -Force"
        return
    }
}

$pester4Output = switch ($Output) {
    "None" { "None" }
    "Minimal" { "Fails" }
    default { "All" }
}

if ($MinimumVersion5 -and $pesterModule.Version -lt "5.0.0") {
    Write-Warning "Pester 5.0.0 or newer is required because setting PowerShell > Pester: Use Legacy Code Lens is disabled, but Pester $($pesterModule.Version) is loaded. Some of the code lens features might not work as expected."
}


function Get-InvokePesterParams {
    $invokePesterParams = @{
        Script = $ScriptPath
    }

    if ($pesterModule.Version -ge '3.4.0') {
        # -PesterOption was introduced before 3.4.0, and VSCodeMarker in 4.0.3-rc,
        # but because no-one checks the integrity of this hashtable we can call
        # all of the versions down to 3.4.0 like this
        $invokePesterParams.Add("PesterOption", @{ IncludeVSCodeMarker = $true })
    }

    if ($pesterModule.Version -ge '3.4.5') {
        # -Show was introduced in 3.4.5
        $invokePesterParams.Add("Show", $pester4Output)
    }

    return $invokePesterParams
}

if ($All) {
    if ($pesterModule.Version -ge '5.0.0') {
        $configuration = @{
            Run = @{
                Path = $ScriptPath
            }
        }
        # only override this if user asks us to do it, to allow Pester to pick up
        # $PesterPreference from caller context and merge it with the configuration
        # we provide below, this way user can specify his output (and other) settings
        # using the standard [PesterConfiguration] object, and we can avoid providing
        # settings for everything
        if ("FromPreference" -ne $Output) {
            $configuration.Add('Output', @{ Verbosity = $Output })
        }

        if ($OutputPath) {
            $configuration.Add('TestResult', @{
                Enabled = $true
                OutputPath = $OutputPath
            })
        }
        Pester\Invoke-Pester -Configuration $configuration | Out-Null
    }
    else {
        $invokePesterParams = Get-InvokePesterParams
        Pester\Invoke-Pester @invokePesterParams
    }
}
elseif (($LineNumber -match '\d+') -and ($pesterModule.Version -ge '4.6.0')) {
    if ($pesterModule.Version -ge '5.0.0') {
        $configuration = @{
            Run = @{
                Path = $ScriptPath
            }
            Filter = @{
                Line = "${ScriptPath}:$LineNumber"
            }
        }
        if ("FromPreference" -ne $Output) {
            $configuration.Add('Output', @{ Verbosity = $Output })
        }

        if ($OutputPath) {
            $configuration.Add('TestResult', @{
                Enabled = $true
                OutputPath = $OutputPath
            })
        }

        Pester\Invoke-Pester -Configuration $configuration | Out-Null
    }
    else {
        Pester\Invoke-Pester -Script $ScriptPath -PesterOption (New-PesterOption -ScriptBlockFilter @{
            IncludeVSCodeMarker=$true; Line=$LineNumber; Path=$ScriptPath}) -Show $pester4Output
    }
}
elseif ($TestName) {
    if ($pesterModule.Version -ge '5.0.0') {
       throw "Running tests by test name is unsafe. This should not trigger for Pester 5."
    }
    else {
        $invokePesterParams = Get-InvokePesterParams
        Pester\Invoke-Pester @invokePesterParams
    }
}
else {
    if ($pesterModule.Version -ge '5.0.0') {
       throw "Running tests by expandable string is unsafe. This should not trigger for Pester 5."
    }

    # We get here when the TestName expression is of type ExpandableStringExpressionAst.
    # PSES will not attempt to "evaluate" the expression so it returns null for the TestName.
    Write-Warning "The Describe block's TestName cannot be evaluated. EXECUTING ALL TESTS instead."
    Write-Warning "To avoid this, install Pester >= 4.6.0 or remove any expressions in the TestName."

    $invokePesterParams = Get-InvokePesterParams
    Pester\Invoke-Pester @invokePesterParams
}

# SIG # Begin signature block
# MIInrQYJKoZIhvcNAQcCoIInnjCCJ5oCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBEveY8BCv+6+1G
# 6Rri2oA0s3PUTsVHmkiczeFU4+rcVqCCDYEwggX/MIID56ADAgECAhMzAAACzI61
# lqa90clOAAAAAALMMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjIwNTEyMjA0NjAxWhcNMjMwNTExMjA0NjAxWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCiTbHs68bADvNud97NzcdP0zh0mRr4VpDv68KobjQFybVAuVgiINf9aG2zQtWK
# No6+2X2Ix65KGcBXuZyEi0oBUAAGnIe5O5q/Y0Ij0WwDyMWaVad2Te4r1Eic3HWH
# UfiiNjF0ETHKg3qa7DCyUqwsR9q5SaXuHlYCwM+m59Nl3jKnYnKLLfzhl13wImV9
# DF8N76ANkRyK6BYoc9I6hHF2MCTQYWbQ4fXgzKhgzj4zeabWgfu+ZJCiFLkogvc0
# RVb0x3DtyxMbl/3e45Eu+sn/x6EVwbJZVvtQYcmdGF1yAYht+JnNmWwAxL8MgHMz
# xEcoY1Q1JtstiY3+u3ulGMvhAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUiLhHjTKWzIqVIp+sM2rOHH11rfQw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDcwNTI5MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAeA8D
# sOAHS53MTIHYu8bbXrO6yQtRD6JfyMWeXaLu3Nc8PDnFc1efYq/F3MGx/aiwNbcs
# J2MU7BKNWTP5JQVBA2GNIeR3mScXqnOsv1XqXPvZeISDVWLaBQzceItdIwgo6B13
# vxlkkSYMvB0Dr3Yw7/W9U4Wk5K/RDOnIGvmKqKi3AwyxlV1mpefy729FKaWT7edB
# d3I4+hldMY8sdfDPjWRtJzjMjXZs41OUOwtHccPazjjC7KndzvZHx/0VWL8n0NT/
# 404vftnXKifMZkS4p2sB3oK+6kCcsyWsgS/3eYGw1Fe4MOnin1RhgrW1rHPODJTG
# AUOmW4wc3Q6KKr2zve7sMDZe9tfylonPwhk971rX8qGw6LkrGFv31IJeJSe/aUbG
# dUDPkbrABbVvPElgoj5eP3REqx5jdfkQw7tOdWkhn0jDUh2uQen9Atj3RkJyHuR0
# GUsJVMWFJdkIO/gFwzoOGlHNsmxvpANV86/1qgb1oZXdrURpzJp53MsDaBY/pxOc
# J0Cvg6uWs3kQWgKk5aBzvsX95BzdItHTpVMtVPW4q41XEvbFmUP1n6oL5rdNdrTM
# j/HXMRk1KCksax1Vxo3qv+13cCsZAaQNaIAvt5LvkshZkDZIP//0Hnq7NnWeYR3z
# 4oFiw9N2n3bb9baQWuWPswG0Dq9YT9kb+Cs4qIIwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZgjCCGX4CAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAsyOtZamvdHJTgAAAAACzDAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgWYlWv0R9
# hb/RNN0zHAL65wt8KOXlvYllYi7RWeFqHl8wQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQCUswaq6+K+YbsA/sXW9Lvb5u4sE23MCifZcGN89cOO
# 6iqhtCCcFGlcK5ObZj3TzPwMPtgglu1A/dilLUHsp+FcMHlq/mCCpP/x0C7HXFGM
# 6vq+xh1JvBf2jlMo54KOtafxhgRQIhY7WESzndGSzVQRIuR+ccMnLL5pVcSD5WkT
# vUSzFiFLpMt78AnMA27RpoRJnbF3gcZy4UJudpDITS2JKcxy/Gx8xu4IT5coQsAi
# GV/BT/8syM+hy0jyr1PJezGx7sTnXmT4as90rHSN0TQHHbME3bSbc10Ac9XJKuZE
# TRn0f4TUfK9WfZ9tS6fp96ExBLy2IncQl+h2v5Cb6Aa/oYIXDDCCFwgGCisGAQQB
# gjcDAwExghb4MIIW9AYJKoZIhvcNAQcCoIIW5TCCFuECAQMxDzANBglghkgBZQME
# AgEFADCCAVUGCyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIPcS9ghzg0gy+9YW0/UUC3ITGGFhgMb2l44Pe513
# 9033AgZjoaF5yysYEzIwMjMwMTA0MjA0NDMzLjE3NVowBIACAfSggdSkgdEwgc4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1p
# Y3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjo0RDJGLUUzREQtQkVFRjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaCCEV8wggcQMIIE+KADAgECAhMzAAABsKHjgzLojTvAAAEA
# AAGwMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTIyMDMwMjE4NTE0MloXDTIzMDUxMTE4NTE0Mlowgc4xCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVy
# YXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo0RDJG
# LUUzREQtQkVFRjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJzGbTsM19KCnQc5RC7V
# oglySXMKLut/yWWPQWD6VAlJgBexVKx2n1zgX3o/xA2ZgZ/NFGcgNDRCJ7mJiOeW
# 7xeHnoNXPlg7EjYWulfk3oOAj6a7O15GvckpYsvLcx+o8Se8CrfIb40EJ8W0Qx4T
# IXf0yDwAJ4/qO94dJ/hGabeJYg4Gp0G0uQmhwFovAWTHlD1ci+sp36AxT9wIhHqw
# /70tzMvrnDF7jmQjaVUPnjOgPOyFWZiVr7e6rkSl4anT1tLv23SWhXqMs14wolv4
# ZeQcWP84rV2Frr1KbwkIa0vlHjlv4xG9a6nlTRfo0CYUQDfrZOMXCI5KcAN2BZ6f
# Vb09qtCdsWdNNxB0y4lwMjnuNmx85FNfzPcMZjmwAF9aRUUMLHv626I67t1+dZoV
# PpKqfSNmGtVt9DETWkmDipnGg4+BdTplvgGVq9F3KZPDFHabxbLpSWfXW90MZXOu
# FH8yCMzDJNUzeyAqytFFyLZir3j4T1Gx7lReCOUPw1puVzbWKspV7ModZjtN/IUW
# dVIdk3HPp4QN1wwdVvdXOsYdhG8kgjGyAZID5or7C/75hyKQb5F0Z+Ee04uY9K+s
# DZ3l3z8TQZWAfYurbZCMWWnmJVsu5V4PR5PO+U6D7tAtMvMULNYibT9+sxVZK/WQ
# er2JJ9q3Z7ljFs4lgpmfc6AVAgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQUOt8BJDcB
# Jm4dy6ASZHrXIEfWNj8wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIw
# XwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3Js
# MGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcD
# CDANBgkqhkiG9w0BAQsFAAOCAgEA3XPih5sNtUfAyLnlXq6MZSpCh0TF+uG+nhIJ
# 44//cMcQGEViZ2N263NwvrQjCFOni/+oxf76jcmUhcKWLXk9hhd7vfFBhZZzcF5a
# Ns07Uligs24pveasFuhmJ4y82OYm1G1ORYsFndZdvF//NrYGxaXqUNlRHQlskV/p
# mccqO3Oi6wLHcPB1/WRTLJtYbIiiwE/uTFEFEL45wWD/1mTCPEkFX3hliXEypxXz
# dZ1k6XqGTysGAtLXUB7IC6CH26YygKQuXG8QjcJBAUG/9F3yNZOdbFvn7FinZyNc
# IVLxld7h0bELfQzhIjelj+5sBKhLcaFU0vbjbmf0WENgFmnyJNiMrL7/2FYOLsgi
# QDbJx6Dpy1EfvuRGsdL5f+jVVds5oMaKrhxgV7oEobrA6Z56nnWYN47swwouucHf
# 0ym1DQWHy2DHOFRRN7yv++zes0GSCOjRRYPK7rr1Qc+O3nsd604Ogm5nR9QqhOOc
# 2OQTrvtSgXBStu5vF6W8DPcsns53cQ4gdcR1Y9Ng5IYEwxCZzzYsq9oalxlH+ZH/
# A6J7ZMeSNKNkrXPx6ppFXUxHuC3k4mzVyZNGWP/ZgcUOi2qV03m6Imytvi1kfGe6
# YdCh32POgWeNH9lfKt+d1M+q4IhJLmX0E2ZZICYEb9Q0romeMX8GZ+cbhuNsFimJ
# ga/fjjswggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3
# DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIw
# MAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAx
# MDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# 5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/
# XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1
# hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7
# M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3K
# Ni1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy
# 1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF80
# 3RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQc
# NIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahha
# YQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkL
# iWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV
# 2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIG
# CSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUp
# zxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBT
# MFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYI
# KwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186a
# GMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsG
# AQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcN
# AQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1
# OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYA
# A7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbz
# aN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6L
# GYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3m
# Sj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0
# SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxko
# JLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFm
# PWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC482
# 2rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7
# vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIC0jCC
# AjsCAQEwgfyhgdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNv
# MSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo0RDJGLUUzREQtQkVFRjElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA
# Ap4vkN3fD5FNBVYZklZeS/JFPBiggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOdf5kMwIhgPMjAyMzAxMDQxNTQ5
# MjNaGA8yMDIzMDEwNTE1NDkyM1owdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA51/m
# QwIBADAKAgEAAgIDjgIB/zAHAgEAAgIRVTAKAgUA52E3wwIBADA2BgorBgEEAYRZ
# CgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0G
# CSqGSIb3DQEBBQUAA4GBAB9Qx7nRY02UL8OJ8SRz6pHCCjKvB/7nm879ctl29moY
# J6OaxZHKRwevqN5AYZarpkVFfR7zoKuXq4ugpj/v6+REFGZwMR4lYrsdyysl3dzo
# xw8f8yp5ooNmDbFchRGad6aDY2C6VIhhNegwlQ9x2wC1H/2Q0M5hTyKbRYNIX9nN
# MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
# AAGwoeODMuiNO8AAAQAAAbAwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
# AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgzsBiiLsJ7fMqBX691cbl
# yGU3yRSM2fI9KcqvdnoG2qcwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDN
# BgtDd8uf9KTjGf1G67IfKmcNFJmeWTd6ilAy5xWEoDCBmDCBgKR+MHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABsKHjgzLojTvAAAEAAAGwMCIEIHV7
# T2eBaufV028n9tP6Qu+32l4P3xFYDwncgZzjVaIIMA0GCSqGSIb3DQEBCwUABIIC
# AEkdkz5/4tllmF7UWSa28Fl97p/fKAc81KpsKU6enqgEZg8s0F+zgkvLYXwK1mPT
# N5jGl+Lbz6RmotAfa/IHD3zX0bYKAnTftPXOJjOChyK+kNdbbVbFydvJ717w2eNk
# 4bkXD4K8YZ/pOaREvIT2AcGgiYZlfBWRRsHT4H8QNq4VMU+Ik8/EDQr8xbchit5P
# 8W4Y2S7IVAhFMjOQNPNBVU3Ue6kINqdJBHrJvL92GJyjm0HM+iQJgfk8Y4Ig+9Bj
# mR84BCtyoLiIxEcu7swtrS/os7bRYQtVEQ946exnYgURL7I2/gcJU4PDMX2HZ2dZ
# A09XNZvj+H5o0Qo9DwAByeYq1MVpvQxvyk0ovQfwKYs6GTyByVgaCi4G8uSZFwVJ
# 70GABSsrYsrmtDqPTrCl45j5J4r58Vb8L/YMkbLxqxdMzLlKeAR1oob03BrlNU5H
# 6Id2aUusAWM/Ui9w14wSFckorx8RHJuySrMeAI2i14rXJ/GCiZHIjs5YygChrwuU
# 0dJ8xQB6Kh4chH3LZ/qA6vivLBeLwx/mbIaaWxkS8DAexPEPR2m/UXlGI8TN8V/O
# BdyBUnRYJuGq2XFnuwJxamTACc45vA+XEvLwOAkUPaMXZp1qL1tjquDL/PZcJBwa
# m2O/2g928lwpjbnYZhWskZwh5a+zInXCdu5l/r8ivQc2
# SIG # End signature block
