//
//  C8oLogger.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 05/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import CoreFoundation
import SwiftyJSON
import AEXML

@objc public class C8oLogger : NSObject
{
    private let RE_FORMAT_TIME : NSRegularExpression =  try! NSRegularExpression(pattern: "(\\d*?)(?:,|.)(\\d{3}).*", options: [])
    //*** Constants ***//
    
    
    
    private static var LOG_TAG :String  = "c8o"
    private static var LOG_INTERNAL_PREFIX :String = "[c8o] "
    
    
    
    static let  REMOTE_LOG_LIMIT : Int = 100
    
    
    private static var JSON_KEY_REMOTE_LOG_LEVEL  : String = "remoteLogLevel"
    private static var JSON_KEY_TIME  : String = "time"
    private static var JSON_KEY_LEVEL  : String = "level"
    private static var JSON_KEY_MESSAGE  : String = "msg"
    private static var JSON_KEY_LOGS  : String = "logs"
    private static var JSON_KEY_ENV  : String = "env"
    
    /** Attributes */
    
    private var remoteLogUrl : String?
    private var remoteLogs : Queue<JSON>?
    private var alreadyRemoteLogging : [Bool]?
    private var remoteLogLevel : C8oLogLevel?
    private var uidRemoteLogs :String?
    private var startTimeRemoteLog : NSDate?
    
    private var c8o : C8o
    
    private var env : String
    
    internal init(c8o :C8o)
    {
        self.c8o = c8o
        
        remoteLogUrl = c8o.endpointConvertigo + "/admin/services/logs.Add"
        remoteLogs = Queue<JSON>()
        alreadyRemoteLogging = [Bool]()
        alreadyRemoteLogging?.append(false)
        
        remoteLogLevel = C8oLogLevel.TRACE
        
        let currentTime = NSDate()
        startTimeRemoteLog = currentTime
        uidRemoteLogs = C8oTranslator.doubleToHexString(C8oUtils.getUnixEpochTime(currentTime)!)
        let envJSON : JSON = ["uid" : uidRemoteLogs!, "uuid" : c8o.deviceUUID, "project" : c8o.endpointProject]
        env = String(envJSON)
    }
    
    private func isLoggableRemote(logLevel : C8oLogLevel?) ->Bool
    {
        return c8o.logRemote && logLevel != nil && C8oLogLevel.TRACE.priority <= remoteLogLevel!.priority && remoteLogLevel!.priority <= logLevel!.priority
    }
    
    private func isLoggableConsole(logLevel : C8oLogLevel?) ->Bool
    {
        return logLevel != nil && C8oLogLevel.TRACE.priority <= c8o.logLevelLocal.priority && c8o.logLevelLocal.priority <= logLevel!.priority
    }
    
    /** Basics log */
    public func canLog(logLevel : C8oLogLevel) ->Bool
    {
        return isLoggableConsole(logLevel) || isLoggableRemote(logLevel)
    }
    
    public var isFatal : Bool
        {
        get { return canLog(C8oLogLevel.FATAL) }
    }
    
    public var isError : Bool
        {
        get { return canLog(C8oLogLevel.ERROR) }
    }
    
    public var isWarn : Bool
        {
        get { return canLog(C8oLogLevel.WARN) }
    }
    
    public var isInfo : Bool
        {
        get { return canLog(C8oLogLevel.INFO) }
    }
    
    public var isDebug : Bool
        {
        get { return canLog(C8oLogLevel.DEBUG) }
    }
    
    public var isTrace : Bool
        {
        get { return canLog(C8oLogLevel.TRACE) }
    }
    
    internal func log(logLevel: C8oLogLevel, message:String , exception: C8oException?! = nil) ->Void
    {
        var message = message
        let isLogConsole : Bool = isLoggableConsole(logLevel)
        let isLogRemote : Bool = isLoggableRemote(logLevel)
        
        if (isLogConsole || isLogRemote)
        {
            if (exception != nil)
            {
                message += "\n" + String(exception)
            }
            
            let time : String = String(NSDate().timeIntervalSinceDate(startTimeRemoteLog!))
            //let stringLevel : String = remoteLogLevel[logLevel]
            
            if (isLogRemote)
            {
                remoteLogs!.enqueue(JSON(
                    [C8oLogger.JSON_KEY_TIME : time,
                        C8oLogger.JSON_KEY_LEVEL : logLevel.name,
                        C8oLogger.JSON_KEY_MESSAGE : message
                    ]))
                logRemote()
            }
            
            if (isLogConsole)
            {
                debugPrint("(" + time + ") [" + logLevel.name + "] " + message)
                
            }
        }
    }
    
