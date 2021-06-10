function InstallPreReqs {
	<#
	.SYNOPSIS
		Install system prerequisites

	.DESCRIPTION
		This will install all PowerShell prerequisite as well as other workloads

	.PARAMETER Exchange
		Install Exchange prerequisites

	.EXAMPLE
		PS C:\> InstallPreReqs

	.EXAMPLE
		PS C:\> InstallPreReqs -Exchange

	.NOTES
		None
	#>
	
	[cmdletbinding()]
	param(
		[switch]
		$Exchange
	)

	begin {
		Start-Transcript -Path "C:\ConfigureDSC\Logging\InstallPreReqs.Log" -NoClobber -Append
		Write-Host -ForegroundColor Green "Checking pre-reqs"
		$executionPolicy = Get-ExecutionPolicy
		Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

		# Software urls
		$wmfUrl = 'https://go.microsoft.com/fwlink/?linkid=839516'
		$ucUrl = 'https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe'
	}

	process {
		$modules = @(
			@('PowerShellGet', 'AutomatedLab', 'ExchangeOnlineManagement', 'AzureAD', 'AzureADPreview', 'PSMDATP', 'Az.Accounts'),
			@('PSDesiredStateConfiguration', 'xPSDesiredStateConfiguration', 'PowerShellModule', 'PSModule', 'PSDscResources', 'xSmbShare' , 'cNtfsAccessControl')
		)
	
		Write-Host -ForegroundColor Green "Checking for TLS 1.2"
		if (([Net.ServicePointManager]::SecurityProtocol -match 'TLS12')) { Write-Host -ForegroundColor Green "TLS1.2 found!" } else {
			Write-Host -ForegroundColor Yellow "TLS1.2 not found! Adding it."
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::SSl3
		}

		Write-Host -ForegroundColor Green "Checking PowerShell Version. Minimum PowerShell version need is 5.1"
		$psVersion = $PSVersionTable.PSVersion.ToString()
		
		if ($psVersion -eq '4.0') {
			Write-Host -ForegroundColor Green "PowerShell version $($psVersion) found. Installing Windows Management Framework 5"

			if (Install-SoftwareComponent -SoftwarePackage 'Win8.1AndW2K12R2-KB3191564-x64.msu' -Url $wmfUrl) {
				Write-Host -ForegroundColor Green "You must reboot your machine to finishing installing Windows Management Framework 5"
				return
			}
		}
		else {
			Write-Host -ForegroundColor Green "PowerShell version $($psVersion) found"
		}

		# If we are on the exchange server create the exchange admin account
		if ($env:computername -eq 'DC1') {
			$password = New-Guid
			$groups = @('Administrators', 'Domain Admins', 'Enterprise Admins', 'Remote Desktop Users', 'Schema Admins')

			try {
				if (Get-ADUser -Identity ExchAdmin -ErrorAction SilentlyContinue) {
					Write-Host -ForegroundColor Green 'Exchange Administrator found.'
				}
			}
			catch {
				Write-Host -ForegroundColor Red 'No Exchange Administrator account found. Creating new account!'

				if (New-ADUser -Name ExchAdmin -AccountPassword (ConvertTo-SecureString -String $password -AsPlainText -Force) -ChangePasswordAtLogon $true -Description 'Exchange Administrator account') {
					Write-Host -ForegroundColor Yellow "Exchange PreReq - Creating Exchange Administrator account"
				}
				else {
					Write-Host -ForegroundColor Green "Exchange Administrator account created!"
				}
				
				$groups.foreach( { Add-ADGroupMember -Identity $group -Members TestUser } )
			}
		}

		if ($Exchange) {
			
			Write-Host -ForegroundColor Yellow "Exchange PreReq - Installing Unified Communications Managed API 4.0 Runtime"
			
			if (Install-SoftwareComponent -SoftwarePackage 'UcmaRuntimeSetup.exe' -Url $ucUrl) {
				Write-Host -ForegroundColor Green "Unified Communications Managed API 4.0 Runtime installed"
			}
		
			Write-Host -ForegroundColor Green "Exchange PreReq - Checking to see if .Net Framework 4.8 is installed"
			$versions = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse -ErrorAction SilentlyContinue | Get-ItemProperty -Name Version -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^(?!S)\p{L}' } | Select-Object Version | Sort-Object -Descending Version
			if ($versions[0].Version -gt '4.0') { Write-Host -ForegroundColor Green ".Net Framework 4.8 installed!" }
			else { Write-Host -ForegroundColor Yellow ".Net Framework 4.8 not installed and is needed for Exchange Server!"	} 
		}

		Write-Host -ForegroundColor Green "Checking for Nuget Package Provider"
		$nuget = Get-PackageProvider -Name Nuget -ListAvailable -ErrorAction SilentlyContinue -ErrorVariable noNuget
			
		if ($noNuget.CategoryInfo.Category -eq 'ObjectNotFound') {
			Write-Host -ForegroundColor Yellow "Nuget Package Provider not found. Installing"
			Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.208 -Force
		}
		else {
			Write-Host -ForegroundColor Green "Nuget Package Provider version: $($nuget[0].version.ToString()) found"
		}
		
		Write-Host -ForegroundColor Green "Starting PowerShell module check and installation"
		try {
			foreach ($array in $modules) {
				foreach ($module in $array) {
					Write-Host -ForegroundColor Green "Checking for PowerShell module: $module"

					if (($module -eq 'PowerShellGet') -and (Get-Module -name $module -ListAvailable)[0].Version.ToString() -eq '1.0.0.1') {
						Install-Module $module -RequiredVersion 2.2.4 -SkipPublisherCheck -Force
						Remove-Module $module
						Import-Module $module -force
					}

					If (-NOT (Get-Module -Name $module -ListAvailable)) {
						Install-Module -Name $module -AllowClobber -Force 
						Write-Host -ForegroundColor Yellow "PowerShell Module: $module installed!"
					}
				}
			}
		}
		catch {
			Write-Host -ForegroundColor Red "Error: $_"
			return
		}
	}
	
	end {
		Write-Host -ForegroundColor Green "Pre-reqs checks finished."
		Set-ExecutionPolicy -ExecutionPolicy $executionpolicy -Force	
		Stop-Transcript
	}
}

function Install-SoftwareComponent {
	<#
		.SYNOPSIS
			Install software component

		.DESCRIPTION
			Install the necessary software components needed for workkoads

		.PARAMETER SofwarePackage
			Software component to install

		.EXAMPLE
			None

		.NOTES
			None
	#>

	[cmdletbinding()]
	param(
	
		[string]
		$SoftwarePackage,

		[string]
		$Url
	)

	process {
		try {
			$outpath = "$env:TEMP\$SoftwarePackage"
			Invoke-WebRequest -Uri $Url -OutFile $outpath
		
			# Install Windows Framework 5.1
			$cmdArguements = '/quiet /norestart'
			Start-Process -Filepath "$env:TEMP\$SoftwarePackage" -ArgumentList $cmdArguements -Wait
			$true
		}
		catch {
			Write-Host -ForegroundColor Red "Error $_"
			$false
		}
	}
}

InstallPreReqs
