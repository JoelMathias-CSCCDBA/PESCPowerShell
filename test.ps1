Import-Module ".\modules\PESCXML\Public\PESCXML.psm1" -Force

<# New-PESCXML
$foo = New-PESCXML -Verbose -Version "1.8"
$foo
#>
$in = "C:\Subversion\ATC.202201\OBR_ATC\PowerShell\target"
$out = "C:\Temp"
# Get-ChildItem -Path $in | Where-Object { $_.Extension -in '.xml' } | Select-Object -First 1 | Test-PESCXML
Get-ChildItem -Path $in | Where-Object { $_.Extension -in '.xml' } | Select-Object -First 1 | Convert-PESCXML -Destination $out -Source Parchment -Target uAchieve -Verbose