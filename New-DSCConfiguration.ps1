function New-DSCConfiguration {
	<#
	.SYNOPSIS
		Setup a new DSC Pull server

	.DESCRIPTION
		This will setup a new DSC pull server & share, create all configuration files found, rename them and publish to the share

	.PARAMETER ServerName
		Server name of the file you are publishing on. Default is 'Localhost'

	.PARAMETER DSCSharedFolder
		DSC file share name

	.PARAMETER RootPath
		Config root path

	.PARAMETER GetEventLogs
		Dispaly the events from the Microsoft-Windows-Dsc/Operational event log

	.PARAMETER NumberOfEvents
		Default number of events to display is 10

	.PARAMETER CreateDSCFileShare
		Allows to skip the creation of creating the file share if you just want to configure new configuration files and publish them

	.EXAMPLE
		PS C:\> New-DSCConfiguration -ServerName 'TestServer' -RootPath "c:\DSCShare"

	.EXAMPLE
		PS C:\> New-DSCConfiguration -ServerName 'TestServer' -CreateDSCFileShare

	.NOTES
		https://docs.microsoft.com/en-us/powershell/scripting/dsc/overview/overview?view=powershell-7.1
	#>

	[cmdletbinding()]
	param(
		[parameter(HelpMessage = 'This is the DSC server that we are connecting too')]
		[string]
		$ServerName = "localhost",

		[parameter(HelpMessage = 'Name of the DSC Pull server share')]
		[string]
		$DSCSharedFolder = 'C:\DscSmbShare',

		[parameter(HelpMessage = 'Root path for all DSC files')]
		[string]
		$RootPath = 'C:\ConfigureDSC',

		[parameter(ParameterSetName = 'Logs')]
		[switch]
		$GetEventLogs,

		[parameter(ParameterSetName = 'Logs', HelpMessage = 'Number of event logs to retrieve. Default = 10')]
		[int]
		$NumberOfEvents = 10,

		[parameter(HelpMessage = 'Switch for creating the root DSC Pull share')]
		[switch]
		$CreateDSCFileShare
	)

	begin {
		Start-Transcript -Path "C:\ConfigureDSC\Logging\NewDSCConfiguration.Log" -NoClobber -Append
		$parameters = $PSBoundParameters
		$script:ModuleRoot = $PSScriptRoot
		Write-Host -ForegroundColor Green "Ensuring TLS1.2 is enabled"
		if (-NOT ([Net.ServicePointManager]::SecurityProtocol -match 'Tls12')) {
			Write-Host -ForegroundColor Yellow "Adding TLS1.2 to server Security Protocol"
			try {
				[Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
			}
			catch { } # Report nothing because  it's already at the correct version
		}
	}

	process {
		try {
			Write-Host -ForegroundColor Cyan "`nStage 1 - Starting DSC pull server configuration"
			. .\InstallPreReqs.ps1
			InstallPreReqs.ps1

			if ($GetEventLogs) {
				Get-WinEvent -LogName "Microsoft-Windows-Dsc/Operational" -MaxEvents $NumberOfEvents | Format-List
				return
			}

			if ($CreateDSCFileShare) {
				Write-Host -ForegroundColor Yellow "Creating DSC Pull Server Share"

				if ($parameters.ContainsKey('Verbose')) { . .\ServerConfigFiles\ConfigureShares.ps1 }
				else { . .\ServerConfigFiles\ConfigureShares.ps1 > $null }

				Start-Sleep -Seconds 5
				Start-DscConfiguration -Path $RootPath\ConfigureShares -Wait -Verbose -Force
			}
			else {
				Write-Host -ForegroundColor Magenta "Skipping creation of DSC Pull Server Share"
			}
		}
		catch {
			Write-Host -ForegroundColor Red "Error: $_"
			return
		}

		Write-Host -ForegroundColor Cyan "`nStage 2 - Authoring MOF Files"
		$files = @(Get-ChildItem "$($script:ModuleRoot)\ConfigurationFiles\*.ps1" -ErrorAction SilentlyContinue -ErrorVariable Failures)
		Write-Host -ForegroundColor Green "Found: $($files.Count) configuration files"
		foreach ($file in $files) {

			try {
				Write-Host -ForegroundColor Green "Compiling MOF file $($file.Name)"
				if ($parameters.ContainsKey('Verbose')) { . $file.FullName -ServerName $ServerName } else {
					. $file.FullName -ServerName $ServerName > $null
				}
			}
			catch {
				"ERROR: Error with $($file.FullName). Please check file and fix errors.`n$($error[1].Exception.Message)"
				return
			}

			# Construct the path so we can check for the existence of the file before renaming it
			$currentFileWithPath = Join-Path -Path "$RootPath\$($file.BaseName)" -ChildPath "$ServerName.mof"
            
			$counter = 0
			while (-NOT (Test-Path -Path $currentFileWithPath -PathType Leaf)) {
				Start-Sleep -Seconds 2
				Write-Host -ForegroundColor Green "Waiting for MOF compile complete"
				if ($counter -eq 5) {
					Write-Host -ForegroundColor Red "Error compiling configuration files. Please check configuration files"
					return
				}
				$counter ++
			}

			try {
				# Test to make sure file exists before we rename the file
				Write-Host -ForegroundColor Yellow "Renaming MOF file: $($file.Name)"
				$guid = New-Guid
				$newName = Rename-Item -Path $currentFileWithPath -NewName "$guid.mof" -ErrorAction SilentlyContinue -ErrorVariable Failures -PassThru
				Write-Host -ForegroundColor Green "New MOF file name: $($newName)"
			}
			catch {
				Write-Host -ForegroundColor Red "Error: $_"
				return
			}
		}

		Write-Host -ForegroundColor Cyan "`nStage 3 - Staging MOF Files on DSCShare"
		$dirs = @(Get-ChildItem -Path $RootPath -Directory)

		foreach ($dir in $dirs) {
			if (($dir.Name -eq 'ConfigurationFiles') -or ($dir.Name -eq 'ConfigureDSCShare') -or ($dir.Name -eq 'ServerConfigFiles')) { continue }
			else {
				try {
					Copy-Item -Path $dir\*.mof -Destination $DSCSharedFolder
					Write-Host -ForegroundColor Yellow "Copying $($dir.Name) MOF file to staging area $($DSCSharedFolder)"
				}
				catch {
					"ERROR: Mof files failed to copy to share $DSCSharedFolder. LocalDSC won't work until these files are created.`rException Message: $_.Exception.Message"
					return
				}
			}
		}

		try {
			Write-Host -ForegroundColor Cyan "`nStage 4 - Creating DscChecksum for all mof files on $($DSCSharedFolder)"
			New-DscChecksum -Path $DSCSharedFolder -ErrorAction Stop
			$checksumFiles = @(Get-ChildItem -Path $DSCSharedFolder\*.mof.checksum)
			Write-Host -ForegroundColor Yellow "$($checksumFiles.Count) mof.checksum files created on $($DSCSharedFolder)"
		}
		catch {
			"ERROR: $_.Exception.Message`nChecksum files failed to create. LocalDSC won't work until these files are created."
			return
		}
	}

	end {
		if ($Failures.Count -gt 0) {
			Write-Host -ForegroundColor Red "`rDSC Pull Server Configuration Finished with $($Failures.Count) errors"

			$counter = 0
			foreach ($failure in $failures) {
				Write-Host  -ForegroundColor Red "Error $($counter): $failure.exception.message"
				$counter++
			}
		}
		else { Write-Host -ForegroundColor Green "`rDSC pull server configuration finished" }
		Stop-Transcript
	}
}