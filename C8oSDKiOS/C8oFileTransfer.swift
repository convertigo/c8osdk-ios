//
//  C8oFileTransfer.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON



public class C8oFileTransfer
{
    static internal var fileManager : C8oFileManager{
        get{
            return self.fileManager
        }
        set(value){
            self.fileManager = value
        }
    }
    
    private var tasksDbCreated : Bool = false
    private var alive : Bool = true
    
    private var c8oTask : C8o
    private var tasks : Dictionary<String, C8oFileTransferStatus>? = nil
    public var raiseTransferStatus : (C8oFileTransfer, C8oFileTransferStatus)? = nil
    public var raiseDebug : (C8oFileTransfer, String)? = nil
    public var raiseException : (C8oFileTransfer, NSError)? = nil
    
    public convenience init(c8o : C8o)throws{
        try self.init(c8o: c8o, projectName: "lib_FileTransfer")
    }
    
    public convenience init(c8o : C8o, projectName : String)throws{
        try self.init(c8o: c8o, projectName: projectName, taskDb: "c8ofiletransfer_tasks")
    }
    
    public init(c8o : C8o, projectName : String, taskDb : String)throws{
        let c8oSet = C8oSettings(c8oSettings: c8o)
        c8oSet.setDefaultDatabaseName(taskDb)
        c8oTask = try C8o(endpoint: c8o.endpointConvertigo + "/projects/" + projectName, c8oSettings: c8oSet)
    }
    
    public func raiseTransferStatus(handler:(C8oFileTransfer, C8oFileTransferStatus))->C8oFileTransfer{
        self.raiseTransferStatus = handler
        return self
    }
    
    public func raiseDebug(handler:(C8oFileTransfer, String))->C8oFileTransfer{
        self.raiseDebug = handler
        return self
    }
    
    public func raiseException(handler :(C8oFileTransfer, NSError))->C8oFileTransfer{
        self.raiseException = handler
        return self
    }
    
    public func start()-> Void
    {
        if(tasks == nil){
            
            tasks = Dictionary<String, C8oFileTransferStatus>()
            
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT            
        
            dispatch_async(dispatch_get_global_queue(priority, 0)){
                try! self.checkTaskDb()
                var skip : Int = 0
                let condition : NSCondition = NSCondition()
    
                var param : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                            ["limit": "222" as NSObject,
                            "include_docs" : true as NSObject]
                
    
                    while (self.alive)
                    {
                        do
                        {
                            param["skip"] = skip
                            var res : JSON = try self.c8oTask.callJson("fs://.all", parameters: param)!.sync()!
    
                            if(res["rows"].count > 0)
                            {
                                var task : JSON = res["rows"][0]["doc"]
                                if (task == nil)
                                {
                                    task = try self.c8oTask.callJson("fs://.get",
                                    parameters: "docid", res["rows"][0]["id"].stringValue
                                    )!.sync()!
                                }
                                let uuid : String = String(task["_id"])
    
                                if let e = self.tasks!["uuid"]{
                                    skip = skip + 1
                                }
                                else
                                {
                                    let filePath : String = task["filePath"].stringValue
                                    
                                    let transferStatus : C8oFileTransferStatus = C8oFileTransferStatus(uuid: uuid, filepath: filePath)
                                    self.tasks![uuid] = transferStatus
                                    
                                    self.notify(transferStatus)
                                    
                                    self.downloadFile(transferStatus, task: task)
                                    
                                    skip = 0
                                    
                                }
                            }
                            else
                            {
                                condition.lock()
                                
                                        condition.wait()
                                        skip = 0
                                
                                condition.unlock()
                            }
                        }
                        catch _ as NSError
                        {
                            
                        }
                }
            }
        }
    }
    
    private func checkTaskDb()throws{
        if (!tasksDbCreated)
        {
            try c8oTask.callJson("fs://.create")?.sync()
            tasksDbCreated = true
        }
    }
    

