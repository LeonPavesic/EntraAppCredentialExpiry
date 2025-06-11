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

License
This project is licensed under the MIT License — see the LICENSE file for details.

Contact
For questions or feedback, please reach out to leon.pavesic@web.de

Keep your Microsoft Entra app credentials secure and avoid disruptions with proactive expiry monitoring!
