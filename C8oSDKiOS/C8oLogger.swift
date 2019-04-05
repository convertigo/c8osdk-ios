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

@objc open class C8oLogger: NSObject {
    fileprivate let RE_FORMAT_TIME: NSRegularExpression = try! NSRegularExpression(pattern: "(\\d*?)(?:,|.)(\\d{3}).*", options: [])
    // *** Constants ***//
    
    fileprivate static var LOG_TAG: String = "c8o"
    fileprivate static var LOG_INTERNAL_PREFIX: String = "[c8o] "
    
    static let REMOTE_LOG_LIMIT: Int = 100
    
    fileprivate static var JSON_KEY_REMOTE_LOG_LEVEL: String = "remoteLogLevel"
    fileprivate static var JSON_KEY_TIME: String = "time"
    fileprivate static var JSON_KEY_LEVEL: String = "level"
    fileprivate static var JSON_KEY_MESSAGE: String = "msg"
    fileprivate static var JSON_KEY_LOGS: String = "logs"
    fileprivate static var JSON_KEY_ENV: String = "env"
    
    /** Attributes */
    
    fileprivate var remoteLogUrl: String?
    fileprivate var remoteLogs: Queue<JSON>?
    fileprivate var alreadyRemoteLogging: [Bool]?
    fileprivate var remoteLogLevel: C8oLogLevel?
    fileprivate var uidRemoteLogs: String?
    fileprivate var startTimeRemoteLog: Date?
    
    fileprivate var c8o: C8o
    
    fileprivate var env: String
    
    internal init(c8o: C8o) {
        self.c8o = c8o
        
        remoteLogUrl = c8o.endpointConvertigo + "/admin/services/logs.Add"
        remoteLogs = Queue<JSON>()
        alreadyRemoteLogging = [Bool]()
        alreadyRemoteLogging?.append(false)
        
        remoteLogLevel = C8oLogLevel.trace
        
        let currentTime = Date()
        startTimeRemoteLog = currentTime
        uidRemoteLogs = C8oTranslator.doubleToHexString(C8oUtils.getUnixEpochTime()!)
        let envJSON: JSON = ["uid": uidRemoteLogs!, "uuid": c8o.deviceUUID, "project": c8o.endpointProject]
        env = String(describing: envJSON)
    }
    
    fileprivate func isLoggableRemote(_ logLevel: C8oLogLevel?) -> Bool {
        return c8o.logRemote && logLevel != nil && C8oLogLevel.trace.rawValue <= remoteLogLevel!.rawValue && remoteLogLevel!.rawValue <= logLevel!.rawValue
    }
    
    fileprivate func isLoggableConsole(_ logLevel: C8oLogLevel?) -> Bool {
        return logLevel != nil && C8oLogLevel.trace.rawValue <= c8o.logLevelLocal.rawValue && c8o.logLevelLocal.rawValue <= logLevel!.rawValue
    }
    
    /** Basics log */
    open func canLog(_ logLevel: C8oLogLevel) -> Bool {
        return isLoggableConsole(logLevel) || isLoggableRemote(logLevel)
    }
    
    open var isFatal: Bool {
        get { return canLog(C8oLogLevel.fatal) }
    }
    
    open var isError: Bool {
        get { return canLog(C8oLogLevel.error) }
    }
    
    open var isWarn: Bool {
        get { return canLog(C8oLogLevel.warn) }
    }
    
    open var isInfo: Bool {
        get { return canLog(C8oLogLevel.info) }
    }
    
    open var isDebug: Bool {
        get { return canLog(C8oLogLevel.debug) }
    }
    
    open var isTrace: Bool {
        get { return canLog(C8oLogLevel.trace) }
    }
    
    internal func log(_ logLevel: C8oLogLevel, message: String, exception: C8oException?! = nil) -> Void {
        var message = message
        let isLogConsole: Bool = isLoggableConsole(logLevel)
        let isLogRemote: Bool = isLoggableRemote(logLevel)
        
        if (isLogConsole || isLogRemote) {
            if (exception! != nil) {
                message += "\n" + String(describing: exception)
            }
            
            let time: String = String(Date().timeIntervalSince(startTimeRemoteLog!))
            // let stringLevel : String = remoteLogLevel[logLevel]
            
            if (isLogRemote) {
                remoteLogs!.enqueue(JSON(
                    [C8oLogger.JSON_KEY_TIME: time,
                     C8oLogger.JSON_KEY_LEVEL: logLevel.name(),
                     C8oLogger.JSON_KEY_MESSAGE: message
                    ]))
                logRemote()
            }
            
            if (isLogConsole) {
                print("(" + time + ") [" + logLevel.name() + "] " + message)
                
            }
        }
    }
    
