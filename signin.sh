#!/usr/bin/env bash

set -u
set -o pipefail

if ! command -v curl >/dev/null 2>&1; then
  echo "错误：未找到 curl，请先安装 curl。"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "错误：未找到 jq，请先安装 jq。"
  exit 1
fi

if [ -z "${COOKIE:-}" ]; then
  echo "错误：环境变量 COOKIE 为空。"
  exit 1
fi

RANDOM_MODE="${Random:-false}"
if [ "$RANDOM_MODE" = "true" ]; then
  attendance_url='https://www.nodeseek.com/api/attendance?random=true'
else
  attendance_url='https://www.nodeseek.com/api/attendance?random=false'
fi

IFS=$'\n' read -r -d '' -a COOKIES < <(printf '%s\0' "$COOKIE")

for cookie_item in "${COOKIES[@]}"; do
  if [ -z "$cookie_item" ]; then
    continue
  fi

  if ! response=$(curl -sS "$attendance_url" --compressed -X POST \
    -H "Cookie: $cookie_item"); then
    echo "签到失败，网络请求异常"
    continue
  fi

  echo "Response: $response"

  if ! echo "$response" | jq -e . >/dev/null 2>&1; then
    echo "签到失败，返回非 JSON：$response"
    continue
  fi

  success=$(echo "$response" | jq -r '.success // false')
  if [ "$success" = "true" ]; then
    message=$(echo "$response" | jq -r '.message // ""')
    current=$(echo "$response" | jq -r '.current // 0')

    if [ "$RANDOM_MODE" = "true" ]; then
      echo "签到成功，$message，如今有$current个鸡腿"
    else
      gain=$(echo "$response" | jq -r '.gain // 0')
      echo "签到成功，$message，本次获得$gain个鸡腿，如今有$current个鸡腿"
    fi
  else
    echo "签到失败，错误信息：$response"
  fi
done
