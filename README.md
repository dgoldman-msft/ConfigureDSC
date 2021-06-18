# New-DSCConfiguration

## This helper script will automate the install and configuration of a simple DSC SMB server

NOTE: you can use this is a workstation non domain joined scenareo, however this will work better for machines in a domain.

1. Select copy and download a zip file of this repository.
2. Create a folder called ConfigureDSC
3. Extract the contents of the zip file into the directory.
4. Navigate to the c:\ConfigureDSC

### This is the default directory structure

> C:.<br>
│   Get-DscConfig.ps1<br>
│   InstallPreReqs.ps1<br>
│   LICENSE<br>
│   New-DSCClientConfiguration.ps1<br>
│   New-DSCConfiguration.ps1<br>
│   README.md<br>
│<br>
├───ConfigurationFiles<br>
│       ConfigureExchangePreReqs.ps1<br>
│       ConfigurePSModules.ps1<br>
│<br>
├───docs<br>
│   │   Get-DscConfig.md<br>
│   │   Install-SoftwareComponent.md<br>
│   │   InstallPreReqs.md<br>
│   │   New-DSCClientConfiguration.md<br>
│   │   New-DSCConfiguration.md<br>
│   │<br>
│   └───en-US<br>
│           rename-me-help.xml<br>
│<br>
└───ServerConfigFiles<br>
        ConfigureShares.ps1

5. Open PowerShell and run . .\New-DSCCConfiguration.ps1

> This will load the New-DSCConfiguration PowerShell script in to the local interactive PowerShell session

6. Run New-DSCConfiguration -CreateDSCFileShare

> This will create the default the c:\DSCSMBShare shared folder and apply all necessary permissions.

a. This will call InstallPreReqs.ps1 script which will do the following:

    i. Create a directory called c:\CreateDSC\Logging
    ii. Start a transcript of all actions
    iii. Set the execution policy so we can download software<br>
    iv. Enable-PSremoting
    v. Install PowerShell and DSC modules in the following location: c:\Program Files\WindowsPowerShel\Modules
    vi. Check if TLS12 is present and if not set it
    vii. Checks for PowerShell Version 5.1 on Windows server platforms. If the version is 4.0 we will install Windows Management Framework 5.1
        1 - If we are on the DC we will create the ExchangeAdmin account and add the account to all relevant groups needed for Exchange installation actions.
	    2 - If ran from a client with the -Exchange switch we will install the Unified Communications Managed API 4.0 Runtime
        3 - Check to see if .Net Framework 4.8 is installed
    viii. Checks for Nuget (new PowerShell setup on a new machine)
    ix. Registered the PackageProvider
    x. Start the install of all modules
    xi. Reset the execution policy back to the default
    		
> 1. Inside c:\DSCSMBShare you will see two files (a mof file and checksum file) for each configuration generated.
> 2. All configuration files to be pulled by the clients will be stored in the ConfigurationFiles folder.

# New-DSClientConfiguration

## This helper script will automate the install and configuration of a simple DSC client

From a client machine after the machine has been joined to the domain

1. Connect to \\\\YourDSCServer\Software\ConfigureDSC

> You will be prompted for your administrator account and admin account password. Make sure you save the network connection so you are not asked in the future

2. Create a new directory called C:\ConfigureDsC
3. Copy both files InstallPreReqs.ps1 and New-DSCClientConfiguration.ps1 to your local c:\ConfigureDSC folder
4. Run . .\InstallPreReqs.ps1

> This will import the InstallPreReqs method in to the local PowerShell session. This needs to be ran first on the client machine to install dependencies for PowerShell and the DSC framework.

   1. For Exchange Setup run: InstallPreReqs -Exchange
   2. For non-exchange setup: run InstallPreReqqs -Verbose

	i. This will create a directory called c:\CreateDSC\Logging
	ii. Start a transcript of all actions
	iii. Set the execution policy so we can download software
	iv. Enable PS-Remoting for PowerShell
	v. Install PowerShell and DSC modules in the following location: C:\Program Files\WindowsPowerShel\Modules
	vi. Check if TLS12 is present and if not set it
	vii. Checks for PowerShell Version 5.1 on Windows server platforms. If the version is 4.0 we will install Windows Management Framework 1
	        1 - The use of the -Exchange switch we will force the install Unified Communications Managed API 4.0 Runtime
		2 - Check to see if .Net Framework 4.8 is installed and report back
	viii. Checks for Nuget (new PowerShell setup on a new machine)
	ix. Registered the PackageProvider
	x. Start the install of all modules
	xi. Reset the execution policy back to the default

5. Run: New-DSCClientConfiguration -Verbose -$DSCSMBServer YourDSCServer

> This will connect to \\\\YourDSCServer\DSCSharedFolder and read in all configuration files generated on DC1. 

> The first time you attempt to connect you will need to put in your DC administrator account and password. You can copy the password from MyWorkspace and paste it in. YOU WILL NOT SEE ANY OUTPUT FROM THE CUT AND PASTE

5. Just hit enter

> You will be offered a menu of configurations you can select from to apply to the local machine

6. Select the configuration that you want to apply to the machine.

> To apply another configuration just re-run New-DSCClientConfiguration -Verbose -$DSCSMBServer DC1 and select another configuration.

> The last configuration you applied will be check every 30 minutes for changes an if something is missing from that configuration it will be re-applied. You can monitor one configuration at a time.
