#!/bin/bash
#=============================================================
# Script Name: ai.sh
# Description:  主要为了在 linux 命令行终端调用 ai
# Author:  确切说是 gemini-2.0-pro-exp
# Created Date: 2025-02-12
# Version: 0.2
# Last Modified: 2025-02-12 13:26:21 by Ray
#=============================================================

# 配置文件路径 (用户主目录下的隐藏文件)
CONFIG_FILE="$HOME/.ai_config"

# 读取配置
read_config() {
  if [ -f "$CONFIG_FILE" ]; then
    # 使用 source 读取配置文件，使变量在当前 shell 中生效
    source "$CONFIG_FILE"
  else
    touch "$CONFIG_FILE"  # 如果文件不存在，则创建
    chmod 600 "$CONFIG_FILE" #并设置权限
  fi
}

# 写入配置
write_config() {
  echo "API_URL=\"$API_URL\"" > "$CONFIG_FILE"
  echo "API_KEY=\"$API_KEY\"" >> "$CONFIG_FILE"
  echo "MODEL=\"$MODEL\"" >> "$CONFIG_FILE" #也保存MODEL
  chmod 600 "$CONFIG_FILE"  # 设置权限，只有用户自己可读写
}


# 设置 API URL
set_api_url() {
  API_URL="$1"
  write_config
  echo "API URL 设置为: $API_URL"
}

# 设置 API KEY
set_api_key() {
  API_KEY="$1"
  write_config
  echo "API Key 设置为: $API_KEY"
}

set_model() {
    MODEL="$1"
    write_config
    echo "默认模型设置为：$MODEL"
}

# 帮助信息
show_help() {
    echo "使用方式: ai [选项] [问题]"
    echo
    echo "选项:"
    echo "  -help          显示帮助信息"
    echo "  -list          获取可用模型列表"
    echo "  -m model_name  指定模型进行对话（默认: gpt-4）"
    echo "  -chat          进入聊天模式（多轮对话）"
    echo "  --set_api_url <URL>  设置 API URL"
    echo "  --set_api_key <KEY>  设置 API Key"
    echo "  --set_model <model> 设置默认模型"
    echo
    echo "示例:"
    echo "  ai '为什么天空是蓝色的？'   # 直接提问"
    echo "  ai -m gpt-3.5-turbo '讲个笑话'  # 指定模型"
    echo "  ai -chat                  # 进入对话模式"
    echo "  ai -m gpt-3.5-turbo -chat  # 指定模型并进入对话"
    echo "  ai -list                   # 获取可用模型列表"
    echo "  ai --set_api_url http://example.com/api  # 设置 API URL"
    echo "  ai --set_api_key YOUR_API_KEY  # 设置 API Key"
    echo "  ai --set_model gpt-3.5-turbo     # 设置默认模型"

}

# 解析参数
if [[ "$1" == "-help" ]]; then
    show_help
    exit 0
fi

# 检查配置文件并提示设置 (在主逻辑前调用)
check_and_prompt_config() {
    read_config #先读取

    local missing_settings=()

    if [[ -z "$API_URL" ]]; then
        missing_settings+=("API_URL")
    fi

    if [[ -z "$API_KEY" ]]; then
        missing_settings+=("API_KEY")
    fi

    if [[ -z "$MODEL" ]]; then
        missing_settings+=("MODEL")
    fi

    if [[ ${#missing_settings[@]} -gt 0 ]]; then
        echo "首次使用，请先设置以下配置："
        for setting in "${missing_settings[@]}"; do
            case "$setting" in
                API_URL)
                    read -r -p "请输入 API URL: "  input
                    set_api_url "$input"
                    ;;
                API_KEY)
                    read -r -p "请输入 API Key: " input
                    set_api_key "$input"
                    ;;
                MODEL)
                    read -r -p "请输入默认模型 (例如 gpt-4): " input
                    set_model "$input"
                    ;;
            esac
        done
        echo "配置已保存到 $CONFIG_FILE"
    fi
}
if [[ "$1" == "-list" ]]; then
    read_config #先读取配置

    if [[ -z "$API_URL" || -z "$API_KEY" ]]; then #list也需要配置
        echo "错误：请先设置 API_URL 和 API_KEY。"
        exit 1
    fi
    echo "获取可用模型列表..."
    curl -s -X GET "$API_URL/models" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" | jq -r '.data[].id'
    exit 0
