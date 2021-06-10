Function Get-DscConfig {
    <#
    .SYNOPSIS
        Get DSC Configuration

    .DESCRIPTION
    Get the DSC configuration from the local machine

    .EXAMPLE
        PS C:\> Get-DSCConfiguration

    .NOTES
        Override method for Get-DSCConfiguration which contains error checking
    #>
    
    [cmdletbinding()]
    param()
    
    begin {
        Write-Host -ForegroundColor Green "Getting current DSC configuration"
    }
    Process {
        Get-DSCConfiguration -ErrorAction SilentlyContinue -ErrorVariable Failures | Format-Table 
    
        if () {
            Write-Host -ForegroundColor Yellow "Unable to get DSCConfiguration as job is still running. Please Get-Job to verify job status."
        }
        else { Get-DSCConfiguration | Format-Table }
    }

    end {
        Write-Host -ForegroundColor Green "Completed"
    }
}
