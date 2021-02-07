<#
.SYNOPSIS
    Decrypts passwords symmetrically encrypted by Plesk on Windows.
.DESCRIPTION
    Plesk uses symmetrical encryption for many passwords in its internal MySQL database "psa". With the help of this script you can now decrypt them for Plesk running on Windows as well.
.PARAMETER EncryptedString
    An encrypted string you found Plesk's psa database
.PARAMETER SymmetricKey
    Plesk symmetric encryption key. You can find it at HKLM:\SOFTWARE\WOW6432Node\PLESK\PSA Config\Config\sym_key\sym_key, but this script extracts it automatically.
.EXAMPLE
    ConvertFrom-PleskSymmetricallyEncryptedString.ps1 -EncryptedString '$AES-128-CBC$ABNK35ZcqnbTYT4Q3mbaEA$HmGDWmtym6K3+kJ8uBoJOg'
.OUTPUTS
    [string]
.NOTES
    Author: Kirill Nikolaev
    Twitter: @exchange12rocks
    Web-site: https://exchange12rocks.org
    GitHub: https://github.com/exchange12rocks
.LINK
    https://exchange12rocks.org/2021/02/08/how-to-decrypt-plesk-passwords-on-windows/
.LINK
    https://github.com/exchange12rocks/PS/blob/master/ConvertFrom-PleskSymmetricallyEncryptedString.ps1
.LINK
    https://mor-pah.net/2014/03/05/decrypt-plesk-11-passwords/
.LINK
    https://codeforcontent.com/blog/using-aes-in-powershell/
#>

#Requires -Version 3.0

Param (
    [Parameter(Mandatory)]
    [string]$EncryptedString,
    [byte[]]$SymmetricKey = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\PLESK\PSA Config\Config\sym_key' -Name sym_key).sym_key
)

$EncryptedStringSplitted = $EncryptedString.Split('$')
$IV = $EncryptedStringSplitted[2]
$Data = $EncryptedStringSplitted[3]

$IVRemainder = $IV.Length % 4
if ($IVRemainder) {
    $IV = $IV.PadRight($IV.Length + $IVRemainder, '=')
}
$DataRemainder = $Data.Length % 4
if ($DataRemainder) {
    $Data = $Data.PadRight($Data.Length + $DataRemainder, '=')
}

$AESCipher = New-Object -TypeName 'System.Security.Cryptography.AesCryptoServiceProvider'
$AESCipher.Key = $SymmetricKey

$EncryptedBytes = [System.Convert]::FromBase64String($Data)
$AESCipher.IV = [System.Convert]::FromBase64String($IV)

$Decryptor = $AESCipher.CreateDecryptor()
$UnencryptedBytes = $Decryptor.TransformFinalBlock($EncryptedBytes, 0, $EncryptedBytes.Length)
[System.Text.Encoding]::UTF8.GetString($UnencryptedBytes)
