## 天网防火墙安装部署文档

#### 一、环境要求：
原则上，只要保证OpenResty 1.5.8+ 就可以满足需求了。但是如果是自编译整合LuaJIT到Nginx还是明确一下各依赖软件的版本：
1. Nginx 1.7.0+
2. luaJIT 2.1+
3. LuaNginxModule 0.9.2+

#### 二、程序部署
1. 从 `http://192.168.1.251:8000/git/lua_skynet` Clone出Master最新代码。
2. 程序部署到 `/opt/skynet`，程序代码目录结构如下：
<pre>
.
├── _Document //文档存放目录
│   ├── DaemonDocument.md
│   ├── InstallDocument.md
│   └── skynet.nginx.conf
├── apps //防火墙脚本目录
│   └── skynet.lua
├── daemon //Golang后台分析程序存放目录。
│   └── spam_filter.go
├── libs //防火墙库文件
│   ├── conf.lua.sample
│   ├── core.lua
│   └── func.lua
└── rules //防火墙过滤规则文件
    ├── UserAgent
    ├── url
    └── whiteurl
</pre>

3. 创建日志存放目录：
<pre>
创建用以存放攻击日志的目录：
$ sudo mkdir -p /data/skynet_logs/hack_logs/
创建用以存放天网系统日志的目录：
$ sudo mkdir -p /data/skynet_logs/system_logs/
</pre>

4. 配置OpenResty，在全局Conf中加入以下配置：
<pre>
    lua_code_cache on;
    lua_socket_log_errors off;
    lua_package_path "/opt/skynet/libs/?.lua;;";
    lua_shared_dict cc_attack_dict 128m;
    access_by_lua_file /opt/skynet/apps/skynet.lua;
</pre>

5. 配置天网系统：
修改 `conf.lua`，然后根据注释修改相关参数。包括Redis参数。

6.　修改完成重启Nginx，观察Error LOG，看是否有错误。


### 后台任务通知程序。基于GoLang。依赖于以下包：
- go get github.com/bitly/go-simplejson
- go get github.com/garyburd/redigo/redis

	- 进程采用Daemonize来控制。Daemeize的安装使用：
	- git clone git://github.com/bmc/daemonize.git
	- cd daemonize
	- ./configure --prefix=/opt/iapps/daemonize
	- make && make install

	- 运行测试：
		- /opt/daemonize/sbin/daemonize -v

	- 使用：
		- /opt/daemonize/sbin/daemonize -p /data/skynet/daemon.pid -l /data/skynet/daemon.lock -u root /data/skynet/daemon/skynet_queue

	- 测试环境：
		-  /opt/daemonize/sbin/daemonize -p /data/skynet/queue/daemon.pid -l /data/skynet/queue/daemon.lock -u root /opt/skynet/daemon/skynet_queue
