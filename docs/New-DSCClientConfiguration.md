---
external help file:
Module Name:
online version:
schema: 2.0.0
---

# New-DSCClientConfiguration

## SYNOPSIS
Setup a new DSC Pull client

## SYNTAX

```
New-DSCClientConfiguration [-DSCSMBServer <String>] [-DSCSharedFolder <String>] [-RemoteDrive <String>]
 [-RefreshConfiguration] [-GetEventLogs] [-NumberOfEvents <Int32>] [-GetCurrentConfigFiles] [-GetCurrentConfig]
 [<CommonParameters>]
```

## DESCRIPTION
This will setup a new DSC pull client

## EXAMPLES

### EXAMPLE 1
```
New-DSCClientConfiguration -ServerName '192.168.1.11'
```

### EXAMPLE 2
```
New-DSCClientConfiguration -RefreshConfiguration
```

### EXAMPLE 3
```
New-DSCClientConfiguration -RefreshConfiguration -Verbose
```

## PARAMETERS

### -DSCSMBServer
DSC configuration server

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Dc1
Accept pipeline input: False
Accept wildcard characters: False
```

### -DSCSharedFolder
DSC configuration server share

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: DscSmbShare
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoteDrive
Remote network share for DSC configuration server

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Z:
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshConfiguration
Reapply current DSC configuration

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

### -GetEventLogs
Display the events from the Microsoft-Windows-Dsc/Operational event log

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

### -GetCurrentConfigFiles
{{ Fill GetCurrentConfigFiles Description }}

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
Display the current DSC configuration

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