    public func fatal(message: String, exceptions: C8oException? = nil) ->Void
    {
        log(C8oLogLevel.FATAL, message: message, exception: exceptions)
    }
    
    public func error(message: String, exceptions: C8oException?  = nil) -> Void
    {
        log(C8oLogLevel.ERROR, message: message, exception: exceptions)
    }
    
    public func warn(message: String, exceptions: C8oException?  = nil) -> Void
    {
        log(C8oLogLevel.WARN, message: message, exception: exceptions)
    }
    
    public func info(message: String, exceptions: C8oException? = nil) -> Void
    {
        log(C8oLogLevel.INFO, message: message, exception: exceptions)
    }
    
    public func debug(message: String, exceptions: C8oException?  = nil) -> Void
    {
        log(C8oLogLevel.DEBUG, message: message, exception: exceptions)
    }
    
    public func trace(message: String, exceptions: C8oException?  = nil) -> Void
    {
        log(C8oLogLevel.TRACE, message: message, exception: exceptions)
    }
    
    internal func _log(logLevel : C8oLogLevel, messages : String, exceptions : C8oException?)->Void
    {
        if (c8o.logC8o)
        {
            log(logLevel, message: C8oLogger.LOG_INTERNAL_PREFIX + messages, exception: exceptions)
        }
    }
    
    internal func _fatal(message: String, exceptions: C8oException?) -> Void
    {
        _log(C8oLogLevel.FATAL, messages: message, exceptions: exceptions)
    }
    
    internal func _c8oException(message: String, exceptions:C8oException?) -> Void
    {
        _log(C8oLogLevel.ERROR, messages: message, exceptions: exceptions)
    }
    
    internal func _warn(message: String, exceptions: C8oException?) -> Void
    {
        _log(C8oLogLevel.WARN, messages: message, exceptions: exceptions)
    }
    
    internal func _info(message: String, exceptions: C8oException?) -> Void
    {
        _log(C8oLogLevel.INFO, messages: message, exceptions: exceptions)
    }
    
    internal func _debug(message: String, exceptions: C8oException?) -> Void
    {
        _log(C8oLogLevel.DEBUG, messages: message, exceptions: exceptions)
    }
    
    internal func _trace(message: String, exceptions: C8oException?) -> Void
    {
        _log(C8oLogLevel.TRACE, messages: message, exceptions: exceptions)
    }
    
    internal func logRemote() ->Void
    {
        var canLog : Bool  = false
        let condition : NSCondition = NSCondition()
        
        condition.lock()
        
        // If there is no another thread already logging AND there is at least one log
        canLog = !alreadyRemoteLogging![0] && remoteLogs!.Count() > 0
        if (canLog)
        {
            alreadyRemoteLogging![0] = true
        }
        
        condition.unlock()
        
        if (canLog) {
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)){
                
                // Take logs in the queue and add it to a json array
                var count : Int = 0
                let listSize : Int = self.remoteLogs!.Count()
                var logsArray = Array<JSON>()
                
                while (count < listSize && count < C8oLogger.REMOTE_LOG_LIMIT)
                {
                    logsArray.append(self.remoteLogs!.dequeue()!)
                    count = count + 1
                }
                
                // Initializes request paramters
                var uidS: String =  "{\"uid\":\""
                uidS += self.uidRemoteLogs!
                uidS += "\"}"
                var parameters = Dictionary<String, NSObject>()
                parameters =
                    
                    [C8oLogger.JSON_KEY_LOGS: String(logsArray),
                        C8oLogger.JSON_KEY_ENV: self.env,
                        C8o.ENGINE_PARAMETER_DEVICE_UUID: self.c8o.deviceUUID]
                
                
                var jsonResponse : JSON
                do
                {
                    let webResponse : (data : NSData?, error : NSError?) = self.c8o.httpInterface!.handleRequest(self.remoteLogUrl!, parameters: parameters)
                    if(webResponse.error != nil){
                        self.c8o.logRemote = false
                        if (self.c8o.logOnFail != nil)
                        {
                            self.c8o.logOnFail!(exception: C8oException(message: C8oExceptionMessage.RemoteLogFail(), exception: webResponse.error!), parameters: nil)
                        }
                        return
                    }
                    else{
                        jsonResponse = C8oTranslator.dataToJson(webResponse.data!)!
                    }
                    
                }
                /*catch _ as NSError
                {
                    
                }*/
                
                var logLevelResponse = jsonResponse[C8oLogger.JSON_KEY_REMOTE_LOG_LEVEL]
                
                if (logLevelResponse != nil)
                {
                    let logLevelResponseStr : String = logLevelResponse.stringValue
                    let c8oLogLevel = C8oLogLevel.getC8oLogLevel(logLevelResponseStr)
                    
                    if (c8oLogLevel != nil)
                    {
                        self.remoteLogLevel = c8oLogLevel!
                    }
                    
                    condition.lock()
                    self.alreadyRemoteLogging![0] = false
                    condition.unlock()
                    self.logRemote()
                    
                }
            }
                
