Windows agent部署


支持的版本：
	
	desktop OSs：  Windows 7, 8.1, and 10
	
	server OSs：  Windows Server 2008, 2008 R2, 2012, 2012 R2, and 2016.
	
	
依赖：
	 
	PowerShell 3.0 or newer and at least .NET 4.0 。（需要重启主机）
	
	A WinRM listener should be created and activated.
	
	
1.依赖安装：

1.1 Upgrading PowerShell and .NET Framework

```
	
$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Upgrade-PowerShell.ps1"$file = "$env:temp\Upgrade-PowerShell.ps1"$username = "Administrator"$password = "Password"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# version can be 3.0, 4.0 or 5.1&$file -Version 5.1 -Username $username -Password $password -Verbose

```
	
1.2 remove auto logon and set the execution policy back to the default of Restricted

```
# this isn't needed but is a good security practice to completeSet-ExecutionPolicy -ExecutionPolicy Restricted -Force

$reg_winlogon_path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"Set-ItemProperty -Path $reg_winlogon_path -Name AutoAdminLogon -Value 0Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultUserName -ErrorAction SilentlyContinueRemove-ItemProperty -Path $reg_winlogon_path -Name DefaultPassword -ErrorAction SilentlyContinue

```	
	
1.3 WinRM Memory Hotfix

```	

$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Install-WMF3Hotfix.ps1"$file = "$env:temp\Install-WMF3Hotfix.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)powershell.exe -ExecutionPolicy ByPass -File $file -Verbose


```	

注意事项：

	Only running on PowerShell v3.0
		
1.4  WinRM Setup
	WinRM service to be configured so that Ansible can connect to it。There are two main components of the WinRM service that governs how Ansible can interface with the Windows host: the listener and the service configuration settings.

```
	
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
	
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
	
powershell.exe -ExecutionPolicy ByPass -File $file

```
	
注意事项：

The ConfigureRemotingForAnsible.ps1 script is intended for training and development purposes only and should not be used in a production environment, since it enables settings (like Basic authentication) that can be inherently insecure.