Configuration ConfigurePSModules
{
	param
	(
		[string]
		$ServerName = "localhost"
	)

	Import-DSCResource -ModuleName PowerShellModule
	
	Node $ServerName
	{
		PSModuleResource 'PSFramework' #ResourceName
		{
			Module_Name = 'PSFramework'
			Ensure = 'Present'
		}
		
		PSModuleResource 'PSUtil' #ResourceName
		{
			Module_Name = 'PSUtil'
			Ensure = 'Present'
		}
		
		PSModuleResource 'PSModuleDevelopment' #ResourceName
		{
			Module_Name = 'PSModuleDevelopment'
			Ensure = 'Present'
		}
		
		PSModuleResource 'PSServicePrincipal' #ResourceName
		{
			Module_Name = 'PSServicePrincipal'
			Ensure = 'Present'
		}
		
		PSModuleResource 'ExchangeOnlineManagement' #ResourceName
		{
			Module_Name = 'ExchangeOnlineManagement'
			Ensure = 'Present'
		}
		
		PSModuleResource 'AzureAD' #ResourceName
		{
			Module_Name = 'AzureAD'
			Ensure = 'Present'
		}
		
		PSModuleResource 'AzureADPreview' #ResourceName
		{
			Module_Name = 'AzureADPreview'
			Ensure = 'Present'
		}
	}
}
ConfigurePSModules -ServerName $ServerName
