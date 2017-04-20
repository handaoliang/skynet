/* vim: set expandtab tabstop=4 shiftwidth=4 foldmethod=marker: */
/**
 * @package              Skynet.SpamFilter.Daemon
 * @file                 $RCSfile: spam_filter.go,v $
 * @version              $Revision: 1.0 $
 * @modifiedby           $Author: handaoliang $
 * @lastmodified         $Date: 2015/06/17 12:02:11 $
**/
package main

import (
    "io"
    "log"
    "os"
    "time"

    "github.com/bitly/go-simplejson"
    "github.com/garyburd/redigo/redis"
)

//预定义LOG类型
var (
    Trace   *log.Logger
    Info    *log.Logger
    Warning *log.Logger
    Error   *log.Logger
)

//预定义常量，Redis配置、APIURI、ThresholdValue、DaemonLogoFile
const (
    IPBlockRedisDB   string = "127.0.0.1:6379"
    IPRecordsRedisDB string = "127.0.0.1:6380"
    IPQueueRedisDB   string = "127.0.0.1:6381"

    TraceLogFile   string = "/data/skynet_logs/system_logs/queue/trace.log"
    InfoLogFile    string = "/data/skynet_logs/system_logs/queue/info.log"
    WarningLogFile string = "/data/skynet_logs/system_logs/queue/Warning.log"
    ErrorLogFile   string = "/data/skynet_logs/system_logs/queue/error.log"
)

//初始化LOG方法函数。
func LogInitialize(TraceLogFileName, InfoLogFileName, WarningLogFileName, ErrorLogFileName string) {
    TraceLogFileHandler, err := os.OpenFile(TraceLogFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
    if err != nil {
        log.Fatalln("Failed to open trace log file Error :", err)
    }
    TraceMultiWriter := io.MultiWriter(TraceLogFileHandler, os.Stdout)
    Trace = log.New(TraceMultiWriter, "TRACE: ", log.Ldate|log.Ltime)

    InfoLogFileHandler, err := os.OpenFile(InfoLogFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
    if err != nil {
        log.Fatalln("Failed to open info log file Error :", err)
    }
    InfoMultiWriter := io.MultiWriter(InfoLogFileHandler, os.Stdout)
    Info = log.New(InfoMultiWriter, "INFO: ", log.Ldate|log.Ltime)

    WarningLogFileHandler, err := os.OpenFile(WarningLogFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
    if err != nil {
        log.Fatalln("Failed to open warning log file Error :", err)
    }
    WarningMultiWriter := io.MultiWriter(WarningLogFileHandler, os.Stdout)
    Warning = log.New(WarningMultiWriter, "WARNING: ", log.Ldate|log.Ltime)

    ErrorLogFileHandler, err := os.OpenFile(ErrorLogFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
    if err != nil {
        log.Fatalln("Failed to open error log file Error :", err)
    }
    ErrorMultiWriter := io.MultiWriter(ErrorLogFileHandler, os.Stdout)
    Error = log.New(ErrorMultiWriter, "ERROR: ", log.Ldate|log.Ltime)
}

//队列操作函数
func QueueOperation() {

    redisQueueConn, err := redis.DialTimeout("tcp", IPQueueRedisDB, 0, 1*time.Second, 1*time.Second)
    if err != nil {
        Error.Println("Connect Queue Redis Error, ", err)
        os.Exit(0)
    }

    var key string
    var result string

    reply, _ := redis.Values(redisQueueConn.Do("brpop", "ip.queue.main", 100))

    if _, err := redis.Scan(reply, &key, &result); err != nil {
        //Error.Println("Scan Redis Error, ", err)
        return
    }

    byteResult := []byte(result)
    simpleJSON, _ := simplejson.NewJson(byteResult)
    ipAddress, _ := simpleJSON.Get("ip").String()
    actions, _ := simpleJSON.Get("actions").String()

    //关闭当前连接。
    redisQueueConn.Close()

    if actions == "spam_analyze" {

        redisIPRecordsConn, err := redis.DialTimeout("tcp", IPRecordsRedisDB, 0, 1*time.Second, 1*time.Second)
        if err != nil {
            Error.Println("Connect IPRecords Redis DB Error, ", err)
        }

        var redisKey = "ip:" + ipAddress
        postNumber, _ := redis.Int64(redisIPRecordsConn.Do("HGET", redisKey, "post_number"))

        //关闭Records Redis DB连接
        redisIPRecordsConn.Close()

        if postNumber > 10 {
            //将这个IP加入到Block List
        }

    }

}

func main() {
    LogInitialize(TraceLogFile, InfoLogFile, WarningLogFile, ErrorLogFile)
    QueueOperation()
    /*
       var i int
       for {
           i = i + 1
           //time.Sleep(time.Second / 10)
           time.Sleep(time.Millisecond)
           QueueOperation()
           //Error.Println(i)
       }
    */
}
