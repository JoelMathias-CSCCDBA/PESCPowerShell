Import-Module ".\modules\PESCXML\Public\PESCXML.psm1" -Force

$Xml = New-PESCXML -Verbose -Version "1.0"

$Xml.Load( (Convert-Path -Path $Path) )	# https://stackoverflow.com/questions/65263942/how-to-load-or-read-an-xml-file-using-convertto-xml-and-select-xml
$Xml.Validate($null)

