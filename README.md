# Entra App Credential Expiry Monitor

**Author:** Leon Pavesic

---

## Overview

This PowerShell script helps Microsoft 365 administrators proactively monitor Microsoft Entra (Azure AD) application registrations for client secrets and certificates that are nearing expiration. It connects to Microsoft Graph, retrieves all app registrations, checks their credential expiry dates, and notifies you by email with a detailed report.

---

## Features

- Automatically installs the Microsoft Graph PowerShell SDK if needed.
- Supports both client secrets and certificate credentials.
- Filters credentials expiring within a configurable time frame (default: 30 days).
- Exports a CSV report of expiring credentials.
- Sends email notifications with the report attached.
- Supports certificate-based authentication and delegated authentication.
- Scheduler-friendly for regular automated checks.

---

## Prerequisites

- PowerShell 7.x or later (recommended)
- Microsoft Graph PowerShell SDK (installed automatically by the script if missing)
- An Azure AD application with appropriate permissions (`Application.Read.All`)
- Email account and Microsoft Graph API permissions to send emails

---

## Usage

1. Clone or download this repository.

2. Customize the script parameters, especially:
   - `$TenantId`
   - `$ClientId`
   - `$CertificateThumbprint` (if using certificate-based auth)
   - `$SoonToExpireInDays` (optional; defaults to 30)
   - `$userEmail` (email to send notifications)

3. Run the script in PowerShell:
   ```powershell
   .\EntraAppCredentialExpiry.ps1 -CreateSession -TenantId "<YourTenantId>" -ClientId "<YourClientId>" -CertificateThumbprint "<Thumbprint>" -SoonToExpireInDays 30

## Setting Up the Microsoft Graph Email Sender App

To enable email notifications from the script, you need to register an application in Microsoft Entra ID and grant it permissions to send emails via Microsoft Graph.

---

### Step 1: Register a New Application

1. Sign in to the [Azure Portal](https://portal.azure.com/).  
2. Navigate to **Azure Active Directory** > **App registrations** > **New registration**.  
3. Enter a name like `Graph Email Sender`.  
4. Select the supported account types (single or multi-tenant).  
5. Click **Register**.

---

### Step 2: Configure API Permissions

1. Go to the app’s **API permissions** tab.  
2. Click **Add a permission** > **Microsoft Graph** > **Application permissions**.  
3. Search for and add `Mail.Send`.  
4. Click **Add permissions**.  
5. Click **Grant admin consent** for your tenant.

---

### Step 3: Create Client Credentials

1. Navigate to **Certificates & secrets**.  
2. Create a new **Client secret** or upload a **Certificate**.  
3. Save the secret value or certificate thumbprint securely for use in the script.

---

### Step 4: Use Credentials in Your Script

Provide these values in your script parameters:

- `$TenantId` – Your Azure AD tenant ID  
- `$ClientId` – The registered application’s Client ID  
- `$ClientSecret` or `$CertificateThumbprint` – The secret or certificate for authentication  

---

### Required Permission Summary

| Permission | Type                   | Description                      |
|------------|------------------------|---------------------------------|
| Mail.Send  | Application permission | Allows the app to send emails   |


License
This project is licensed under the MIT License — see the LICENSE file for details.

Contact
For questions or feedback, please reach out to leon.pavesic@web.de

Keep your Microsoft Entra app credentials secure and avoid disruptions with proactive expiry monitoring!