fi

if [[ "$1" == "-m" ]]; then
    if [[ -n "$2" ]]; then
        MODEL="$2"
        shift 2
    else
        echo "错误：请提供模型名称，例如：ai -m gpt-3.5-turbo '你的问题'"
        exit 1
    fi
fi

stream_response() {
    local response=""
    local last_was_reasoning  # 声明为局部变量

    curl -s -X POST "$API_URL/chat/completions" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$1" | while IFS= read -r line; do
            # 解析 SSE 数据格式
            if [[ $line =~ data:\ (.*) ]]; then
                chunk="${BASH_REMATCH[1]}"
                if [[ "$chunk" != "[DONE]" ]]; then
                    # 提取 JSON 字符串
                    token=$(echo "$chunk" | jq -r '.choices[0].delta.content' 2>/dev/null)
                    reasoning=$(echo "$chunk" | jq -r '.choices[0].delta.reasoning_content' 2>/dev/null)

                    if [[ "$reasoning" != "null" && "$reasoning" != "" ]]; then
                        if [[ -z "$last_was_reasoning" ]]; then #首次出现reasoning
			    echo -n ">>>>>>>>>>>>>思考中... |"
			    echo ""
                            last_was_reasoning=1
                        fi
                        echo -n "$reasoning"
                        response+="$reasoning"
                        sleep 0.0005
                    elif [[ "$token" != "null" && "$token" != "" ]]; then
                        if [[ "$last_was_reasoning" == "1" ]]; then #从reasoning切换到content
                            echo ""
			    echo -n ">>>>>>>>>>>>>思考结束. |"
			    echo ""
                            unset last_was_reasoning
                        fi
                        echo -n "$token"
                        response+="$token"
                        sleep 0.0005
                    fi
                fi
            fi
        done
    echo ""  # 换行
    echo "$response"  # 打印完整的响应
    printf "%s" "$response" #返回完整的响应
}
# 主逻辑
main() {
  read_config  # 读取配置
  check_and_prompt_config #检查并设置配置

    if [[ "$1" == "--set_api_url" ]]; then
        if [[ -z "$2" ]]; then
          echo "错误：--set_api_url 后面需要提供 URL。"
          exit 1
        fi
        set_api_url "$2"
    elif [[ "$1" == "--set_api_key" ]]; then
        if [[ -z "$2" ]]; then
          echo "错误：--set_api_key 后面需要提供 API Key。"
          exit 1
        fi
        set_api_key "$2"
    elif [[ "$1" == "--set_model" ]]; then
        if [[ -z "$2" ]]; then
          echo "错误：--set_model 后面需要提供模型名称。"
          exit 1
        fi
      set_model "$2"

    elif [[ "$1" == "-chat" ]]; then
        echo "进入 AI 聊天模式，输入 'exit' 退出。（使用模型：$MODEL）"
        history=()
        while true; do
            read -p "You: " user_input
            if [[ "$user_input" == "exit" ]]; then
                echo "退出 AI 聊天模式。"
                break
            fi
            history+=("{\"role\": \"user\", \"content\": \"$user_input\"}")
            payload="{\"model\": \"$MODEL\", \"messages\": [$(IFS=,; echo "${history[*]}")], \"stream\": true}"

            echo -n "AI: "
        response=$(stream_response "$payload" | tee /dev/tty)  # 捕获完整 AI 输出并同时输出到控制台
            history+=("{\"role\": \"assistant\", \"content\": \"$response\"}")
        done
    else
        question="$*"
        if [[ -z "$question" ]]; then
            echo "错误：请输入你的问题，例如：ai '你的问题'"
            exit 1
        fi

        payload="{\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"$question\"}], \"stream\": true}"

        echo -n "AI: "
        stream_response "$payload"
    fi
}

# 运行主函数
main "$@"
