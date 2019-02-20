#!/bin/bash
##script for prometheus node_exporter install
#author: Henry Zhang

nodeexporter_install_path='/data/application/nodeexporter'
prometheus_user='prometheus'
prometheus_group='prometheus'
log_path='/data/log/nodeexporter'
run_path='/data/run/nodeexporter'
TMP_DIR='/tmp'
MD5SUM='ea098f984e3a8d505d029bef2e1df831'

WK_DIR=${TMP_DIR}/node_exporter_install
FILE_NAME=node_exporter_installer.tar.gz

check_os_bits() {
  SYSTEM_BITS_CHECK=`uname -a|grep x86_64|wc -l`
  if [[ ${SYSTEM_BITS_CHECK} ]];then
    OS_BITS='amd64'
    SYS_BITS='amd64'
  else
    OS_BITS='386'
    SYS_BITS='i386'
  fi
}

check_os_version() {
  #check the release of system
  CENTOS_SERIES=`egrep '^CentOS| Redhat |Red\ Hat' /etc/redhat-release|wc -l`
  SYSTEM_VERSION_CHECK=`grep ' 7' /etc/redhat-release |wc -l`
  SYSTEM_VERSION6_CHECK=`grep ' 6' /etc/redhat-release |wc -l`
  SYSTEM_VERSION5_CHECK=`grep ' 5' /etc/redhat-release |wc -l`

  if [[ ${CENTOS_SERIES} -eq 1 && ${SYSTEM_VERSION_CHECK} -eq 1 ]];then
    echo "system version is ceontos 7"
    sys_release='centos7'
  elif [[ ${CENTOS_SERIES} -eq 1 && ${SYSTEM_VERSION6_CHECK} -eq 1 ]];then
    echo "system version is ceontos 6"
    sys_release='centos6'
  elif [[ ${CENTOS_SERIES} -eq 1 && ${SYSTEM_VERSION5_CHECK} -eq 1 ]];then
    echo "system version is ceontos 5"
    sys_release='centos5'
  else
    echo "system version is not centos or redhat"
    sys_release='others'
    #return 0
  fi
}

wget_install() {
  yum install wget -y
}

go_install() {
  yum install go -y
}

gosu_install() {
  check_os_bits
  GOSU_URL='https://github.com/tianon/gosu/releases/download/1.11/gosu-'${SYS_BITS}

  cp -fr ${WK_DIR}/bin/gosu-${SYS_BITS} /usr/local/bin/gosu
  if [[ -f '/usr/local/bin/gosu' ]];then
    chmod a+x /usr/local/bin/gosu
  else
    echo 'gosu install failed!'
    exit 1
  fi
}

firewall_setting() {
  if [[ ${sys_release} == "centos7" ]];then
    check_iptable=`service iptables status|grep -v inactive|grep active|grep -v grep|wc -l`
  else
    check_iptable=`service iptables status|grep -v 'not running'|egrep '1|running' |grep -v grep|wc -l`
  fi
  if [[ ${check_iptable} -ne 0 ]];then
    check_iptables_setting=`iptables -L -n |grep ${nodeexporter_port}|grep -v grep|wc -l`
    if [[ ${check_iptables_setting} -eq 0 ]];then
      iptables -A INPUT -p tcp --dport ${nodeexporter_port} -j ACCEPT
      service iptables save
    fi
  fi
  echo '**************************************************'
  echo 'firewall setting finished!'
  echo '**************************************************'
}

download_pac() {
  DOWNLOAD_URL=ftp://10.1.5.100/software/monitor/node_exporter_deploy/

  if [[ -f "${TMP_DIR}/$FILE_NAME" ]];then
    rm -rf ${TMP_DIR}/${FILE_NAME}
  fi
  wget_res=`which wget`
  if [[ ${wget_res} ]];then
    wget_install
  fi
  echo '**************************************************'
  echo 'Downloading start...'
  echo '**************************************************'
  wget --tries=3 --no-check-certificate -O ${TMP_DIR}/${FILE_NAME} ${DOWNLOAD_URL}/${FILE_NAME}
  MD5_VUE=`md5sum ${TMP_DIR}/${FILE_NAME} |awk '{print $1}'`
  echo ${MD5_VUE}
  sleep 1
  if [[ "$MD5_VUE" == "$MD5SUM" ]]; then

    echo 'Download success!'
    echo '**************************************************'
  else
    echo 'node_exporter data download failed,try again!!!'
    echo '**************************************************'
    exit 1
  fi
}


