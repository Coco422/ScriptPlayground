# 一个求着 gemeni 给我写的小玩具

#### 用法

新建 ai.sh
`sudo cp ai.sh /usr/local/bin/ai`
然后就可以在终端直接
`ai tell me how to use scp copy a folder to other server`

#### 关于补全

输入 ai 之后 tab 可以查看补全。包括选择模型时会 tab 会请求 /v1/models 获取一次模型列表

> 以下内容来自 gemini 的解释
使用 `bash-completion` 包
如果你的系统安装了 `bash-completion` 包（大多数 Linux 发行版都预装了），你可以将补全脚本放到` /etc/bash_completion.d/ `目录下（或者` ~/.local/share/bash-completion/completions/ `，如果想为单个用户安装）：
接下来把补全拷过去
`sudo cp ai_completion.bash /etc/bash_completion.d/ai`
或者
`mkdir -p ~/.local/share/bash-completion/completions/`
`cp ai_completion.bash ~/.local/share/bash-completion/completions/ai`
然后，确保你的 `~/.bashrc` 或 `~/.bash_profile` 文件中包含以下行（通常已经有了）：


## ssh_login_dingding

这个是为了在有人登录 ssh 时直接给我钉钉机器人发消息。