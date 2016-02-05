//
//  C8oLogger.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 05/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


 public class C8oLogger
{
    private let RE_FORMAT_TIME : NSRegularExpression =  try! NSRegularExpression(pattern: "(\\d*?)([\\d ]{4})((?:\\.[\\d ]{3})|(?: {4}))", options: [])
    //*** Constants ***//
    
    /// <summary>
    /// The log tag used by the SDK.
    /// </summary>
    
    private static var LOG_TAG :String  = "c8o";
    private static var LOG_INTERNAL_PREFIX :String = "[c8o] ";
    
    
    /// <summary>
    /// The maximum number of logs sent to the Convertigo server in one time.
    /// </summary>
    private static var  REMOTE_LOG_LIMIT :Int = 100;
    /// <summary>
    /// Convertigo log levels.
    /// </summary>
    // private static String[] REMOTE_LOG_LEVELS = { "", "none", "trace", "debug", "info", "warn", "error", "fatal" };
    
    private static var JSON_KEY_REMOTE_LOG_LEVEL  : String = "remoteLogLevel";
    private static var JSON_KEY_TIME  : String = "time";
    private static var JSON_KEY_LEVEL  : String = "level";
    private static var JSON_KEY_MESSAGE  : String = "msg";
    private static var JSON_KEY_LOGS  : String = "logs";
    private static var JSON_KEY_ENV  : String = "env";
    
    //*** Attributes ***//
    
    /// <summary>
    /// The URL used to send logs.
    /// </summary>
    private var remoteLogUrl : String;
    /// <summary>
    /// Contains logs to be sent to the Convertigo server.
    /// </summary>
    private var remoteLogs : Queue<JObject>
    /// <summary>
    /// Indicates if a thread is sending logs.
    /// </summary>
    private var alreadyRemoteLogging : [Bool];
    /// <summary>
    /// The log level returned by the Convertigo server.
    /// </summary>
    private var remoteLogLevel : C8oLogLevel;
    /// <summary>
    /// The UID sent to the Convertigo server.
    /// </summary>
    private var uidRemoteLogs :String;
    /// <summary>
    /// The date in milliseconds at the creation of the C8o instance.
    /// </summary>
    private var startTimeRemoteLog : NSDate;
    
    private var c8o : C8o;
    
    internal init(c8o :C8o)
    {
        self.c8o = c8o;
    
        remoteLogUrl = self.c8o.EndpointConvertigo + "/admin/services/logs.Add";
        remoteLogs = Queue<JObject>();
        alreadyRemoteLogging[0] = false;
    
        remoteLogLevel = C8oLogLevel.TRACE;
    
        var currentTime = NSDate();
        startTimeRemoteLog = currentTime;
        uidRemoteLogs = C8oTranslator.DoubleToHexString(C8oUtils.GetUnixEpochTime(currentTime));
    }
    
    private func IsLoggableRemote(logLevel : C8oLogLevel) ->Bool
    {
        return c8o.LogRemote && logLevel != null && C8oLogLevel.TRACE.priority <= remoteLogLevel.priority && remoteLogLevel.priority <= logLevel.priority;
    }
    
    private func IsLoggableConsole(logLevel : C8oLogLevel) ->Bool
    {
        return logLevel != null && C8oLogLevel.TRACE.priority <= c8o.LogLevelLocal.priority && c8o.LogLevelLocal.priority <= logLevel.priority;
    }
    
    //*** Basics log ***//
    public func CanLog(logLevel : C8oLogLevel) ->Bool
    {
        return IsLoggableConsole(logLevel) || IsLoggableRemote(logLevel);
    }
    
    public var IsFatal : Bool
    {
        get { return CanLog(C8oLogLevel.FATAL); }
    }
    
    public var IsError : Bool
    {
        get { return CanLog(C8oLogLevel.ERROR); }
    }
    
    public var IsWarn  : Bool
    {
        get { return CanLog(C8oLogLevel.WARN); }
    }
    
    public var IsInfo  : Bool
    {
        get { return CanLog(C8oLogLevel.INFO); }
    }
    
    public var IsDebug  : Bool
    {
        get { return CanLog(C8oLogLevel.DEBUG); }
    }
    
    public var IsTrace  : Bool
    {
        get { return CanLog(C8oLogLevel.TRACE); }
    }
    
    internal func Log(logLevel: C8oLogLevel, var message:String , exception: NSException! = nil) ->Void
    {
        var isLogConsole : Bool = IsLoggableConsole(logLevel);
        var isLogRemote : Bool = IsLoggableRemote(logLevel);
    
        if (isLogConsole || isLogRemote)
        {
            if (exception != nil)
            {
                message += "\n" + String(exception)
            }
    
            var time : String = String(NSDate().timeIntervalSinceDate(startTimeRemoteLog))
            
            time = RE_FORMAT_TIME.Replace(time, "$1.$2");
    
            if (isLogRemote)
            {
                remoteLogs.Enqueue(new JObject()
                    {
                        { JSON_KEY_TIME, time},
                        { JSON_KEY_LEVEL, logLevel.name},
                        { JSON_KEY_MESSAGE, message }
                    });
                LogRemote();
            }
    
            if (isLogConsole)
            {
                System.Diagnostics.Debug.WriteLine("(" + time + ") [" + logLevel.name + "] " + message);
            }
        }
    }
    
    
    
}