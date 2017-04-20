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
