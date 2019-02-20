#统计ip、MAC地址、计算机名、计算机配置、计算机型号、windows及SP的版本、C盘可用空间

$ostype='windows'
$osrelease=Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption  
'# HELP node_os 操作系统'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_os{name="',$ostype,'",version="',$osrelease,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#操作系统类型 node_os

$hostname= Get-WMIObject Win32_ComputerSystem |select  -ExpandProperty Name
'# HELP node_hostname 获取主机名 '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_hostname{hostname="',$hostname,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#获取主机名 node_hostname

$kernalversion= Get-CimInstance -ClassName Win32_OperatingSystem |select -ExpandProperty Version
'# HELP node_kernel 内核类型'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_kernel={kernel="windows",version="',$kernalversion,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#操作系统版本 node_kernel

$cpu=get-wmiobject win32_processor
$cpu_num= @($cpu).count*$cpu.NumberOfLogicalProcessors
'# HELP node_cpu_total CPU核心数量'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_cpu_total ',$cpu_num)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#每个CPU的逻辑核心数 node_cpu_total

$cpu_mode=  get-wmiobject win32_processor|Select-Object -ExpandProperty Name
'# HELP node_cpu_mode CPU类型'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_cpu_mode={cpu_mode="',$cpu_mode,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#CPU类型 node_cpu_mode

$IP=Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter IPEnabled=true |select -ExpandProperty IPAddress -First 1 |?{$_ -notlike "*:*" -and $_ -notlike "169*"} 
'# HELP node_network_ip 网卡IP' | Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_ip={ipaddress="',$IP,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#通过获取WMI中的IPV4地址 node_ip 

$MAC= Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter IPEnabled=true -Property * |?{$_.IPAddress -match $IP} |select -ExpandProperty macaddress -First 1 
'# HELP node_network_mac 网卡MAC’| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_network_mac={mac="',$MAC,'"}',' ',1)| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#通过获取WMI中的MAC地址 node_network_mac

$pcmodel=  Get-WmiObject -Class Win32_ComputerSystem -Property * |select -ExpandProperty Model
'# HELP node_virtual_type 虚拟化类型'| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
-Join('node_virtual_type={type="',$pcmodel,'"}',' ',1)  | Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
' '| Out-File -Append 'C:\Program Files\wmi_exporter\textfile_inputs\stattics.prome.0' -encoding utf8
#通过获取WMI中的计算机类型 node_virtual_type 

$memory=  (Get-WmiObject -Class Win32_ComputerSystem -Property * |select -ExpandProperty TotalPhysicalMemory)/1gb -as [int]       
#通过获取WMI中的计算机内存   

$harddisk=  (Get-WmiObject -Class Win32_DiskDrive |select -First 1 -ExpandProperty size)/1gb  -as [int]
#通过获取WMI中的硬盘大小   

$diskcfreesize=  ((Get-WMIObject Win32_LogicalDisk | ? { $_.deviceid -match "c" }).freespace)/1GB -as [int]
#通过获取WMI中的C盘可用空间大小

cd  'C:\Program Files\wmi_exporter\textfile_inputs\'

del stattics.prome.txt

Rename-Item  stattics.prome.0  stattics.prome.txt