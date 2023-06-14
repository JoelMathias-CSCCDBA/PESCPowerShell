<##
.SYNOPSIS
	Collection of Functions to support the exchange of XML data conforming to PESC XML standards

.DESCRIPTION
	Collection of Functions to support the exchange of XML data conforming to PESC XML standards

.NOTES
	Author: Joel C Mathias (jmathias@cscc.edu)
	Date: Created 04/07/2022
	Version: 0.01
	Build: 
	BUsiness LOgic:
		Get - use protocol to get files from intermediate (Parchments, NSC, etc.) and place in (local) location for processing
		Convert - validate XML vs PESC standard, extract source information to match target, extract student information to match target - if no errors distill XML to next state for import
		Import - take files from above and import into destination ERP or degree audit system

#>
$Global:Organization = @{
	OrganizationName = "Columbus State Community College"
	IPEDS = @("202222")
	FICE = @("006867")
	Contacts = ""
	NoteMessage = "PESC"
}
$Global:ReceiveConfig = @{
	OrganizationIDGroups = @('IPEDS','FICE')	# Organization IDs supported by receive
	RemoveNodes = @("NoteMessage","Tests","Health","UserDefinedExtensions")	# Nodes to remove
}
<#
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Out of Scope:

function Export-PESCXML {	# connect to ERP and extract data	}
function ?-PESCXML {	# converted exported data to a PESC standard XML document	}
function Send-PESCXML {	# send converted document to intermediate location	}

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>

<#
.SYNOPSIS
Creates a new xml object for PESC College Transcript files and loads the approved standard schemas into the object for validation

.DESCRIPTION
Creates a new xml object for PESC College Transcript files and loads the approved standard schemas into the object for validation.

.PARAMETER Version
Version of the PESC XML College Transcript schemas to validate the incoming XML file(s) against

.OUTPUTS
A new XML object containing the selected schemas to validate and transform the XML on PESC standards

.NOTES

.EXAMPLE
$ourXML = New-PESCXML

.EXAMPLE
$ourXML = New-PESCXML -Version "1.8"

.LINK
https://www.pesc.org/college-transcript.html

#>
function New-PESCXML {	# STATUS: COMPLETED
	[CmdletBinding()]
	[OutputType([xml])]
	param (
		[Parameter(HelpMessage="Version of the PESC XML College Transcript schemas to validate the incoming XML file(s) against")]
		[ValidateSet("1.8","1.7","1.6","1.0")] # (1.8,1.7,1.6,1.5,1.4,1.3,1.2,1.1,1.0
		[string] $Version = "1.0"
	)

	$Xml = New-Object xml
	$PESCschema = switch ($Version) {
		"1.8" { @("iso_3166-1:v1.0.0", "CoreMain:v1.19.0", "AcademicRecord:v1.13.0", "CollegeTranscript:v1.8.0") }
		"1.7" { @("iso_3166-1:v1.0.0", "CoreMain:v1.17.0", "AcademicRecord:v1.11.0", "CollegeTranscript:v1.7.0") }
		"1.6" { @("CoreMain:v1.14.0" , "AcademicRecord:v1.9.0", "CollegeTranscript:v1.6.0") }
#		"1.5" { @("CoreMain:v1.13.0" , "AcademicRecord:v1.8.0", "CollegeTranscript:v1.5.0") }
#		"1.4" { @("CoreMain:v1.12.0" , "AcademicRecord:v1.7.0", "CollegeTranscript:v1.4.0") }
#		"1.3" { @("CoreMain:v1.10.0" , "AcademicRecord:v1.6.0", "CollegeTranscript:v1.3.0") }
#		"1.2" { @("CoreMain:v1.8.0"  , "AcademicRecord:v1.5.0", "CollegeTranscript:v1.2.0") }
#		"1.1" { @("CoreMain:v1.4.0"  , "AcademicRecord:v1.3.0", "CollegeTranscript:v1.1.0") }
		Default {
			@("CoreMain:v1.0.0"  , "AcademicRecord:v1.0.0", "CollegeTranscript:v1.0.0")
		}
	}
	foreach ($schema in $PESCschema) {
		$schemaFile = '{0}\{1}.xsd' -f $PSScriptRoot.Replace("Public","Private"),$schema.Replace(':','_') #
		$schemaSection = switch ($schema.Substring(0,$schema.IndexOf(':'))) { # MUST BE Added IN SEQUENCE - 
			CoreMain { 'core' }
			AcademicRecord {'sector'}
			CollegeTranscript {'message'}
			Default {'codes'}
		}
		$schemaURI = 'urn:org:pesc:{0}:{1}' -f $schemaSection,$schema
		Write-Verbose "New-PESCXML, schema: $schemaFile $schemaURI"
		$Xml.Schemas.Add($schemaURI,$schemaFile) | Out-Null
	}
	return $Xml
}

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
Pipelined; paths to XML files that passed validation

.NOTES

.EXAMPLE
Test-PESCXML -Path 'D:\PESCXML\Receiving\TheOSU-test230214a.xml'

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

#>
function Test-PESCXML	{	# STATUS: COMPLETED
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position=0, ValueFromPipeline=$true, HelpMessage="PESC XML data files to validate against PESC XML College Transcript schemas for transmission or import")]
		[Alias("PSPath")]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	,	[Parameter(Position=1, HelpMessage="Version of the PESC XML College Transcript schemas to validate the incoming XML file(s) against")]
		[ValidateSet("1.8","1.7","1.6","1.0")] # (1.8,1.7,1.6,1.5,1.4,1.3,1.2,1.1,1.0
		[string] $Version = "1.0"
	)
	begin {
		$_ID = "Test-PESCXML"
		Write-Verbose "$_ID begin"
		$Xml = New-PESCXML -Version $Version
	}
	process {
		Write-Verbose "$_ID process"
		Write-Verbose "$_ID process, loading contents of file"
		$Xml.Load( (Convert-Path -Path $Path) )	# https://stackoverflow.com/questions/65263942/how-to-load-or-read-an-xml-file-using-convertto-xml-and-select-xml
		try {
			Write-Verbose "$_ID process, validating"
			$Xml.Validate($null)
			$Path # output only validated files back into output/pipeline
		}
		catch	{
			$err = $_.Exception.Message
			Write-Error "$_ID process, failed to validate against schema`nDetails: $err"   # is write-error correct here?
		}
	}
	end {
		Write-Verbose "$_ID end"
	}
}