    @objc open func fatal(_ message: String, exceptions: C8oException? = nil) -> Void {
        log(C8oLogLevel.fatal, message: message, exception: exceptions)
    }
    
    @objc open func error(_ message: String, exceptions: C8oException? = nil) -> Void {
        log(C8oLogLevel.error, message: message, exception: exceptions)
    }
    
    @objc open func warn(_ message: String, exceptions: C8oException? = nil) -> Void {
        log(C8oLogLevel.warn, message: message, exception: exceptions)
    }
    
    @objc open func info(_ message: String, exceptions: C8oException? = nil) -> Void {
        log(C8oLogLevel.info, message: message, exception: exceptions)
    }
    
    @objc open func debug(_ message: String, exceptions: C8oException? = nil) -> Void {
        log(C8oLogLevel.debug, message: message, exception: exceptions)
    }
    
    @objc open func trace(_ message: String, exceptions: C8oException? = nil) -> Void {
        log(C8oLogLevel.trace, message: message, exception: exceptions)
    }
    
    internal func _log(_ logLevel: C8oLogLevel, messages: String, exceptions: C8oException?) -> Void {
        if (c8o.logC8o) {
            log(logLevel, message: C8oLogger.LOG_INTERNAL_PREFIX + messages, exception: exceptions)
        }
    }
    
    internal func _fatal(_ message: String, exceptions: C8oException? = nil) -> Void {
        _log(C8oLogLevel.fatal, messages: message, exceptions: exceptions)
    }
    
    internal func _error(_ message: String, exceptions: C8oException? = nil) -> Void {
        _log(C8oLogLevel.error, messages: message, exceptions: exceptions)
    }
    
    internal func _warn(_ message: String, exceptions: C8oException? = nil) -> Void {
        _log(C8oLogLevel.warn, messages: message, exceptions: exceptions)
    }
    
    internal func _info(_ message: String, exceptions: C8oException? = nil) -> Void {
        _log(C8oLogLevel.info, messages: message, exceptions: exceptions)
    }
    
    internal func _debug(_ message: String, exceptions: C8oException? = nil) -> Void {
        _log(C8oLogLevel.debug, messages: message, exceptions: exceptions)
    }
    
    internal func _trace(_ message: String, exceptions: C8oException? = nil) -> Void {
        _log(C8oLogLevel.trace, messages: message, exceptions: exceptions)
    }
    
    internal func logRemote() -> Void {
        var canLog: Bool = false
        let condition: NSCondition = NSCondition()
        
        condition.lock()
        
        // If there is no another thread already logging AND there is at least one log
        canLog = !alreadyRemoteLogging![0] && remoteLogs!.count > 0
        if (canLog) {
            alreadyRemoteLogging![0] = true
        }
        
        condition.unlock()
        
        if (canLog) {
            let priority = DispatchQoS.QoSClass.default
            DispatchQueue.global(qos: priority).async {
                
                // Take logs in the queue and add it to a json array
                var count: Int = 0
                let listSize: Int = self.remoteLogs!.count
                var logsArray = Array<JSON>()
                
                while (count < listSize && count < C8oLogger.REMOTE_LOG_LIMIT) {
                    let log = self.remoteLogs!.dequeue()
                    if (log != nil) {
                        logsArray.append(log!)
                    }
                    count = count + 1
                }
                
                // Initializes request paramters
                var uidS: String = "{\"uid\":\""
                uidS += self.uidRemoteLogs!
                uidS += "\"}"
                var parameters = Dictionary<String, NSObject>()
                parameters =
                    [C8oLogger.JSON_KEY_LOGS: String(describing: logsArray) as NSObject,
                     C8oLogger.JSON_KEY_ENV: self.env as NSObject,
                     C8o.ENGINE_PARAMETER_DEVICE_UUID: self.c8o.deviceUUID as NSObject]
                
                var jsonResponse: JSON
                do {
                    let webResponse: (data: Data?, error: NSError?) = self.c8o.httpInterface!.handleRequest(self.remoteLogUrl!, parameters: parameters)
                    if (webResponse.error != nil) {
                        self.c8o.logRemote = false
                        if (self.c8o.logOnFail != nil) {
                            self.c8o.logOnFail!(C8oException(message: C8oExceptionMessage.RemoteLogFail(), exception: webResponse.error!), nil)
                        }
                        return
                    } else {
                        do{
                            jsonResponse = try C8oTranslator.dataToJson(webResponse.data! as NSData)!
                        }
                        catch {
                            jsonResponse = "Can't translate data into JSON"
                        }
                    }
                }
                var logLevelResponse = jsonResponse[C8oLogger.JSON_KEY_REMOTE_LOG_LEVEL]
                
                if (logLevelResponse != JSON.null) {
                    let logLevelResponseStr: String = logLevelResponse.stringValue
                    let c8oLogLevel = C8oLogLevel.getC8oLogLevel(logLevelResponseStr)
                    
                    if (c8oLogLevel != nil) {
                        self.remoteLogLevel = c8oLogLevel!
                    }
                    condition.lock()
                    self.alreadyRemoteLogging![0] = false
                    condition.unlock()
                    self.logRemote()
                }
            }
        }
    }
    /** Others log */
    