                /*dispatch_async(dispatch_get_main_queue()){
                   
                }*/
        }
    }
    /** Others log */
    
    
    internal func logMethodCall(methodName : String, parameters : NSObject...)-> Void
    {
        if (c8o.logC8o && isDebug)
        {
            var methodCallLogMessage : String = "Method call : " + methodName
            if (isTrace && parameters.count > 0)
            {
                methodCallLogMessage += "\n" + String(parameters)
                _trace(methodCallLogMessage, exceptions: nil)
                
            }
            else
            {
                _debug(methodCallLogMessage, exceptions: nil)
            }
        }
    }
    
    
    internal func logC8oCall(url : String, parameters : Dictionary<String, NSObject>)->Void
    {
        if (c8o.logC8o && isDebug)
        {
            var c8oCallLogMessage : String = "C8o call : " + url
            
            if (parameters.count > 0)
            {
                c8oCallLogMessage += "\n" + String(parameters)
            }
            
            _debug(c8oCallLogMessage, exceptions: nil)
        }
    }
    
    
    internal func logC8oCallXMLResponse(response : AEXMLDocument, url: String, parameters : Dictionary<String, NSObject>)-> Void
    {
        logC8oCallResponse(C8oTranslator.xmlToString(response)!, responseType: "XML", url: url, parameters: parameters)
    }
    
    
    internal func logC8oCallJSONResponse(response : JSON, url : String?, parameters : Dictionary<String, NSObject>)-> Void
    {
        logC8oCallResponse(C8oTranslator.jsonToString(response)!, responseType: "JSON", url: url, parameters: parameters)
    }
    
    internal func logC8oCallResponse(responseStr : String, responseType : String, url: String?, parameters : Dictionary<String, NSObject>)-> Void
    {
        if(c8o.logC8o && isTrace)
        {
            var c8oCallResponseLogMessage : String
            if(url == nil){
                 c8oCallResponseLogMessage = "C8o call " + responseType + " response : "
            }
            else{
                c8oCallResponseLogMessage = "C8o call " + responseType + " response : " + url!
            }
            
            
            if (parameters.count > 0)
            {
                c8oCallResponseLogMessage += "\n" + parameters.description
            }
            
            c8oCallResponseLogMessage += "\n" + responseStr
            
            _trace(c8oCallResponseLogMessage, exceptions: nil)
        }
    }
}

@objc public class C8oLogLevel: NSObject
{
    //
    private static var JSON_KEY_REMOTE_LOG_LEVEL  : String = "remoteLogLevel"
    //
    
    internal static var NULL : C8oLogLevel = C8oLogLevel(name: "", priority: 0)
    public static var  NONE : C8oLogLevel = C8oLogLevel(name: "none", priority: 1)
    public static var TRACE : C8oLogLevel = C8oLogLevel(name: "trace", priority: 2)
    public static var DEBUG : C8oLogLevel = C8oLogLevel(name: "debug", priority: 3)
    public static var INFO : C8oLogLevel = C8oLogLevel(name: "info", priority: 4)
    public static var WARN : C8oLogLevel = C8oLogLevel(name: "warn", priority: 5)
    public static var ERROR : C8oLogLevel = C8oLogLevel(name: "error", priority: 6)
    public static var FATAL : C8oLogLevel = C8oLogLevel(name: "fatal", priority: 7)
    
    internal static var C8O_LOG_LEVELS : [C8oLogLevel] = [ NULL, NONE, TRACE, DEBUG, INFO, WARN, ERROR, FATAL ]
    
    internal var name : String
    internal var priority: Int
    
    private init(name : String, priority : Int)
    {
        self.name = name
        self.priority = priority
    }
    
    internal static func getC8oLogLevel(name : String) ->C8oLogLevel?
    {
        for c8oLogLevel in C8oLogLevel.C8O_LOG_LEVELS
        {
            if (c8oLogLevel.name == name)
            {
                return c8oLogLevel
            }
        }
        return nil
    }
}
