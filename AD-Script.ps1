#####################################################
# To create the AAD resources                     #
#####################################################
Get-Module -ListAvailable

# Import the Active Directory Module
Import-Module ActiveDirectory

# Get the current UPN suffixes
Get-ADObject -Identity "CN=Partitions,CN=Configuration,DC=an,DC=local" -Properties uPNSuffixes | Select-Object -ExpandProperty uPNSuffixes
# Add a new UPN suffix
Set-ADObject -Identity "CN=Partitions,CN=Configuration,DC=an,DC=local" -ProtectedFromAccidentalDeletion $false
Set-ADObject -Identity "CN=Partitions,CN=Configuration,DC=an,DC=local" -Add @{'uPNSuffixes'="abacusnetwork.com.au"}
Set-ADObject -Identity "CN=Partitions,CN=Configuration,DC=an,DC=local" -ProtectedFromAccidentalDeletion $true

# Create new OUs
New-ADOrganizationalUnit -Name "AVD" -Path "DC=an,DC=local"
New-ADOrganizationalUnit -Name "AAD_Users" -Path "DC=an,DC=local"


# Define the user details
$userName = "aaduser1"
$password = ConvertTo-SecureString -AsPlainText "P@ssw0rd!@#" -Force
$upnSuffix = "abacusnetwork.com.au"
$ouPath = "OU=AAD_Users,DC=an,DC=local"

# Create the new user
New-ADUser -Name $userName -UserPrincipalName "$userName@$upnSuffix" -GivenName $userName -Surname "Surname" -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true -AccountPassword $password -Path $ouPath
