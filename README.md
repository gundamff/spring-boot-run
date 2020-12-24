# spring-boot-run

## 简介
该项目是为了解决Spring Boot程序部署运行的问题

## 部署目录

```
.
├── run.sh
├── jvm-options.sh
├── boot.properties
└── app-web
   ├── boot.properties
   └── app-web.jar
```

### boot.properties
该文件是run.sh的参数文件，run.sh会引用此文件，里面的参数只供run.sh使用，不设置为环境变量（避免污染环境变量）

### jvm-options.sh
jvm-options.sh 生成jvm参数 , 参考 [唯品会@江南白衣 JVM调优指南](https://github.com/vipshop/vjtools/blob/master/vjstar/src/main/script/jvm-options/jvm-options.sh)

### run.sh
该脚本用来运行Spring Boot应用,程序部署时可以直接拷贝，根据服务的实际情况修改boot.properties即可

### 功能
1. 启动 start
2. 停止 stop
3. 状态 status
4. 重启 restart
5. 清理日志（为了防止误删日志，需要程序是停止状态下） cleanup
6. 部署jar包 (需要程序是停止状态)  deploy

### 样例

#### 启动
```
run.sh app-web start

```
使用boot.properties 中的参数启动app-web,其中端口号使用配置文件中的,首先加载当前目录的boot.properties,再加载app-web目录中的(如果存在的话)

```
run.sh app-web start 8081

```

#### 停止
```
run.sh app-web stop

```
同上

```
run.sh app-web stop 8081

```

#### 查看状态
```
run.sh app-web status

```
同上

```
run.sh app-web status 8081

```

#### 重启
```
run.sh app-web restart

```
同上

```
run.sh app-web restart 8081

```

#### 清理日志
```
run.sh app-web cleanup

```
同上

```
run.sh app-web cleanup 8081

```

#### 部署jia包
```
run.sh app-web deploy

```
不加版本号则部署最新版,加版本号部署指定版本

```
run.sh app-web deploy 2.0.2

```


## 问题
部署方法目前只能检查跑在默认配置的端口号上的程序是否在运行中,这里应该以ps的返回结果进行判断

stop all & restart all