nodes_install() {
  echo 'Check vars before start install job!'
  if [[ ! "$run_path" || ! "$log_path" || ! "$nodeexporter_install_path" ]];then
    echo 'Var pid_path log_path or nodeexporter_install_path not defined! Use default value!'
    nodeexporter_install_path=${nodeexporter_install_path:-'/data/application/nodeexporter'}
    run_path=${run_path:-'/data/run'}
    log_path=${log_path:-'/data/log'}
  fi
  echo 'Install start right now!'
  tar -zxvf ${TMP_DIR}/${FILE_NAME} -C ${TMP_DIR}
  #load vars defined in config file
  if [[ -f "${WK_DIR}/conf/node_exporter.conf" ]];then
    source ${WK_DIR}/conf/node_exporter.conf
  else
    echo 'Config file conde_exporter.conf not exists in conf dir!'
    exit 1
  fi
  if [[ "$cp" ]];then
    unalias cp
  fi
  if [[ -d ${nodeexporter_install_path} ]];then
    rm -r -f ${nodeexporter_install_path}
  fi
  echo 'Path rights setting!'
  mkdir -p ${nodeexporter_install_path} ${collector_textfile_directory} ${pid_path} ${log_path}
  chmod -R 755 ${run_path} ${log_path}
    
  groupadd ${prometheus_user}
  useradd -g ${prometheus_user} -d ${nodeexporter_install_path} -m -s '/sbin/nologin' ${prometheus_user}

  echo 'Install bin file to path'
  check_os_version
  if [[ ${sys_release} == 'centos5' ]];then
    cp -fr ${WK_DIR}/bin/node_exporter_v5.bin ${nodeexporter_install_path}/node_exporter
  else
    cp -fr ${WK_DIR}/bin/node_exporter.bin ${nodeexporter_install_path}/node_exporter
  fi
  cp -fr ${WK_DIR}/conf/node_exporter.conf ${nodeexporter_install_path}
  cp -fr ${WK_DIR}/bin/*.sh ${nodeexporter_install_path}
  cp -fr ${WK_DIR}/bin/virt-what* ${nodeexporter_install_path}
  chown -R ${prometheus_user}:${prometheus_group} ${nodeexporter_install_path}
  chmod -R 775 ${nodeexporter_install_path}
}

service_start() {
  echo 'service configure now!'
  if [[ ${SYSTEM_VERSION_CHECK} != 'others' ]]; then
    check_os_version
    if [[ ${sys_release} == 'centos5' ]];then
      cp -fr ${WK_DIR}/service/node_exporter.init5 /etc/init.d/node_exporter
      chmod a+x /etc/init.d/node_exporter
    elif [[ ${sys_release} == 'centos6' ]];then
      cp -fr ${WK_DIR}/service/node_exporter.init /etc/init.d/node_exporter
      chmod a+x /etc/init.d/node_exporter
    else
      cp -fr ${WK_DIR}/service/node_exporter.service /etc/systemd/system/
      systemctl daemon-reload
    fi

  else
    cp -fr ${WK_DIR}/service/node_exporter.service /etc/systemd/system/
    systemctl daemon-reload
  fi


  echo 'Install gosu if system is rhel 6 series!'
  if [[ ! -f '/usr/local/bin/gosu' ]];then
    gosu_install
  fi
  echo 'delete temp dir after install finished!'
  if [[ -d ${WK_DIR} ]];then
    rm -rf ${WK_DIR}
  fi  
  node_pid=`ps -ef|grep '${nodeexporter_install_path}/node_exporter '|grep -v grep|awk '{print $2}'`
  if [[ "$node_pid" ]];then
    kill -9 ${node_pid}
    find ${run_path} -type f -name node_exporter.pid|xargs rm -rf {}
  fi
  echo 'Service starting!'
  service node_exporter start
  chkconfig node_exporter on
  service node_exporter restart
  
  #Run once for instant
  bash ${nodeexporter_install_path}/*.sh
  #check service status
  SERVICE_CHK=`netstat -tunlp | grep ":${nodeexporter_port}"|grep -v grep|wc -l`
  if [[ ${SERVICE_CHK} -eq 1 ]]; then
    echo '**************************************************'
    echo 'node exporter install successful!'
    echo '**************************************************'
  else
    echo '**************************************************'
    echo 'node exporter service start failed!!!'
    echo '**************************************************'
    exit 1
  fi
  
}

echo '**************************************************'
echo '*******   Node_exporter install            *******'
echo '**************************************************'
download_pac
nodes_install
service_start
firewall_setting
echo '**************************************************'
echo '*******   we all finished here             *******'
echo '**************************************************'
