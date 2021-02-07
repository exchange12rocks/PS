# Thanks to:
# https://mor-pah.net/2014/03/05/decrypt-plesk-11-passwords/
# https://codeforcontent.com/blog/using-aes-in-powershell/

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