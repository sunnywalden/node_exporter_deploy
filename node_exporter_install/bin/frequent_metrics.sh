#!/bin/bash

WK_DIR=$(cd "$(dirname "$0")";pwd)
current_dir=$(cd $(dirname $0);pwd)
filename="$current_dir/$(basename $0)"
tmp_file=${0%.*}.prom.$$
source /etc/profile &>/dev/null
source ${WK_DIR}/node_exporter.conf

frequent_metrics_store_path=${collector_textfile_directory}
grep -q "$filename" /var/spool/cron/root
[ $? -ne 0 ] && echo '*/1 * * * * /bin/bash '"$filename"'' >> /var/spool/cron/root

function get_inode_usage() {
  counter=0
  for fs in `cat /proc/self/mountstats |grep -E "^device /"|grep -Po "(?<=mounted on )\S+"`;do
    df -ilPT $fs|grep -vE "^[^/]"
  done | while read device fstype total used free percetile mountpoint;do
    # ignore mountpoints
    echo "${mountpoint}"|grep -Eq '^/(dev|proc|sys|var/lib/kubelet/.+|var/lib/docker/.+|data/docker/overlay)($|/)' && continue
    # ignore fstype
    echo "${fstype}"|grep -Eq '^(none|nfs.*|autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$' && continue
    [ $counter -eq 0 ] && echo "# HELP node_filesystem_inode_used 已使用 inode 个数"
    [ $counter -eq 0 ] && echo "# TYPE node_filesystem_inode_used gauge"
    echo "node_filesystem_inode_used{device=\"${device}\",mountpoint=\"${mountpoint}\",fstype=\"${fstype}\"} ${used}"
    [ $counter -eq 0 ] && echo "# HELP node_filesystem_inode_free 可用 inode 个数"
    [ $counter -eq 0 ] && echo "# TYPE node_filesystem_inode_free gauge"
    echo "node_filesystem_inode_free{device=\"${device}\",mountpoint=\"${mountpoint}\",fstype=\"${fstype}\"} ${free}"
    [ $counter -eq 0 ] && echo "# HELP node_filesystem_inode_total inode 总数"
    [ $counter -eq 0 ] && echo "# TYPE node_filesystem_inode_total gauge"
    echo "node_filesystem_inode_total{device=\"${device}\",mountpoint=\"${mountpoint}\",fstype=\"${fstype}\"} ${total}"
    counter=1
  done
}

cat > $tmp_file <<EOF
$(get_inode_usage)
EOF

mv $tmp_file ${frequent_metrics_store_path}/frequent_metrics.prom
chmod a+r ${frequent_metrics_store_path}/frequent_metrics.prom
