#!/bin/bash

# 服务列表记录
servers=server.list

createAppInstance() {
    echo "\n>>>>>>>>开始设置环境参数,输入 q 退出<<<<<<<<<\n"

    # 检测系统CATALINA_HOME变量
    tips=
    if [ ! -z $CATALINA_HOME ] ; then tips="(直接回车使用系统默认: $CATALINA_HOME) "; fi

    # 设置CATALINA_HOME
    catalinaHome=
    while [ -z $catalinaHome ] ; do
      read -p "请输入CATALINA_HOME: $tips" catalinaHome
      if [ -z $catalinaHome ] && [ ! -z $CATALINA_HOME ] ; then
        catalinaHome=$CATALINA_HOME
      else
        if [ ! -z $catalinaHome ] ; then
          [ $catalinaHome = "q" ] && exit 0
        fi
      fi

      if [ ! -z $catalinaHome ] && [ ! -d "$catalinaHome" ] ; then
        catalinaHome=
        echo "\t您输入的目录不存在, 请检查后重新输入!"
      fi
    done

    if [ -z $catalinaHome ]; then echo "ERROR:\t系统没有指定CATALINA_HOME,请指定CATALINA_HOME!" && exit 0; fi

    # 设置APPID
    appId=
    while [ -z $appId ] ; do
      read -p "请输入APPID: " appId
      if [ ! -z $appId ] ; then
        [ $appId = "q" ] && exit 0

        if [ -d "tomcat_$appId" ] ; then
          read -p "APPID: $appId 已存在,是否覆盖(y/n): " yes
          if [ -z $yes ] || [ $yes = "n" ] ; then
            appId=
          else
            # 去掉server.list中的记录
            `sed -i.bak "/app_id: $appId/d" $servers`
          fi
        fi
      fi
    done

    if [ -z $appId ]; then echo "ERROR:\tAPPID不能为空" && exit 0; fi

    # 设置port
    #read -p "使用随机端口: (输入 n 自己手工设置)" defPort

    #if [  "$defPort" != "n" ]; then
    #  serverPort=`shuf -i 8005-8015 -n 1`


    echo ""
    echo "====================================="
    echo "== CATALINA_HOME= $catalinaHome"
    echo "== APPID= $appId"
    echo "== DIR= `pwd`/tomcat_$appId"
    echo "====================================="
    echo ""

    [ -d "tomcat_$appId" ] && `rm -rf "tomcat_$appId"`

    mkdir "tomcat_$appId"

    cd tomcat_$appId

    cp -r $catalinaHome/conf . && mkdir logs && mkdir temp && mkdir webapps

    cd ../

    echo "catalina_home: $catalinaHome ** app_id: $appId ** dir: `pwd`/tomcat_$appId" >> $servers

    echo "\n>>>>>>>>创建新服务成功!<<<<<<<<<"
    echo ">>>>>>>>请修改端口后再运行(tomcat_$appId/conf/server.xml)<<<<<<<<"
    return
}

executeCommand() {
  awk -F "**|:" '
    BEGIN {
      print "----------服务列表----------"
    }
    {
      print NR ") " $3 ": " $4
    }
    END {
      print ""
      print "命令格式: appId {start|stop|restart} 详细参考catalina.sh -h"
    }
  ' $servers

  cmd= 
  while [ -z "$cmd" ]; do
    read -p "请输入命令: ( q 退出) " cmd
    if [ "$cmd" = "q" ]; then
      break; return;
    fi
  done

  #awk 'BEGIN {print split('"\"$cmd\""', arrs, " ")}'
  #`IFS=' '; arrs=($cmd); unset IFS;`
  arrs=(${cmd//:/ })

  row=`sed -n "/app_id: ${arrs[0]}/p" $servers`
  if [ -z "$row" ]; then
    echo "没有找到服务 ${arrs[0]}"
    return
  fi

  echo "[DEBUG] Find>> $row"

  read catHome catBase <<< $(awk -F "**|:" '{print $2; print $6}' <<< "$row")
  
  echo "[DEBUG] Home: $catHome, Base: $catBase"

  export CATALINA_HOME="$catHome"
  export CATALINA_BASE="$catBase"
  echo "[DEBUG] CATALINA_HOME: $CATALINA_HOME"
  echo "[DEBUG] CATALINA_BASE: $CATALINA_BASE"

  $CATALINA_HOME/bin/catalina.sh ${arrs[1]} && tail -f $CATALINA_BASE/logs/catalina.out
}

while :
  do
    clear
    echo "-------------------------------"
    echo "              菜单              "
    echo "-------------------------------"
    echo "[1] 创建新服务实例"
    echo "[2] 启动 重启&停止 服务"
    echo "[3] 退出"
    echo "-------------------------------"
    echo -n "请选择: "
    read opt
    case $opt in
      1) createAppInstance; echo "Press a key. . ."; read x ;;
      2) executeCommand; echo "Press a key. . ."; read x ;;
      3) exit 0 ;;
      *) echo "请选择 1,2,3"; 
         echo "Press a key. . ."; read x ;;
  esac
done
