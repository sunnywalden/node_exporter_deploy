#ͳ��ip��MAC��ַ�������������������á�������ͺš�windows��SP�İ汾��C�̿��ÿռ�

$ostype='windows'
$osrelease=Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption  
'# HELP node_os ����ϵͳ'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_os{name="',$ostype,'",version="',$osrelease,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#����ϵͳ���� node_os

$hostname= Get-WMIObject Win32_ComputerSystem |select  -ExpandProperty Name
'# HELP node_hostname ��ȡ������ '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_hostname{hostname="',$hostname,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#��ȡ������ node_hostname

$kernalversion= Get-CimInstance -ClassName Win32_OperatingSystem |select -ExpandProperty Version
'# HELP node_kernel �ں�����'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_kernel={kernel="windows",version="',$kernalversion,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#����ϵͳ�汾 node_kernel

$cpu=get-wmiobject win32_processor
$cpu_num= @($cpu).count*$cpu.NumberOfLogicalProcessors
'# HELP node_cpu_total CPU��������'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_cpu_total ',$cpu_num)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#ÿ��CPU���߼������� node_cpu_total

$cpu_mode=  get-wmiobject win32_processor|Select-Object -ExpandProperty Name
'# HELP node_cpu_mode CPU����'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_cpu_mode={cpu_mode="',$cpu_mode,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#CPU���� node_cpu_mode

$IP=Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter IPEnabled=true |select -ExpandProperty IPAddress -First 1 |?{$_ -notlike "*:*" -and $_ -notlike "169*"} 
'# HELP node_network_ip ����IP' | Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_ip={ipaddress="',$IP,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#ͨ����ȡWMI�е�IPV4��ַ node_ip 

$MAC= Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter IPEnabled=true -Property * |?{$_.IPAddress -match $IP} |select -ExpandProperty macaddress -First 1 
'# HELP node_network_mac ����MAC��| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_network_mac={mac="',$MAC,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#ͨ����ȡWMI�е�MAC��ַ node_network_mac

$pcmodel=  Get-WmiObject -Class Win32_ComputerSystem -Property * |select -ExpandProperty Model
'# HELP node_virtual_type ���⻯����'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_virtual_type={type="',$pcmodel,'"}',' ',1)  | Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#ͨ����ȡWMI�еļ�������� node_virtual_type 

$memory=  (Get-WmiObject -Class Win32_ComputerSystem -Property * |select -ExpandProperty TotalPhysicalMemory)/1gb -as [int]       
#ͨ����ȡWMI�еļ�����ڴ�   

$harddisk=  (Get-WmiObject -Class Win32_DiskDrive |select -First 1 -ExpandProperty size)/1gb  -as [int]
#ͨ����ȡWMI�е�Ӳ�̴�С   

$diskcfreesize=  ((Get-WMIObject Win32_LogicalDisk | ? { $_.deviceid -match "c" }).freespace)/1GB -as [int]
#ͨ����ȡWMI�е�C�̿��ÿռ��С

cd  'C:\Program Files\wmi_exporter\textfile_inputs\'

del stattics.prome.txt

Rename-Item  stattics.prome.0  stattics.prome.txt