# Import the Active Directory module
Import-Module ActiveDirectory

# Define the number of days of inactivity to consider an account as inactive
$inactiveDays = 90

# Define the Organizational Units to exclude
$excludedOUs = @("OU=AdminAccounts,DC=example,DC=com", "OU=ServiceAccounts,DC=example,DC=com")

# Calculate the date to compare the LastLogonDate property
$inactiveDate = (Get-Date).AddDays(-$inactiveDays)

# Function to check if a user is in an excluded OU
function IsUserInExcludedOU {
    param (
        [Parameter(Mandatory=$true)]
        [string]$userDN
    )

    foreach ($ou in $excludedOUs) {
        if ($userDN -like "*$ou*") {
            return $true
        }
    }
    return $false
}

# Find all users who have not logged in since the inactiveDate
$inactiveUsers = Get-ADUser -Filter {LastLogonDate -lt $inactiveDate -and Enabled -eq $true} -Properties LastLogonDate, DistinguishedName

# List to hold the names of disabled accounts
$disabledAccounts = @()

# Disable the inactive user accounts
foreach ($user in $inactiveUsers) {
    if (-not (IsUserInExcludedOU -userDN $user.DistinguishedName)) {
        Disable-ADAccount -Identity $user
        $disabledAccounts += $user.SamAccountName
        Write-Output "Disabled account: $($user.SamAccountName)"
    }
}

# Output the names of the disabled accounts
$disabledAccounts | Out-File -FilePath "DisabledAccounts.txt"

Write-Output "Process completed. Disabled $($disabledAccounts.Count) inactive user accounts."