    internal func logMethodCall(_ methodName: String, parameters: NSObject...) -> Void {
        if (c8o.logC8o && isDebug) {
            var methodCallLogMessage: String = "Method call : " + methodName
            if (isTrace && parameters.count > 0) {
                methodCallLogMessage += "\n" + String(describing: parameters)
                _trace(methodCallLogMessage, exceptions: nil)
                
            } else {
                _debug(methodCallLogMessage, exceptions: nil)
            }
        }
    }
    
    internal func logC8oCall(_ url: String, parameters: Dictionary<String, NSObject>) -> Void {
        if (c8o.logC8o && isDebug) {
            var c8oCallLogMessage: String = "C8o call : " + url
            
            if (parameters.count > 0) {
                c8oCallLogMessage += "\n" + String(describing: parameters)
            }
            
            _debug(c8oCallLogMessage, exceptions: nil)
        }
    }
    
    internal func logC8oCallXMLResponse(_ response: AEXMLDocument, url: String?, parameters: Dictionary<String, Any>) -> Void {
        logC8oCallResponse(C8oTranslator.xmlToString(response)!, responseType: "XML", url: url, parameters: parameters)
    }
    
    internal func logC8oCallJSONResponse(_ response: JSON, url: String?, parameters: Dictionary<String, Any>) -> Void {
        logC8oCallResponse(C8oTranslator.jsonToString(response)!, responseType: "JSON", url: url, parameters: parameters)
    }
    
    internal func logC8oCallResponse(_ responseStr: String, responseType: String, url: String?, parameters: Dictionary<String, Any>) -> Void {
        if (c8o.logC8o && isTrace) {
            var c8oCallResponseLogMessage: String
            if (url == nil) {
                c8oCallResponseLogMessage = "C8o call " + responseType + " response : "
            } else {
                c8oCallResponseLogMessage = "C8o call " + responseType + " response : " + url!
            }
            
            if (parameters.count > 0) {
                c8oCallResponseLogMessage += "\n" + parameters.description
            }
            
            c8oCallResponseLogMessage += "\n" + responseStr
            
            _trace(c8oCallResponseLogMessage, exceptions: nil)
        }
    }
}

@objc public enum C8oLogLevel : UInt {
    case null, none, trace, debug, info, warn, error, fatal
    
    internal static func getC8oLogLevel(_ name: String) -> C8oLogLevel? {
        switch name.uppercased() {
        case "NULL":
            return .null
        case "NONE":
            return .none
        case "TRACE":
            return .trace
        case "DEBUG":
            return .debug
        case "INFO":
            return .info
        case "WARN":
            return .warn
        case "ERROR":
            return .error
        case "FATAL":
            return .fatal
        default:
            return nil
        }
    }
    internal func getC8oLogLevelDescription(_ number: Int) -> String {
        switch number {
        case 0:
            return "NULL"
        case 1:
            return "NONE"
        case 2:
            return "TRACE"
        case 3:
            return "DEBUG"
        case 4:
            return "INFO"
        case 5:
            return "WARN"
        case 6:
            return "ERROR"
        case 7:
            return "FATAL"
        default:
            return "DEBUG"
        }
    }
    public func name()->String{
        return self.getC8oLogLevelDescription(Int(self.rawValue))
    }
}
