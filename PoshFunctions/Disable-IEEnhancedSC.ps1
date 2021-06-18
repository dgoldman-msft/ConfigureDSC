function Disable-IEEnhancedSC {
    <#
    .SYNOPSIS
        Check the state of IE Enhanced Security Configuration

    .DESCRIPTION
        Checks to see if IE Enhanced Security Configuration is disables it for administrators
    .
    .EXAMPLE
        None

    .NOTES
        None
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [switch]
        $Revert
    )

    begin {
        Start-Transcript -Path "C:\ConfigureDSC\Logging\Disable-IEEnhancedSC.Log" -NoClobber -Append
        Write-Host -ForegroundColor Green  'Starting IE Enhanced Security Configuration check'
        $adminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    }

    process {
        try {
            $adminRegKey = Get-ItemProperty -Path $adminKey -Name "IsInstalled" -ErrorAction SilentlyContinue

            if (($Revert -and $adminRegKey.IsInstalled -eq $false)) {
                Write-Host -ForegroundColor Green "Reverting IE Enhanced Security for Administrators: Enabling for Administrators"
                Set-ItemProperty -Path $adminKey -Name "IsInstalled" -Value $false
            }

            if ($adminRegKey.IsInstalled -eq $true) {
                Write-Host -ForegroundColor Green "IE Enhanced Security for Administrators: Enabled. Disabling for Administrators"
                Set-ItemProperty -Path $adminKey -Name "IsInstalled" -Value $false
                Write-Host -ForegroundColor Yellow "IE Enhanced Security now disabled for Administrators"
            }
            else { 
                Write-Host -ForegroundColor Green "Checking IE Enhanced already disabled" 
            }
        }
        catch {
            Write-Host -ForegroundColor Red "Error $_"
        }

    }
    end {
        Write-Host -ForegroundColor Green "Finished IE Enhanced Security Configuration check"
        Stop-Transcript
    }
}