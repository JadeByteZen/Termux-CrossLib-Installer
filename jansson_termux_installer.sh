#!/bin/bash
set -euo pipefail

INSTALL_PREFIX="${PREFIX:-/usr/local}"
BUILD_THREADS=8
JANSSON_REPO="https://ghfast.top/https://github.com/akheron/jansson"
WORKING_DIR="${HOME}/jansson_build"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_intro() {
    echo -e "${GREEN}
    ██╗ █████╗ ███╗   ██╗███████╗ █████╗ ███╗   ██╗
    ██║██╔══██╗████╗  ██║██╔════╝██╔══██╗████╗  ██║
    ██║███████║██╔██╗ ██║███████╗███████║██╔██╗ ██║
██╗██║██╔══██║██║╚██╗██║╚════██║██╔══██║██║╚██╗██║
╚█████╔╝██║  ██║██║ ╚████║███████║██║  ██║██║ ╚████║
 ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝
    ${NC}"
    echo -e "${BLUE}▶ 专业版 Jansson 安装脚本 (Termux 适配)"
    echo -e "${BLUE}▶ 功能：高性能 JSON 解析库 (C语言)"
    echo -e "${BLUE}▶ 特性：内存安全、Unicode 支持、流式解析"
    echo -e "${BLUE}▶ 适配：自动检测 Termux 环境并优化配置${NC}\n"
}

check_termux() {
    if [ -d "/data/data/com.termux/files/usr" ]; then
        INSTALL_PREFIX="/data/data/com.termux/files/usr"
        echo -e "${YELLOW}检测到 Termux 环境，自动调整安装路径${NC}"
    fi
}

prompt_install() {
    echo -e "${YELLOW}▷ 即将安装以下内容："
    echo -e "  - libjansson.so (核心库)"
    echo -e "  - jansson.h (开发头文件)"
    echo -e "  - pkg-config 配置文件"
    echo -e "\n▷ 解决的环境问题："
    echo -e "  - 自动安装编译依赖 (git,make,clang)"
    echo -e "  - 修复 Termux 的路径问题"
    echo -e "  - 优化 CPU 编译参数${NC}"
    
    read -p "是否继续安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}安装已取消${NC}"
        exit 1
    fi
}

install_deps() {
    local termux_deps=("git" "make" "clang" "cmake")
    local linux_deps=("build-essential" "cmake" "git")
    
    if [ -d "/data/data/com.termux/files/usr" ]; then
        echo -e "${BLUE}▶ 正在安装 Termux 依赖...${NC}"
        pkg update -y && pkg install -y "${termux_deps[@]}" || {
            echo -e "${RED}依赖安装失败，请手动执行："
            echo -e "pkg update && pkg install git make clang cmake${NC}"
            exit 1
        }
    else
        echo -e "${BLUE}▶ 正在安装 Linux 依赖...${NC}"
        apt-get update && apt-get install -y "${linux_deps[@]}" || {
            echo -e "${RED}依赖安装失败，请手动执行："
            echo -e "apt update && apt install build-essential cmake git${NC}"
            exit 1
        }
    fi
}

build_jansson() {
    mkdir -p "$WORKING_DIR" && cd "$WORKING_DIR"
    [ ! -d "jansson" ] && git clone "$JANSSON_REPO"
    cd jansson && mkdir -p build && cd build
    
    cmake .. \
        -DJANSSON_BUILD_DOCS=OFF \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCMAKE_BUILD_TYPE=Release
    
    make -j"$BUILD_THREADS"
    make install
}

verify_install() {
    echo -e "\n${GREEN}✅ 安装完成！验证结果：${NC}"
    echo -e "${YELLOW}▶ 库文件位置："
    ls -lh "${INSTALL_PREFIX}/lib/libjansson"*
    echo -e "\n▶ 开发头文件："
    ls -lh "${INSTALL_PREFIX}/include/jansson.h"
    
    echo -e "\n${GREEN}🔧 使用说明："
    echo -e "1. 编译时添加参数：-ljansson"
    echo -e "2. 示例代码："
    echo -e "${BLUE}#include <jansson.h>"
    echo -e "int main() {"
    echo -e "    json_t *root = json_object();"
    echo -e "    json_object_set_new(root, \"name\", json_string(\"Termux\"));"
    echo -e "    json_dump_file(root, \"data.json\", 0);"
    echo -e "    json_decref(root);"
    echo -e "}${NC}"
}

cleanup() {
    echo -e "${BLUE}▶ 清理临时文件...${NC}"
    rm -rf "$WORKING_DIR"
}

main() {
    show_intro
    check_termux
    prompt_install
    install_deps
    build_jansson
    verify_install
    cleanup
}

main "$@"