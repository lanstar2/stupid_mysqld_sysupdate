#!/bin/bash
# 恶意软件清理脚本 - 请以root权限运行
echo "开始清理恶意软件..."

# 1. 立即终止相关恶意进程
echo "正在终止恶意进程..."
pkill -f mysqld_sysupdate
pkill -f mysqld_sysup
killall mysqld_sysupdate 2>/dev/null
ps aux | grep mysqld_sysupdate | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null

# 2. 移除文件保护属性
echo "移除文件保护属性..."
chattr -R -i /var/spool/cron 2>/dev/null
chattr -i /etc/crontab 2>/dev/null
chattr -i /etc/rc.local 2>/dev/null

# 3. 清理crontab任务
echo "清理crontab恶意任务..."
# 备份当前crontab
crontab -l > /tmp/crontab_backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null
# 移除包含恶意URL的任务
crontab -l 2>/dev/null | grep -v "23.94.139.145" | grep -v "mysql_check.sh" | crontab -

# 检查root用户的crontab
if [ -f /var/spool/cron/root ]; then
    cp /var/spool/cron/root /var/spool/cron/root.backup.$(date +%Y%m%d_%H%M%S)
    grep -v "23.94.139.145" /var/spool/cron/root | grep -v "mysql_check.sh" > /tmp/clean_cron
    mv /tmp/clean_cron /var/spool/cron/root
fi

# 4. 清理/etc/rc.local
echo "清理开机启动项..."
if [ -f /etc/rc.local ]; then
    cp /etc/rc.local /etc/rc.local.backup.$(date +%Y%m%d_%H%M%S)
    grep -v "23.94.139.145" /etc/rc.local | grep -v "mysql_check.sh" > /tmp/clean_rc.local
    mv /tmp/clean_rc.local /etc/rc.local
    chmod +x /etc/rc.local
fi

# 5. 删除恶意文件
echo "删除恶意文件..."
rm -f /tmp/mysqld_sysupdate*
rm -f /tmp/config.json*
rm -f /tmp/mysql_check.sh*

# 查找并删除其他可能的恶意文件
find /tmp -name "*mysqld_sysupdate*" -delete 2>/dev/null
find /var/tmp -name "*mysqld_sysupdate*" -delete 2>/dev/null

# 6. 检查系统服务
echo "检查系统服务..."
systemctl list-units --type=service | grep -i mysql
systemctl list-units --type=service | grep -i sysupdate

# 7. 检查网络连接
echo "检查可疑网络连接..."
netstat -antp | grep "23.94.139.145" 2>/dev/null || echo "未发现到恶意IP的连接"
ss -antp | grep "23.94.139.145" 2>/dev/null || echo "未发现到恶意IP的连接"

# 8. 恢复文件保护（可选）
echo "恢复关键文件保护..."
chattr +i /etc/crontab 2>/dev/null
chattr -R +i /var/spool/cron 2>/dev/null

# 9. 重启cron服务
echo "重启cron服务..."
systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null || service cron restart 2>/dev/null

echo "清理完成！请检查以下内容："
echo "1. 验证crontab任务: crontab -l"
echo "2. 检查/etc/rc.local内容"
echo "3. 监控系统进程: ps aux | grep mysql"
echo "4. 检查网络连接: netstat -antp"
echo "5. 建议重启系统以确保完全清理"