<#
.SYNOPSIS
Convert PESC College Transcript files to destination format.

.DESCRIPTION
Validate and Convert PESC College Transcript files to a destination format determining criteria to match the sending institution to target ERP/DA systems and match one or more students to target ERP identifiers

.PARAMETER Path 
PESC XML data files to validate and convert to target format; extracting sending institution identifers, student match elements, and a flattened/streamlined academic record per student

.PARAMETER Destination
Path to place output files using the same filenames on input.

.PARAMETER Source
Defines the source of the XML file; for documentation only at this time but may include optional logic in the future

.PARAMETER Target
Defines the final destination of the transcript data; ; for documentation only at this time but may include optional logic in the future

.OUTPUTS
Pipelined; paths to validated and converted XML transcripts

.NOTES
Assumes default for PESC standard supported; see New-PESCXML for details

.EXAMPLE
Convert-PESCXML -Path 'D:\PESCXML\Receiving\TheOSU-test230214a.xml'

.EXAMPLE
Get-PESCXML | Convert-PESCXML | Import-PESCXML

.COMPONENT
The name of the technology or feature that the function or script uses, or to which it is related. The Component parameter of Get-Help uses this value to filter the search results returned by Get-Help.
.ROLE
The name of the user role for the help topic. The Role parameter of Get-Help uses this value to filter the search results returned by Get-Help.
.FUNCTIONALITY
The keywords that describe the intended use of the function. The Functionality parameter of Get-Help uses this value to filter the search results returned by Get-Help.

.LINK
https://www.pesc.org/college-transcript.html

