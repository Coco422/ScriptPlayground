_ai_complete() {
    local cur prev opts
    COMPREPLY=()  # 初始化补全结果数组
    cur="${COMP_WORDS[COMP_CWORD]}"  # 当前正在输入的单词
    prev="${COMP_WORDS[COMP_CWORD-1]}" # 前一个单词

    # 顶级命令的选项
    opts="-help -list -m -chat --set_api_url --set_api_key --set_model"

    # 如果前一个单词是 -m，则提供模型列表补全（需要先读取配置）
    if [[ "$prev" == "-m" ]]; then
        if [ -f "$HOME/.ai_config" ]; then  # 检查配置文件是否存在
            source "$HOME/.ai_config"
            if [[ ! -z "$API_URL" && ! -z "$API_KEY" ]]; then # 检查URL和key
                # 使用 curl 获取模型列表 (与 -list 选项类似)
                COMPREPLY=($(compgen -W "$(curl -s -X GET "$API_URL/models" \
                    -H "Authorization: Bearer $API_KEY" \
                    -H "Content-Type: application/json" | jq -r '.data[].id')" -- "$cur"))
            fi
        fi
        return 0  # 阻止默认补全
    fi
     # 如果前一个单词是 --set_model，则提供模型列表补全（需要先读取配置）
    if [[ "$prev" == "--set_model" ]]; then
        if [ -f "$HOME/.ai_config" ]; then  # 检查配置文件是否存在
            source "$HOME/.ai_config"
            if [[ ! -z "$API_URL" && ! -z "$API_KEY" ]]; then # 检查URL和key
                # 使用 curl 获取模型列表 (与 -list 选项类似)
                COMPREPLY=($(compgen -W "$(curl -s -X GET "$API_URL/models" \
                    -H "Authorization: Bearer $API_KEY" \
                    -H "Content-Type: application/json" | jq -r '.data[].id')" -- "$cur"))
            fi
        fi
        return 0  # 阻止默认补全
    fi

    # 如果当前单词以 --set_ 开头，则提供 --set_... 选项的补全
    if [[ "$cur" == --set_* ]]; then
        COMPREPLY=($(compgen -W "--set_api_url --set_api_key --set_model" -- "$cur"))
        return 0
    fi

    # 默认情况下，提供顶级命令的选项补全
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

complete -F _ai_complete ai  # 将 _ai_complete 函数注册为 ai 命令的补全函数

