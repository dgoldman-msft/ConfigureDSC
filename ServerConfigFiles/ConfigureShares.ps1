Configuration ConfigureShares {
	
	Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName xSmbShare
	Import-DscResource -ModuleName cNtfsAccessControl

	Node localhost {

		# Declare we need the DSC-Service installed
		WindowsFeature DSCServiceFeature
		{
			Ensure = "Present"
			Name   = "DSC-Service"
		}
	
		# Declare we need the DSCShare folder created
		File CreateFolder {

			Ensure = 'Present'
			Type = 'Directory'
			DestinationPath = 'C:\DscSMBShare'
		}

		# Declare we need the DSCShare folder share created
		xSMBShare CreateShare {

			Ensure = 'Present'
			Name = 'DscSMBShare'
			Path = 'C:\DscSMBShare'
			FullAccess = 'Everyone'
			FolderEnumerationMode = 'AccessBased'
			DependsOn = '[File]CreateFolder'
		}

		# Declare we need the DSCShare folder share permissions set
		cNtfsPermissionEntry PermissionSet1 {

		Ensure = 'Present'
		Path = 'C:\DscSMBShare'
		Principal = 'Everyone'
		AccessControlInformation = @(
			cNtfsAccessControlInformation
			{
				AccessControlType = 'Allow'
				FileSystemRights = 'ReadAndExecute'
				Inheritance = 'ThisFolderSubfoldersAndFiles'
				NoPropagateInherit = $false
			}
		)
		DependsOn = '[File]CreateFolder'

		}
		
		File CreateSoftwareFolder
		{
			Ensure = 'Present'
			Type = 'Directory'
			DestinationPath = 'c:\Software\'
		}             
	
	# Declare we need the Software folder share created
		xSMBShare CreateSoftwareShare {

			Ensure = 'Present'
			Name = 'Software'
			Path = 'c:\Software'
			ReadAccess = 'Everyone'
			FolderEnumerationMode = 'AccessBased'
			DependsOn = '[File]CreateSoftwareFolder'
		}

		# Declare we need the Software folder share permissions set
		cNtfsPermissionEntry PermissionSet2 {

		Ensure = 'Present'
		Path = 'c:\Software'
		Principal = 'Everyone'
		AccessControlInformation = @(
			cNtfsAccessControlInformation
			{
				AccessControlType = 'Allow'
				FileSystemRights = 'ReadAndExecute'
				Inheritance = 'ThisFolderSubfoldersAndFiles'
				NoPropagateInherit = $false
			}
		)
		DependsOn = '[File]CreateSoftwareFolder'

		}
	}
}

ConfigureShares
 
