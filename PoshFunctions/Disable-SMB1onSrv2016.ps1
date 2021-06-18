function Disable-SMB1onSrv2016 {
    <#
    .SYNOPSIS
        Disable SMB1 on Windows Server 2016

    .DESCRIPTION
        Checks the value of SMB1 and disable it if enabled
    
    .EXAMPLE
        None

    .NOTES
        Disabling the server configuration the server will no longer offer SMB v1 shares. The SMB client however is still able to connect to external SMB v1 shares on another server
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    begin {
        Start-Transcript -Path "C:\ConfigureDSC\Logging\Disable-SMB1onSrv2016.Log" -NoClobber -Append
        Write-Host -ForegroundColor Green 'Starting SMB Version 1 check'
    }

    process {
        try {
            $ServerVersion = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption

            if ($ServerVersion -like "Microsoft Windows Server 2016*") {
                Write-Host -ForegroundColor Green "Server OS: Windows Server 2016. Checking for SMB Version 1"

                $value = Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableSMB1Protocol
                if ($value) {
                    Write-Host -ForegroundColor Yellow "SMB Version 1 enabled. Disabling"
                    Set-SmbServerConfiguration -EnableSMB1Protocol $false

                    # Disable SMB 1 click check
                    $disabled = Invoke-Command -ComputerName Localhost -ScriptBlock { 
                        sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi
                        sc.exe config mrxsmb10 start= disabled
                    } -ErrorAction SilentlyContinue

                    if ($disabled[1].contains('FAILED')) {
                        Write-Host -ForegroundColor Green $($disabled[3])
                    }
                }
            }
        }
        catch {
            Write-Host -ForegroundColor Red "Error $_"
        }

    }
    end {
        Write-Host -ForegroundColor Green "SMB Version 1 check finished"
        Stop-Transcript
    }
}