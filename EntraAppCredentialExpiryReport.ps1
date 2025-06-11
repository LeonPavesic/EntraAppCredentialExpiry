# =============================================================================================
# App Credential Expiry Report + Email Notification (via Microsoft Graph)
# Author: Leon Pavesic's Admin Automation
# Description: Scans Entra ID apps for expiring client secrets and certificates.
#              Sends email notifications via Microsoft Graph if expiring credentials are found.
# =============================================================================================

Param (
    [switch]$CreateSession,
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$CertificateThumbprint,
    [string]$UserEmail,
    [Switch]$ClientSecretsOnly,
    [Switch]$CertificatesOnly,
    [int]$SoonToExpireInDays = 30,
    [string]$OutputPath = "$env:TEMP\ExpiringApps.csv"
)

# Connects to Microsoft Graph
function Connect-MgGraph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Beta)) {
        Write-Host "Installing Microsoft Graph PowerShell SDK..."
        Install-Module Microsoft.Graph.Beta -Repository PSGallery -Scope CurrentUser -Force
    }

    if ($CreateSession) {
        Disconnect-MgGraph
    }

    Write-Host "Connecting to Microsoft Graph..."
    if ($TenantId -and $ClientId -and $CertificateThumbprint) {
        Connect-MgGraph -TenantId $TenantId -AppId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome
    }
    else {
        Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome
    }
}

# Start connection
Connect-MgGraph

# Prepare output
$ExportResults = @()
$Properties = @('DisplayName', 'AppId', 'Id', 'KeyCredentials', 'PasswordCredentials', 'CreatedDateTime', 'SigninAudience')

# Process applications
Get-MgBetaApplication -All -Property $Properties | ForEach-Object {
    $App = $_
    $Owners = (Get-MgBetaApplicationOwner -ApplicationId $App.Id).AdditionalProperties.userPrincipalName -join "," 
    if (-not $Owners) { $Owners = "-" }

    if (-not $CertificatesOnly) {
        foreach ($Secret in $App.PasswordCredentials) {
            $DaysLeft = (New-TimeSpan -Start (Get-Date) -End $Secret.EndDateTime).Days
            if ($DaysLeft -ge 0 -and $DaysLeft -le $SoonToExpireInDays) {
                $ExportResults += [PSCustomObject]@{
                    'App Name'             = $App.DisplayName
                    'App Owners'           = $Owners
                    'App Creation Time'    = $App.CreatedDateTime
                    'Credential Type'      = "Client Secret"
                    'Name'                 = $Secret.DisplayName
                    'Id'                   = $Secret.KeyId
                    'Creation Time'        = $Secret.StartDateTime
                    'Expiry Date'          = $Secret.EndDateTime
                    'Days to Expiry'       = $DaysLeft
                    'Friendly Expiry Date' = "Expires in $DaysLeft days"
                    'App Id'               = $App.Id
                }
            }
        }
    }

    if (-not $ClientSecretsOnly) {
        foreach ($Certificate in $App.KeyCredentials) {
            $DaysLeft = (New-TimeSpan -Start (Get-Date) -End $Certificate.EndDateTime).Days
            if ($DaysLeft -ge 0 -and $DaysLeft -le $SoonToExpireInDays) {
                $ExportResults += [PSCustomObject]@{
                    'App Name'             = $App.DisplayName
                    'App Owners'           = $Owners
                    'App Creation Time'    = $App.CreatedDateTime
                    'Credential Type'      = "Certificate"
                    'Name'                 = $Certificate.DisplayName
                    'Id'                   = $Certificate.KeyId
                    'Creation Time'        = $Certificate.StartDateTime
                    'Expiry Date'          = $Certificate.EndDateTime
                    'Days to Expiry'       = $DaysLeft
                    'Friendly Expiry Date' = "Expires in $DaysLeft days"
                    'App Id'               = $App.Id
                }
            }
        }
    }
}

# Function to send email via Microsoft Graph
function Send-GraphEmail {
    param (
        [string]$Token,
        [string]$Recipient,
        [string]$Subject,
        [string]$BodyContent,
        [string]$AttachmentPath
    )

    $EmailPayload = @{
        message = @{
            subject = $Subject
            body = @{
                contentType = "Text"
                content     = $BodyContent
            }
            toRecipients = @(@{emailAddress = @{address = $Recipient}})
        }
        saveToSentItems = "true"
    }

    if ($AttachmentPath -and (Test-Path $AttachmentPath)) {
        $EmailPayload.message.attachments = @(
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                name          = [IO.Path]::GetFileName($AttachmentPath)
                contentBytes  = [Convert]::ToBase64String([IO.File]::ReadAllBytes($AttachmentPath))
            }
        )
    }

    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$Recipient/sendMail" `
        -Headers @{Authorization = "Bearer $Token"} `
        -Method POST -Body ($EmailPayload | ConvertTo-Json -Depth 5) `
        -ContentType "application/json"
}

# Obtain token for email
if ($ClientId -and $ClientSecret -and $TenantId -and $UserEmail) {
    $TokenRequest = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }

    $TokenResponse = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $TokenRequest
    $AccessToken = $TokenResponse.access_token

    if ($ExportResults.Count -gt 0) {
        $ExportResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "[INFO] Exported $($ExportResults.Count) expiring credentials to $OutputPath"

        Send-GraphEmail -Token $AccessToken `
                        -Recipient $UserEmail `
                        -Subject "Entra ID Apps Expiring in <$SoonToExpireInDays Days" `
                        -BodyContent "Hi, please find attached the list of expiring Entra ID app credentials. Regards, Entra Automation Script" `
                        -AttachmentPath $OutputPath

        Write-Host "Email with attachment sent to $UserEmail"
    }
    else {
        Send-GraphEmail -Token $AccessToken `
                        -Recipient $UserEmail `
                        -Subject "Entra ID Credential Expiry Check - No Expiring Apps" `
                        -BodyContent "Hi, the scheduled check completed successfully. No app credentials are expiring in the next $SoonToExpireInDays days.Regards, Entra Automation"

        Write-Host "No expiring apps found. Confirmation email sent."
    }
} else {
    Write-Warning "Skipping email notification: Required parameters (ClientId, ClientSecret, TenantId, UserEmail) are missing."
}
