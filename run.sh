#!/bin/bash
# -------------------------------------------------------------------------------
# Description: 应用启动脚本,支持Mac,Linux
# -------------------------------------------------------------------------------

#应用名称
APP_NAME=$1

#操作
ACTION=$2

#其他参数 deploy代表版本号 start/stop代表端口
PARAMETER=$3

#应用主目录
if [ ! -x "$APP_NAME" ]; then
  if ("$RUN_IN_DOCKER");then
     echo "skip mkdir"
  else
     mkdir $APP_NAME
  fi
fi

cd $APP_NAME || exit 1
APP_HOME=$(pwd)

BOOT_CONF="boot.properties"

#2.引入启动配置
# 先引入上级配置,再引入本目录下配置
. "../$BOOT_CONF"
if [ -r "$BOOT_CONF" ]; then
    . "$BOOT_CONF"
fi

LOG_DIR="${APP_HOME}/${SERVER_PORT}/logs"

PID_FILE="${APP_HOME}/${SERVER_PORT}/app.pid"

if [[ -z $GROUPID ]];
    then
        GROUPID="com.qlteacher"
fi

#应用JAR
#APP_JAR="$(find "${APP_HOME}" -name "*.jar" 2>/dev/null | head -n 1)"
APP_JAR="$APP_NAME.jar"

echoRed() { echo $'\e[0;31m'"$1"$'\e[0m'; }
echoGreen() { echo $'\e[0;32m'"$1"$'\e[0m'; }
echoYellow() { echo $'\e[0;33m'"$1"$'\e[0m'; }

usage() {
    echo $'\n\n\n'
    echoRed "用法: ${0} 支持的命令 {start|stop|restart|status|cleanup|deploy}"
    echo $'\n\n\n'
    exit 1
}

psCheck() {
    echo "--------------本机上的所有实例--------------"
    echo "USER       PID   %CPU %MEM VSZ    RSS    TTY   STAT  START   TIME COMMAND" && echo ""
    ps aux | grep "$APP_NAME" | grep -E -v "grep"
}

#根据PID_FILE检查是否在运行
isRunning() {
    [[ -f "$PID_FILE" ]] || return 1
    ps -p "$(<"$PID_FILE")" &>/dev/null
}

