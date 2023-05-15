<##
.SYNOPSIS
	Collection of Functions to support the exchange of XML data conforming to PESC XML standards

.DESCRIPTION
	Collection of Functions to support the exchange of XML data conforming to PESC XML standards

.NOTES
	Author: Joel C Mathias (jmathias@cscc.edu)
	Date: Created 05/15/2023
	Version: 0.01
	Build: 
	

#>



<#
.SYNOPSIS
Validate PESC College Transcript files to approved standard schemas.

.DESCRIPTION
Validate a file containing PESC College Transcript XML against PESC Approved Standards for Academic College Transcript schemas, sending validated files as output to be used in a pipeline or other subsequent process.

.PARAMETER Path
PESC XML data files to validate against PESC XML College Transcript schemas for transmission or import

.PARAMETER Version
Version of the PESC XML College Transcript schemas to validate the incoming XML file(s) against

.OUTPUTS

.NOTES

.EXAMPLE
Test-PESCXML -Path 'D:\PESCXML\Receiving\TheOSU-test230214a.xml'

.EXAMPLE
Get-PESCXML | Test-PESCXML

.EXAMPLE

Export-PESCXML -Path 'D:\PESCXML\Sending' | Test-PESCXML | Send-PESCXML -Target Parchment

.COMPONENT
The name of the technology or feature that the function or script uses, or to which it is related. The Component parameter of Get-Help uses this value to filter the search results returned by Get-Help.
.ROLE
The name of the user role for the help topic. The Role parameter of Get-Help uses this value to filter the search results returned by Get-Help.
.FUNCTIONALITY
The keywords that describe the intended use of the function. The Functionality parameter of Get-Help uses this value to filter the search results returned by Get-Help.

.LINK
https://www.pesc.org/college-transcript.html

.LINK
#>
function Test-PESCXML	{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position=0, ValueFromPipeline=$true, HelpMessage="PESC XML data files to validate against PESC XML College Transcript schemas for transmission or import")]
		[Alias("PSPath")]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	,	[Parameter(Position=1, HelpMessage="Version of the PESC XML College Transcript schemas to validate the incoming XML file(s) against")]
		[ValidateSet(1.8,1.7,1.6,1.0)] # (1.8,1.7,1.6,1.5,1.4,1.3,1.2,1.1,1.0
		[double] $Version = 1.0
	)
	begin {
		Write-Verbose "Test-PESCXML begin"
		$PESCschemas = @{
			1.8 = @("iso_3166-1:v1.0.0", "CoreMain:v1.19.0", "AcademicRecord:v1.13.0", "CollegeTranscript:v1.8.0") # must be loaded in order from left to right
			1.7 = @("iso_3166-1:v1.0.0", "CoreMain:v1.17.0", "AcademicRecord:v1.11.0", "CollegeTranscript:v1.7.0")
			1.6 = @("CoreMain:v1.14.0" , "AcademicRecord:v1.9.0", "CollegeTranscript:v1.6.0")
			1.5 = @("CoreMain:v1.13.0" , "AcademicRecord:v1.8.0", "CollegeTranscript:v1.5.0")
			1.4 = @("CoreMain:v1.12.0" , "AcademicRecord:v1.7.0", "CollegeTranscript:v1.4.0")
			1.3 = @("CoreMain:v1.10.0" , "AcademicRecord:v1.6.0", "CollegeTranscript:v1.3.0")
			1.2 = @("CoreMain:v1.8.0"  , "AcademicRecord:v1.5.0", "CollegeTranscript:v1.2.0")
			1.1 = @("CoreMain:v1.4.0"  , "AcademicRecord:v1.3.0", "CollegeTranscript:v1.1.0")
			1.0 = @("CoreMain:v1.0.0"  , "AcademicRecord:v1.0.0", "CollegeTranscript:v1.0.0")
		}
		$Xml = New-Object xml
		Write-Verbose "Test-PESCXML begin, load schemas" ($PESCschemas[$Version] -join ', ')
		foreach ($schema in $PESCschemas[$Version]) {
			$schemaFile = '..\Private\{0}.xsd' -f $schema #
			$schemaSection = switch ($schema.Substring(0,$schema.IndexOf("_"))) {
				CoreMain { 'core' }
				AcademicRecord {'sector'}
				CollegeTranscript {'message'}
				Default {'codes'}
			}
			$schemaURI = 'urn:org:pesc:{0}:{1}' -f $schemaSection,$schema.Replace('_',':')
			Write-Host "$Xml.Schemas.Add($schemaURI,$schemaFile) | Out-Null"
		}
	}
	process {
		Write-Verbose "Test-PESCXML process"
		Write-Verbose "Test-PESCXML process, loading contents of file"
		$Xml.Load( (Convert-Path -Path $Path) )	# https://stackoverflow.com/questions/65263942/how-to-load-or-read-an-xml-file-using-convertto-xml-and-select-xml
		try {
			Write-Verbose "Test-PESCXML process, validating"
			$Xml.Validate($null)
			$Path # output only validated files back into output/pipeline
		}
		catch	{
			$err = $_.Exception.Message
			Write-Error "Test-PESCXML process, failed to validate against schema`nDetails: $err"   # is write-error correct here?
		}
	}
	end {
		Write-Verbose "Test-PESCXML end"
	}
}
