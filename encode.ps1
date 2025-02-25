$textToEncrypt = Get-Content -Raw -Path "temp.txt"
$key = [Text.Encoding]::UTF8.GetBytes("s0m3sh1tttttttt")
$keyLength = $key.Length
$bytesToEncrypt = [Text.Encoding]::UTF8.GetBytes($textToEncrypt)

for ($i = 0; $i -lt $bytesToEncrypt.Length; $i++) {
    $bytesToEncrypt[$i] = $bytesToEncrypt[$i] -bxor $key[$i % $keyLength]
}

$encryptedText = [Convert]::ToBase64String($bytesToEncrypt)
Write-Output $encryptedText