#1.检查操作参数
[ $# -gt 0 ] || usage

setServerPort() {
    #基础配置
    if [[ ! -z $PARAMETER ]];
    then
        SERVER_PORT=$PARAMETER
    fi
    
    LOG_DIR="${APP_HOME}/${SERVER_PORT}/logs"
    PID_FILE="${APP_HOME}/${SERVER_PORT}/app.pid"
}

start() {
    setServerPort

    source ../jvm-options.sh

    BASE_ARGS="--spring.profiles.active=$PROFILES_ACTIVE "

    RUN_EXE="$JAVA_EXE $JVM_ARGS $JAVA_OPTS -Dserver.port=$SERVER_PORT -jar $APP_JAR $BASE_ARGS  $OPT_ARGS"
    
    echo "--------------启动 $APP_NAME: 端口: $SERVER_PORT"
    echo $'\n\n\n'

    #检查jdk
    if [ -z "$JAVA_EXE" ]; then
        echoRed "Result: 启动失败,没有找到JDK. 请检查 boot.properties文件里的JAVA_EXE 参数"
        echo $'\n\n\n'
        exit 1
    fi

    #检查已经运行
    if (isRunning); then
        echoYellow "Result: 运行中 无需启动"
        echo $'\n\n\n'
        exit 0
    fi

    if ("$RUN_IN_DOCKER");then
        # 在docker内启动 不需要nohup
        echo "是否在docker内运行 = $RUN_IN_DOCKER"
        #打印启动命令
        echo "-------Boot Command: "
        echo "$RUN_EXE"
        echo $'\n\n\n'
        #启动
        $RUN_EXE
    else
         echo "是否在docker内运行 = $RUN_IN_DOCKER"
         #打印启动命令
         echo "-------Boot Command: "
         echo "nohup $RUN_EXE >${LOG_DIR}/error.log 2>&1 &"
         echo $'\n\n\n'

         #创建错误日志文件
         mkdir -p "$LOG_DIR" && touch "${LOG_DIR}/error.log"
         #清空日志信息
         >${LOG_DIR}/error.log
         #启动
         nohup $RUN_EXE >"${LOG_DIR}/error.log" 2>&1 &
    fi
    
    #记录pid到pid文件
    echo "$!" >"$PID_FILE"

    #命令执行异常，快速失败
    sleep 1
    if (! isRunning); then
        echoRed "1s Result: Start failed" && rm -f "$PID_FILE"
        echo $'\n\n\n'
        exit 1
    fi

    #启动几秒钟中后失败的情况，6秒内失败
    sleep 6
    if (! isRunning); then
        echoRed "6s Result: Start failed" && rm -f "$PID_FILE"
        echo $'\n\n\n'
        exit 1
    fi

    #启动几秒钟中后失败的情况，10秒内失败
    sleep 10
    if (! isRunning); then
        echoRed "10s Result: Start failed" && rm -f "$PID_FILE"
        echo $'\n\n\n'
        exit 1
    fi

    #启动几秒钟中后失败的情况，启动在10秒外失败的比例比较低，而且也不可能一直等，这种情况交给监控告警来解决

    echoGreen "Result: Start success,Running (PID: $(<"$PID_FILE"))"
    echo $'\n\n\n'

    #检查本机存在的实例
    psCheck
}

stop() {
    setServerPort
    echo "--------------停止 $APP_NAME: 端口: $SERVER_PORT"
    echo $'\n\n\n'

    if (! isRunning); then
        echoYellow "Result: Not running" && rm -f "$PID_FILE"
        echo $'\n\n\n'
        return 0
    fi

    kill "$(<"$PID_FILE")" 2>/dev/null

    #30秒后强制退出
    TIMEOUT=60
    while isRunning; do
        if ((TIMEOUT-- == 0)); then
            kill -KILL "$(<"$PID_FILE")" 2>/dev/null
        fi
        sleep 1
    done

    rm -f "$PID_FILE"
    echoGreen "Result: Stop success"
    echo $'\n\n\n'
    
    psCheck
}

status() {
    echo "--------------Status $APP_NAME:"
    echo $'\n\n\n'

    if isRunning; then
        echoGreen "Result: Running （PID: $(<"$PID_FILE"))"
    else
        echoYellow "Result: Not running"
    fi

    echo $'\n\n\n'
    psCheck
}

cleanup() {
    echo "--------------Cleanup $APP_NAME:"
    echo $'\n\n\n'
    if ! isRunning; then
        [[ -d "$LOG_DIR" ]] || {
            echoGreen "Result: Log does not exist, there is no need to clean up" && echo $'\n\n\n'
            return 0
        }
        rm -rf "$LOG_DIR"
        echoGreen "Result: Log cleared"
    else
        echoYellow "Result: Please stop the application first and then clean up the log"
    fi
    echo $'\n\n\n'
}

deploy() {
    VERSION=$PARAMETER
    if [[ -z $VERSION ]];
    then
        VERSION="LATEST"
    fi
    
    echo "--------------deploy $APP_NAME:$VERSION"
    echo $'\n\n\n'
    if isRunning; then
        echoRed "运行中无法发布"
    else
        rm -rf $APP_NAME.jar
        mvn dependency:get -Dartifact=$GROUPID:$APP_NAME:$VERSION -DremoteRepositories=http://you-nexus/repository/public/ -Ddest=$APP_HOME/$APP_NAME.jar -Dtransitive=false
        if [ -f "$APP_NAME".jar ]; then
            echoGreen "发布完成"
            return 0
        else
            echoRed "发布失败"
        fi
    fi
    echo $'\n\n\n'
}

case "$ACTION" in
start)
    start
    ;;
stop)
    stop
    ;;
restart)
    stop
    start
    ;;
status)
    status
    ;;
cleanup)
    cleanup
    ;;
deploy)
    deploy
    ;;
*)
    usage
    ;;
esac

#成功退出
exit 0