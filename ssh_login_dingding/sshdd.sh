# 编辑/etc/ssh/sshrc文件，如果没有自行新建一个sshrc文件
#获取登录者的用户名
user=$USER
#获取登录IP地址
ip=${SSH_CLIENT%% *}
#获取登录的时间
time=$(date +%F%t%k:%M)
#服务器的IP地址和自定义名称
server='X.X.X.X-自定义名称'

# 修改函数声明语法，使其兼容Dash
DingDingalarm() {
#生成的钉钉机器人的地址。
local url="https://oapi.dingtalk.com/robot/send?access_token=f469bee0141a8edc7b465b85c6e91caf22fbcc0881c2e3c311b2bdfd4aa8abb6"

local UA="Mozilla/5.0(WindowsNT6.2;WOW64)AppleWebKit/535.24(KHTML,likeGecko)Chrome/19.0.1055.1Safari/535.24"

# 修改为markdown格式
local res=`curl -XPOST -s -L -H"Content-Type:application/json" -H"charset:utf-8" $url -d"{\"msgtype\":\"markdown\",\"markdown\":{\"title\":\"$1\",\"text\":\"$2\"}}"`

echo $res
}

# 使用Markdown格式美化通知内容
DingDingalarm "服务器登录通知" "### 🔔 服务器登录通知 🔔\n\n**时间**：<font color='#FF5722'>$time</font>\n\n**服务器**：<font color='#2196F3'>$server</font>\n\n**用户**：<font color='#4CAF50'>$user</font>\n\n**来源IP**：<font color='#9C27B0'>$ip</font>\n\n> 请注意检查此次登录是否为您的预期操作"