    public func downloadFile(uuid : String, filePath : String)throws{
        let condition : NSCondition = NSCondition()
        try checkTaskDb()
        c8oTask.callJson("fs://.post",
                            parameters: "_id", uuid,
                            "filePath", filePath,
                            "replicated", false,
                            "assembled", false,
                            "remoteDeleted", false
                )?.then({ (response, parameters) -> (C8oPromise<JSON>?) in
                    condition.lock()
                    //C8oFileTransfer.self.Notify(C8oFileTransfer)
                    condition.unlock()
                    return nil
                })
    
        
    }
    
    
    public func downloadFile(transferStatus : C8oFileTransferStatus, task : JSON){
        var task2 = task
        var needRemoveSession : Bool = false
        var c8o : C8o? = nil
        do
        {
            c8o = try C8o(endpoint: c8oTask.endpoint, c8oSettings : C8oSettings(c8oSettings: c8oTask).setFullSyncLocalSuffix("_" + transferStatus.uuid))
            var fsConnector : String? = nil
    
            //
            // 0 : Authenticates the user on the Convertigo server in order to replicate wanted documents
            //
            if (!task2["replicated"].boolValue || !task2["remoteDeleted"].boolValue){
                needRemoveSession = true
                var json : JSON = try c8o!.callJson(".SelectUuid", parameters: "uuid", transferStatus.uuid)!.sync()!
    
                self.debug("SelectUuid:\n" + json.stringValue)
    
                if(json["document"]["selected"].stringValue != "true"){
                    if (!task2["replicated"].boolValue)
                    {
                        throw C8oException(message: "uuid not selected")
                    }
                }
                else
                {
                    fsConnector = json["document"]["connector"].stringValue
                    transferStatus.state = C8oFileTransferStatus.stateAuthenticated
                    self.notify(transferStatus)
                }
            }
    
            //
            // 1 : Replicate the document discribing the chunks ids list
            //
    
            if (!task2["replicated"].boolValue && fsConnector != nil)
            {
                var locker : [Bool] = [Bool]()
                locker[0] = false
                try c8o!.callJson("fs://" + fsConnector! + ".create")!.sync()!
                needRemoveSession = true
                let condition : NSCondition = NSCondition()
                
                

                
                c8o!.callJson("fs://" + fsConnector! + ".replicate_pull")?.then({ (response, parameters) -> (C8oPromise<JSON>?) in
                    condition.lock()
                        locker[0] = true
                        condition.signal()
                    condition.unlock()
                    return nil
                })
                
                
                transferStatus.state = C8oFileTransferStatus.stateReplicate
                notify(transferStatus)
    
                let allOptions : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                    [ "startkey" : "\"" + transferStatus.uuid + "_\"",
                     "endkey" : "\"" + transferStatus.uuid + "__\"" ]
                
    
                // Waits the end of the replication if it is not finished
                while (!locker[0])
                {
                    do
                    {
                        condition.lock()
                        
                        condition.wait()
                        
                        condition.unlock()
                    
    
                        var all = try c8o?.callJson("fs://" + fsConnector! + ".all", parameters: allOptions)!.sync()
                        let rows = all!["rows"]
                        if (rows != nil)
                        {
                            let current : Int = rows.count
                            if (current != transferStatus.current)
                            {
                                transferStatus.current = current
                                self.notify(transferStatus)
                            }
                        }
                    }
                    catch let e as NSError
                    {
                        self.debug(e.description)
                    }
                }
    
                if (transferStatus.current < transferStatus.total)
                {
                    throw C8oException(message: "replication not completed")
                }
    
                let res = try c8oTask.callJson("fs://" + fsConnector! + ".post",
                    parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                    "_id", task2["_id"].stringValue,
                    "replicated", true
                    )!.sync()
                
                self.debug("replicated true:\n" + (res?.description)!)
            }
    
            if (!task2["assembled"].boolValue && fsConnector != nil)
            {
                transferStatus.state = C8oFileTransferStatus.stateAssembling
                self.notify(transferStatus)
                //
                // 2 : Gets the document describing the chunks list
                //
                var createdFileStream = C8oFileTransfer.fileManager.createFile(transferStatus.filepath)
                
    
                for i in 0...transferStatus.total{
                    let meta : JSON = try c8o!.callJson("fs://" + fsConnector! + ".get", parameters: "docid", transferStatus.uuid + "_" + i.description)!.sync()!
                    self.debug((meta.description))
    
                    appendChunk(&createdFileStream, contentPath: meta["_attachments"]["chunk"]["content_url"].stringValue)
                }
                createdFileStream.close()
                
                task2["assembled"] = true
                let res = try c8oTask.callJson("fs://.post",
                    parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                    "_id", task2["_id"].stringValue,
                    "assembled", true
                    )!.sync()!
                self.debug("assembled true:\n" + res.description)
            }
    
            if (!task2["remoteDeleted"].boolValue && fsConnector != nil)
            {
                transferStatus.state = C8oFileTransferStatus.stateCleaning
                self.notify(transferStatus)
    
                var res = try c8o!.callJson("fs://" + fsConnector! + ".destroy")!.sync()
                self.debug("destroy local true:\n" + (res?.stringValue)!)
    
                needRemoveSession = true
                res = try c8o!.callJson(".DeleteUuid", parameters: "uuid", transferStatus.uuid)!.sync()!
                self.debug("deleteUuid:\n" + (res?.description)!)
    
                task2["remoteDeleted"] = true
                
                res = try c8oTask.callJson("fs://.post",
                    parameters :
                    C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                    "_id", task2["_id"].stringValue,
                    "remoteDeleted", true
                    )!.sync()!
                self.debug("remoteDeleted true:\n" + (res?.description)!)
            }
    
            if (task2["replicated"].boolValue && task2["assembled"].boolValue && task2["remoteDeleted"].boolValue)
            {
                let res = try c8oTask.callJson("fs://.delete", parameters: "docid", transferStatus.uuid)!.sync()
                self.debug("local delete:\n" + (res?.description)!)
    
                transferStatus.state = C8oFileTransferStatus.stateFinished
                self.notify(transferStatus)
            }
        }
        catch let e as NSError
        {
            self.notify(e)
        }
    
        if (needRemoveSession && c8o != nil)
        {
            c8o!.callJson(".RemoveSession")
        }
    
        tasks?.removeValueForKey(transferStatus.uuid)
        let condition : NSCondition = NSCondition()
        condition.lock()
        condition.signal()
            
        condition.unlock()
    }
    
    private func appendChunk(inout createdFileStream : NSStream, contentPath : String)->Void
    {
        var str = contentPath
        let regex = try! NSRegularExpression(pattern: "^file:", options: .CaseInsensitive)
        str = regex.stringByReplacingMatchesInString(str, options: [], range: NSRange(0..<str.utf16.count), withTemplate: "")
        let chunkStream = NSInputStream(fileAtPath: str)
        createdFileStream = chunkStream!
        chunkStream?.close()
    }
    
    
    private func notify(transferStatus : C8oFileTransferStatus)->Void
    {
        if (raiseTransferStatus != nil)
        {
            raiseTransferStatus(self, transferStatus)
        }
    }
    
    private func notify(exception : NSError)->Void
    {
        if (raiseException != nil)
        {
            raiseException(self, exception)
        }
    }
    
    private func debug(debug : String)->Void
    {
        if (raiseDebug != nil)
        {
            raiseDebug(self, debug)
        }
    }
}
