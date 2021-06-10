Function New-DSCClientConfiguration {
    <#
		.SYNOPSIS
			Setup a new DSC Pull client

		.DESCRIPTION
			This will setup a new DSC pull client

		.PARAMETER DSCSMBServer
			DSC configuration server

		.PARAMETER DSCSharedFolder
			DSC configuration server share

		.PARAMETER RemoteDrive
			Remote network share for DSC configuration server

		.PARAMETER RefreshConfiguration
			Reapply current DSC configuration

		.PARAMETER GetCurrentConfig
			Display the current DSC configuration

		.PARAMETER GetEventLogs
			Display the events from the Microsoft-Windows-Dsc/Operational event log

		.PARAMETER NumberOfEvents
			Default number of events to display is 10

		.EXAMPLE
			PS C:\> New-DSCClientConfiguration -ServerName '192.168.1.11'

		.EXAMPLE
			PS C:\> New-DSCClientConfiguration -RefreshConfiguration

		.EXAMPLE
			PS C:\> New-DSCClientConfiguration -RefreshConfiguration -Verbose

		.NOTES
			https://docs.microsoft.com/en-us/powershell/scripting/dsc/overview/overview?view=powershell-7.1
	#>

    [cmdletbinding()]
    param(
        [string]
        [parameter(HelpMessage = 'This is the DSC server that will be configured as the DSC Pull server')]
        $DSCSMBServer = 'dc1',

        [string]
        $DSCSharedFolder = 'DscSmbShare',

        [parameter(HelpMessage = 'Folder mapping for this machine that will be used as the conenction to the DSC pull server')]
        [string]
        $RemoteDrive = "z:",

        [parameter(HelpMessage = 'Reapply the current DSC configuration to the machine')]
        [switch]
        $RefreshConfiguration,

        [parameter(ParameterSetName = 'Logs')]
        [switch]
        $GetEventLogs,

        [parameter(ParameterSetName = 'Logs')]
        [int]
        $NumberOfEvents = 10,

        [switch]
        $GetCurrentConfigFiles,

        [switch]
        $GetCurrentConfig
    )

    begin {
        $runningLocally = $false
        $parameters = $PSBoundParameters
        $script:ModuleRoot = $PSScriptRoot
        Set-Location $script:ModuleRoot
        . .\InstallPreReqs.ps1
    }

    process {
        try {
            if ($GetCurrentConfigFiles) {
                Invoke-Item 'C:\Windows\system32\configuration\'
                return
            }

            if ($GetEventLogs) {
                Get-WinEvent -LogName "Microsoft-Windows-Dsc/Operational" -MaxEvents $NumberOfEvents
                return
            }
			
            if ($GetCurrentConfig) {
                Get-DscConfig
                return
            }
	
            if ($RefreshConfiguration) {
                Write-Host -ForegroundColor Yellow "`nRefreshing configuration"
                if ($parameters.ContainsKey('Verbose')) {
                    Start-DscConfiguration -UseExisting -Verbose -Force
                }
                else {
                    Start-DscConfiguration -UseExisting -Force > $null
                }
	
                Write-Host -ForegroundColor Green "Configuration re-applied!"
                return
            }
			
            Write-Host -ForegroundColor Cyan "`nStage 1 - Starting DSC client configuration"
            Write-Host -ForegroundColor Green "Testing remote connection to $DSCSMBServer"
			
            $connection = Test-NetConnection -ComputerName $DSCSMBServer -ErrorAction Stop
            if ($connection) {
                Write-Host -ForegroundColor Green "Network connection is good!"
                if (($connection.PingSucceeded -eq 'True') -and $connection.RemoteAddress -ne '::1') {
                    $newConnection = Join-Path -Path "\\" -ChildPath $connection.RemoteAddress
                    $DSCSMBConfigLocalation = Join-Path -Path $newConnection -ChildPath $DSCSharedFolder
                    Write-Host -ForegroundColor Green "Checking for network shared foler on $DSCSMBServer"

                    if ((Get-PSDrive | Where-Object Name -eq "Z")) {
                        Write-Host -ForegroundColor Green "Mapped connection found!"
                    }
                    else {
                        try {
                            Write-Host -ForegroundColor Yellow "No mapped drive found. Mapping $RemoteDrive drive to $DSCSMBServer"
                            net use $RemoteDrive $DSCSMBConfigLocalation
                        }
                        catch {
                            Throw "Unable to create mapped drive $RemoteDrive on $DSCSMBConfigLocalation"
                            return
                        }
                    }
                }
                else {
                    Write-Host -ForegroundColor Green "Running on localhost!"
                    $DSCSMBConfigLocalation = "\\" + $DSCSMBServer + '\' + 'DscSmbShare' + '\'
                    $runningLocally = $true
                }
            }
            else {
                Throw "No DSC server found."
                return
            }

        }
        catch {
            Write-Host -ForegroundColor Red "Error: $_"
            return
        }

        try {
            Write-Host -ForegroundColor Green "Obtaining MOF Files on from $DSCSMBConfigLocalation"
            if ($runningLocally) {
                $mofFiles = Get-ChildItem -Path $DSCSMBConfigLocalation -Filter "*.mof" 
                if ($mofFiles.Count -eq 0 -and $runningLocally ) { Throw "Unable to retrieve mof files from $DSCSMBConfigLocalation" }
            }
            else {
                $mofFiles = Get-ChildItem -Path $RemoteDrive -Filter "*.mof" 
                if (($mofFiles.Count -eq 0) -and (-NOT ($runningLocally))) { Throw "Unable to retrieve mof files from $RemoteDrive on $DSCSMBConfigLocalation" }			
            }  

            Write-Host -ForegroundColor Green "$($mofFiles.Count) configurations files found $DSCSMBConfigLocalation"
		
        }
        catch {
            Write-Host -ForegroundColor Red "Error: $_"
            return
        }

        try {
            $counter = 0
            $customObjects = @()
            foreach ($mofFile in $mofFiles) {
                if ($runningLocally) { $content = Get-Content -Path "$DSCSMBConfigLocalation\$mofFile" -ErrorAction Stop }
                else { $content = Get-Content -Path "$RemoteDrive\$mofFile" -ErrorAction Stop }
				
                foreach ($line in $content) {
                    if ( $line.contains("TargetNode")) {
                        $temp = $line.Split("'")
                        $targetHode = $temp[1]
                    }

                    if ($line -match "ConfigurationName =") {
                        $temp = $line.Split('"')
                        $configurationName = $temp[1]
                    }
                }

                $customObjects += [PSCustomObject]@{
                    ID                = $counter
                    ConfigurationName = $configurationName
                    TargetNode        = $targetHode
                    Guid              = $mofFile.BaseName
                }
                $counter++
            }
        }
        catch {
            Write-Host -ForegroundColor Red "Error: $_"
            return
        }

        $customObjects | Format-Table
        $choice = Read-Host -Prompt "Which configuration would you like to configure?"

        [DSCLocalConfigurationManager()]
        configuration PullClientConfigID
        {
            Node localhost
            {
                Settings {
                    ConfigurationMode    = "ApplyAndAutoCorrect"
                    RefreshMode          = 'Pull'
                    ConfigurationID      = $customObjects[$choice].Guid
                    RefreshFrequencyMins = 30
                    RebootNodeIfNeeded   = $true
                }

                ConfigurationRepositoryShare DSCWeb {
                    SourcePath = $DSCSMBConfigLocalation
                }
            }
        }
        PullClientConfigID

        try {
            Write-Host -ForegroundColor Cyan "`nStage 2 - Setting configuration: $($customObjects[$choice].Guid) to the local DSC configuration manager"
            if ($parameters.ContainsKey('Verbose')) { Set-DSCLocalConfigurationManager -Path $script:ModuleRoot\PullClientConfigID\ -Verbose -Force	}
            else { Set-DSCLocalConfigurationManager -Path $script:ModuleRoot\PullClientConfigID\ -Force	}
            if ($parameters.ContainsKey('Verbose')) { Update-DscConfiguration -Verbose }
            else {
                Update-DscConfiguration > $null
                Write-Host -ForegroundColor Green "Configuration applied!"
            }
			
            Get-DscConfig
        }
        catch {
            Write-Host -ForegroundColor Red "Error: $_"
        }
    }

    end {
        if (-NOT($GetEventLogs)) {
            Write-Host -ForegroundColor Green "`rDSC client configuration finished"
        }
    }
}

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
	
        if ($failures) {
            Write-Host -ForegroundColor Yellow "Unable to get DSCConfiguration as job is still running. Please Get-Job to verify job status."
        }
        else { Get-DSCConfiguration | Format-Table }
    }

    end {
        Write-Host -ForegroundColor Green "Completed"
    }
}