#>
function Convert-PESCXML {	# STATUS: Development; Initial
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline=$true)]
		[Alias("PSPath")]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	,	[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $Destination
	,	[Parameter()]
		[ValidateSet("Parchment","NSC")]
		[string] $Source = "Parchment"
	,	[Parameter()]
		[ValidateSet("Colleague","uAchieve")]
		[string] $Target = "uAchieve"
	)
	begin {
		$_ID = 'Convert-PESCXML'
		Write-Verbose -Message "$_ID begin $Source $Target"
		Write-Verbose -Message "$_ID begin, connect to ERP services for student matching services."

		$Xml = New-PESCXML -Version "1.0"
		$DestinationIPEDS = @('202222') # Load from database, configuration, or module data ???
		$Transcripts = @() # Technically, a PESC document can contain more than one student in student transcripts (but usually doesn't, we've never seen one) so create an empty array for them
	}
	process {
		Write-Verbose "$_ID process, $Path"
		try {
			Write-Verbose "$_ID process, loading contents of XML file"
			$Xml.Load( (Convert-Path -Path $Path) )	# https://stackoverflow.com/questions/65263942/how-to-load-or-read-an-xml-file-using-convertto-xml-and-select-xml
			Write-Verbose "$_ID process, validating"
			$Xml.Validate($null)

			$Transmission = $Xml.CollegeTranscript.TransmissionData
			$DocumentID = $Transmission.DocumentID	# The File Transmission Date and Time stamp with additional unique qualifying characters
			Write-Verbose "$_ID process, validated: DocumentID = $DocumentID"

			Write-Verbose "$_ID process, removing unused nodes from document"
            foreach ($nodeName in $ReceiveConfig['RemoveNodes']) {
                while ($null -ne ($node = $xml.SelectSingleNode("//$nodeName"))) {
                    Write-Host ("$_ID process, RemoveChild({0}), {1}" -f $node.Name,$node.InnerText)
                    $parent = $node.ParentNode
                    $parent.RemoveChild($node) | Out-Null
                }
            }

			Write-Verbose "$_ID process, extract required and optional data from CollegeTranscript.TransmissionData node"
			$TransmissionInfo = @()

			foreach ($node in $TransmissionData.Source.Organization.ChildNodes) {
				switch ($node.Name) {
					IPEDS { $TransmissionInfo += @($node.Name,$node.InnerText) } # The unique identifier assigned by the National Center for Education Statistics for the Integrated Postsecondary Education Data System for each postsecondary data exchange partner; 6 digit.
					FICE { $TransmissionInfo += @($node.Name,$node.InnerText) } # The unique identifier assigned for the Federal Interagency Committee on Education by the US Department of Education's National Center for Education Statistics for each postsecondary data exchange partner; 6 digit.
				#	CEEBACT	The unique identifier assigned by the College Entrance Examining Board and ACT for each K12 data exchange partner; 6-digits
				#	GEOCode	The unique identifier assigned by PESC for educational institutions; 7 character (2 alpha+5 alphanumeric)
				#	ATP	The unique identifier assigned for the Admissions Testing Program by the College Board for each postsecondary data exchange partner; 6 digit.
				#	OPEID	The unique identifier assigned by the Office of Postsecondary Education for each data exchange partner; 3-8 characters.
				#	NCHELPID	The unique identifier assigned by National Council on Higher Education Loan Programs for each data exchange partner; 3-8 characters.
				#	ACT	The unique identifier assigned by the American College Testing or ACT for each postsecondary data exchange partner. See www.act.org; 6 characters.
				#	CCD	The unique identifier assigned by the US Department of Education's National Center for Education Statistics as the Common Core of Data for each K12 data exchange partner; 12 characters.
				#	PSS	The unique identifier assigned to private K12 schools in the US by the US Department of Education's National Center for Education Statistics (NCES); 8 characters.
				#	CSIS	The 6-character unique identifier assigned by the Statistics Canada Canadian College Student Information System for each postsecondary data exchange partner
				#	USIS	The 6-character unique identifier assigned by the Statistics Canada University Student Information System for each postsecondary data exchange partner 
				#	ESIS	The 8-character unique identifier assigned by the Statistics Canada Enhanced Student Information System for each postsecondary data exchange partner.
				#	PSIS	The 8-character unique identifier assigned by the Statistics Canada Enhanced Student Information System for each data exchange partner.
				#	DUNS	Data Universal Numbering System (DUNS), unique nine character company identification number issued by Dun and Bradstreet Corporation.
				#	APAS	Alberta Post-secondary Application System; 2-12 characters
				#	LocalOrganizationID	1-35 character string
				#	MutuallyDefinedType	1-60 character string		
					default {  }
				}
			}
			Write-Verbose ("$_ID process, identify source ID for {0}, parse required and optional data, continue processing if no exceptions else report issues" -f $TransmissionData.Source.Organization.OrganizationName)

			switch ($Transmission.DocumentTypeCode) { #	Acknowledgment, Application, Cancel, Certificate, CertificationRequest, Change, Credential, Diploma, DisbursementAcknowledgement, DisbursementForecast, DisbursementRoster, GainfulEmploymentStudentResponseFile, GainfulEmploymentStudentSubmittal, IPEDS, InstitutionRequest, NSLDSEnrollmentError, NSLDSEnrollmentSubmittal, Receipt, Request, RequestedRecord, Response, ReverseTransfer, StudentRequest, TermEnroll, TermGrade, ThirdPartyRequest
				StudentRequest { 
					$TransmissionInfo += $Transmission.DocumentTypeCode
				}
				Default {
					Write-Error "$_ID process, error message - unsupported DocumentTypeCode" $Transmission.DocumentTypeCode
				}
			}
			switch ($Transmission.TransmissionType) { #	The nature of the transmission; Duplicate, MutuallyDefined, Original, Reissue, Replace, Resubmission
				Original {
					$TransmissionInfo += $Transmission.TransmissionType
				}
				Default {
					Write-Error "$_ID process, error message - unsupported TransmissionType" $Transmission.TransmissionType
				}
			}
<###
		#	Optional
		#	This element indicates a TEST or PRODUCTION document
			switch ($Transmission.DocumentProcessCode) {
				TEST {
					# TEST MODE ?
					$TransmissionInfo += 'TEST'
				}
				Default { $TransmissionInfo += 'PRODUCTION'}
			}
		#	This element indicates if the document is unofficial. Unofficial documents may be produced for reference purpose but may not be binding.
			switch ($Transmission.DocumentOfficialCode) {
				Unofficial { $TransmissionInfo += $Transmission.DocumentOfficialCode }
				Default { $TransmissionInfo += 'Official'}
			}
		#	This element indicates whether the document conveys a complete record. Partial documents may be produced for information that is recorded in multiple media or formats.  If the student is still enrolled at the school, but the record being sent includes all the available information to date for that student, then the record would be considered complete, and this data element would not be included in the transcript.  A value of Partial generally means that the remainder will be sent in hard copy.
			switch ($Transmission.DocumentCompleteCode) {
				Partial { 
					Write-Error "$_ID process, error message - Partial DocumentCompleteCode is not supported at this time"
				}
				Default { $TransmissionInfo += 'Complete'}
			}
			$RequestTrackingID = $Transmission.RequestTrackingID	# The unique ID associated with a request action that is returned to the requestor for document matching and tracking.
###>

			Write-Verbose "$_ID process, transmission contains {0} students" -f $Xml.CollegeTranscript.Student.Count
		#
			$Path - pipelined output; XML file validated, tested, matched to institution and students, and can be imported into target system in Import-PESCXML
		#
		} # END Try
		catch {
			Write-Error "$_ID ERROR"
		}
		finally {
			Write-Verbose "$_ID process, end try"
		}
	}
	end {
		Write-Verbose "$_ID end"

	}
}

