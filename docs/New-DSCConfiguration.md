---
external help file:
Module Name:
online version:
schema: 2.0.0
---

# New-DSCConfiguration

## SYNOPSIS
Setup a new DSC Pull server

## SYNTAX

```
New-DSCConfiguration [-ServerName <String>] [-DSCSharedFolder <String>] [-RootPath <String>] [-GetEventLogs]
 [-NumberOfEvents <Int32>] [-CreateDSCFileShare] [-GetCurrentConfigFiles] [-GetCurrentConfig]
 [<CommonParameters>]
```

## DESCRIPTION
This will setup a new DSC pull server & share, create all configuration files found, rename them and publish to the share

## EXAMPLES

### EXAMPLE 1
```
New-DSCConfiguration -ServerName 'TestServer' -RootPath "c:\DSCShare"
```

### EXAMPLE 2
```
New-DSCConfiguration -ServerName 'TestServer' -CreateDSCFileShare
```

### EXAMPLE 3
```
New-DSCConfiguration -GetConfigFiles
```

### EXAMPLE 4
```
New-DSCConfiguration -GetCurrentConfig
```

## PARAMETERS

### -ServerName
Server name of the file you are publishing on.
Default is 'Localhost'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Localhost
Accept pipeline input: False
Accept wildcard characters: False
```

### -DSCSharedFolder
DSC file share name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: C:\DscSmbShare
Accept pipeline input: False
Accept wildcard characters: False
```

### -RootPath
Config root path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: C:\ConfigureDSC
Accept pipeline input: False
Accept wildcard characters: False
```

### -GetEventLogs
Dispaly the events from the Microsoft-Windows-Dsc/Operational event log

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NumberOfEvents
Default number of events to display is 10

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateDSCFileShare
Allows to skip the creation of creating the file share if you just want to configure new configuration files and publish them

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -GetCurrentConfigFiles
Open the local windows DSC mof file repository

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -GetCurrentConfig
Get the local DSC configuration applied to the machine

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
https://docs.microsoft.com/en-us/powershell/scripting/dsc/overview/overview?view=powershell-7.1

## RELATED LINKS
