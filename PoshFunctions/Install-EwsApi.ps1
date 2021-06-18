function Install-EwsApi {
    <#
    .SYNOPSIS
        Install the EWS 2.0 API
    
    .DESCRIPTION
        Installs the Exchange Web Services package
    
    .EXAMPLE
        None
    
    .NOTES
        More information: Install-Package Microsoft.Exchange.WebServices -Version 2.2.0
    #>

    [CmdletBinding()]
    param ()
    
    begin {
        Start-Transcript -Path "C:\ConfigureDSC\Logging\Install-EwsApi.Log" -NoClobber -Append
        Write-Host -ForegroundColor Green  'Starting EWS API check'
    }
    
    process {
        if (-NOT (Get-PackageSource | Where-Object Name -eq 'Nuget')) { 
            Write-Host -ForegroundColor Yellow "Nuget package source not found. Registering"
            $null = Register-PackageSource -Name NuGet -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Force 
            
        }
        else {
            Write-Host -ForegroundColor Green "Nuget found and registered as a package source provider"
        } 
         
        if (-NOT (Get-Package | Where-Object Name -eq 'Microsoft.Exchange.WebServices')) {
            Write-Host -ForegroundColor Yellow "Nuget package source not found. Registering"
            Install-Package Microsoft.Exchange.WebServices -RequiredVersion 2.2.0 -Force 
        }
        else {
            Write-Host -ForegroundColor Green "EWS API found"
        }
    }
    
    end {
        Write-Host -ForegroundColor Green  'EWS API check finished'
    }
}