<#
.SYNOPSIS
Import PESC College Transcript data into target system.

.DESCRIPTION
Import PESC College Transcript data into target system.

.PARAMETER Path 
Converted data files to import into target system

.PARAMETER Target
Defines the final destination of the transcript data.

.OUTPUTS
Pipelined; paths to validated and converted XML transcripts

.NOTES
Assumes default for PESC standard supported; see New-PESCXML for details

.EXAMPLE
Import-PESCXML -Path 'D:\PESCXML\Receiving\TheOSU-test230214a.xml'

.EXAMPLE
Get-PESCXML | Convert-PESCXML | Import-PESCXML

.COMPONENT
The name of the technology or feature that the function or script uses, or to which it is related. The Component parameter of Get-Help uses this value to filter the search results returned by Get-Help.
.ROLE
The name of the user role for the help topic. The Role parameter of Get-Help uses this value to filter the search results returned by Get-Help.
.FUNCTIONALITY
The keywords that describe the intended use of the function. The Functionality parameter of Get-Help uses this value to filter the search results returned by Get-Help.

.LINK
https://www.pesc.org/college-transcript.html

#>
function Import-PESCXML {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline=$true)]
		[Alias("PSPath")]
		[ValidateNotNullOrEmpty()]
		[string] $Path
	,	[Parameter()]
		[ValidateSet("uAchieve","Colleague","Workday")]
		[string] $Target = "uAchieve"
	)
	begin {
		$_ID = "Import-PESCXML"
		Write-Verbose "$_ID begin, import into $Target"
		try {
			switch ($Target) {
				uAchieve {
					Write-Verbose "$_ID begin, connect to $Target database server..."
				}
			}
		catch {
			Write-Error "$_ID begin, error message - oopsie daisy"
		}
	}
	process {
		Write-Verbose "$_ID process, $Path"
		try {
		} # END Try
		catch {
			Write-Error "#_ID begin, error message - oopsie daisy"
		}
		finally {
			Write-Verbose "$_ID process, completed"
		}
	}
	end {
		Write-Verbose "$_ID end"
		if ($tgtConn -and $tgtConn.State -eq 'Open') {
			$tgtConn.Close()
		}
	}
}	# END function Import-PESCXML
