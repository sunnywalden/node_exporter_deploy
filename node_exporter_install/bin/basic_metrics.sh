#!/bin/bash
WK_DIR=$(cd "$(dirname "$0")";pwd)

source /etc/profile &>/dev/null
source ${WK_DIR}/node_exporter.conf

rpm --quiet -q virt-what || yum install virt-what -y -q

vw_check=`rpm -qa virt-what|wc -l`
if [ $vw_check -ne 1 ];then
  rpm -i ${WK_DIR}/virt-what-1.11-2.el5.x86_64.rpm
fi

# node_region
#    10.1.0.0 idc-shanghai
#    10.3.101.0 idc-shenzhen
#    10.3.102.0 idc-shenzhen
#    10.3.103.0 idc-shenzhen
#    10.3.104.0 idc-shenzhen
#    10.3.105.0 idc-shenzhen
#    10.3.106.0 idc-shenzhen
#    10.3.107.0 idc-shenzhen

current_hostname=`hostname`

current_dir=$(cd $(dirname $0);pwd)

filename="$current_dir/$(basename $0)"

metrics_store_path=${collector_textfile_directory}

grep -q "$filename" /var/spool/cron/root
[ $? -ne 0 ] && echo '* 5 * * * /bin/bash '"$filename"'' >> /var/spool/cron/root

tmp_file=${0%.*}.prom.$$

function ip_addr(){
  python -c "import socket;print([(s.connect(('223.5.5.5', 53)), s.getsockname()[0], s.close()) for s in [socket.socket(socket.AF_INET, socket.SOCK_DGRAM)]][0][1])"
}


current_ip=`ip_addr`

function get_vpc_region(){
  echo `curl -sSL http://100.100.100.200/latest/meta-data/region-id`
}

function get_classic_region(){
  echo "cn-hangzhou"
}


function get_idc_region(){
  ipaddr=$(ip_addr)
  ip_seg_1=${ipaddr%%.*}
  _ip_seg=${ipaddr#*.}
  ip_seg_2=${_ip_seg%%.*}

  _ip_seg=${_ip_seg#*.}
  ip_seg_3=${_ip_seg%%.*}

  case $ip_seg_2 in
    1)
      echo "idc-shanghai"
      ;;
    2)
      echo "hq-shanghai"
      ;;
    3)
      if [[ "$ip_seg_3" -ge 101 && "$ip_seg_3" -le 107 ]];then
        echo "idc-shenzhen"
      else
        echo "hq-shenzhen"
      fi
      ;;
    4)
      echo "wuhan"
      ;;
    5)
      echo "beijing"
      ;;
    6)
      echo "meizhou"
      ;;
    10)
      echo "chengdu"
      ;;
    9)
      echo "zhangjiang"
      ;;
    8)
      echo "zhangjiang"
      ;;

    *)
      echo "unknown"
      ;;
  esac
}

function get_region(){

  http_code=$(curl --max-time 2 -i -sLS http://100.100.100.200/latest|head -1|awk '{print $2}')
  if [ "$http_code" == "200" ];then    # VPC 网络
    echo $(get_vpc_region)
  else
    echo $(get_idc_region $current_ip)
  fi

}

function get_os_info(){
 if [ -f /etc/redhat-release ];then
    os_name=$(cat /etc/redhat-release|grep -Po "Red Hat|CentOS"|head -1)
    os_version=$(cat /etc/redhat-release|grep -Po "[0-9.]+"|head -1)
    echo "$os_name|$os_version"
  elif [ -f /etc/issue ];then
    os_name=$(cat /etc/issue|awk '{print $1}'|head -1)
    os_version=$(cat /etc/issue|grep -pO "[0-9.]+"|head -1)
    echo "$os_name|$os_version"
  else
    echo "unknown|unknown"
  fi
}

function get_device_ip(){
  net_devices=`cat /proc/net/dev|grep -vE "Inter|face"|awk -F':' '{print $1}'`
  for dev in $net_devices;do
    ip=$(ip addr show $dev |grep -Po "(?<=inet )\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}")
    if [ "$ip" != "" ];then
      for i in `echo -e ${ip}`;do
        echo "node_network_ip{device=\"$dev\",ip=\"$i\"} 1"
      done
    fi
  done
}

function get_device_mac(){
  net_devices=`cat /proc/net/dev|grep -vE "Inter|face"|awk -F':' '{print $1}'`
  for dev in $net_devices;do
    mac=$(ip link show $dev|grep -Po "(?:(?:[A-Fa-f0-9]{2}:){5}[A-Fa-f0-9]{2})"|head -1)
    echo "node_network_mac{device=\"$dev\",mac=\"$mac\"} 1"
  done
}

function get_cpu_mode(){
  cpu_mode_name=`cat /proc/cpuinfo |grep 'model name'|head -1|awk -F ':' '{print $2}'`
  cpu_mode=`echo $cpu_mode_name|sed -e 's/(R)//g'|sed -e 's/@//g'`
  echo "node_cpu_mode{cpu_mode=\"$cpu_mode\"} 1"
}

function get_vendor_info(){
  if [ -f /sys/class/dmi/id/product_name ];then
    model=`cat /sys/class/dmi/id/product_name`
  fi
  if [ -f /sys/class/dmi/id/sys_vendor ];then
    vendor=`cat /sys/class/dmi/id/sys_vendor|awk '{print $1}'|tr -d ,`
  fi
  echo "node_vendor{vendor=\"$vendor\", model=\"$model\"} 1"
}

current_region=`get_region $current_ip`
virtual_type=`virt-what`
if [ -z "$virtual_type" ];then
  virtual_type="bare_metal"
fi
node_os_version=$(get_os_info|awk -F'|' '{print $2}')
node_os_name=$(get_os_info|awk -F'|' '{print $1}')
node_os=$(echo $(get_os_info)|tr '|' ' ')

node_kernel_version=`uname -r`
node_kernel=`uname -s`

rm -rf ${WK_DIR}/basic_metrics.prom*

cat > $tmp_file <<EOF
# HELP node_hostname hostname of current node
node_hostname{hostname="$current_hostname"} 1

# HELP node_network_ip 网卡IP
$(get_device_ip)

# HELP node_ip ipaddress of current node
node_ip{ipaddress="$current_ip"} 1

# HELP node_region 区域
node_region{region="$current_region"} 1

# HELP node_virtual_type 虚拟化类型
node_virtual_type{type="$virtual_type"} 1

# HELP node_os 操作系统
node_os{name="$node_os_name", version="$node_os_version"} 1

# HELP node_kernel 内核类型
node_kernel{kernel="$node_kernel",version="$node_kernel_version"} 1

# HELP node_cpu_num CPU核心数量
# TYPE node_cpu_num gauge
node_cpu_num $(cat /proc/cpuinfo|grep "processor"|wc -l)

# HELP node_cpu_mode CPU类型
# TYPE node_cpu_mode gauge
$(get_cpu_mode)

# HELP node_network_mac 网卡MAC
$(get_device_mac)

# "HELP node_vendoer 设备厂商"
$(get_vendor_info)

EOF

mv $tmp_file $metrics_store_path/basic_metrics.prom
chmod a+r $metrics_store_path/basic_metrics.prom
