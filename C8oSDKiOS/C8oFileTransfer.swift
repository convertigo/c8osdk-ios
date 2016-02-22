//
//  C8oFileTransfer.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


/// <summary>
/// This class manages big file transfers from and to Convertigo Server. To transfer a file you need to install in the
/// Convertigo server the lib_FileTransfer.car project handling the backend part.
///
/// File transfers are using FullSync technology to transfer files in chunk mode. When a transfer is requested, the server
/// will cut the file in chunks, then will insert the chunks in a FullSync database, the Database will replicate and the file will be reassembled
/// on the client side.
/// </summary>
/*
public class C8oFileTransfer
{
    static internal var fileManager : C8oFileManager;
    
    private var tasksDbCreated : Bool = false;
    private var alive : Bool = true;
    
    private var c8oTask : C8o;
    private var tasks : Dictionary<String, C8oFileTransferStatus>? = nil;
    public event  RaiseTransferStatus : EventHandler<C8oFileTransferStatus>;
    public event RaiseDebug :  EventHandler<string>
    public event RaiseException EventHandler<Exception> ;
    
    /// <summary>
    /// Initialize a File transfer. This will prepare everything needed to transfer a file. The name of the backend project and
    /// the name of the FullSync status database will be set by default to <b>lib_FileTransfer</b> and to <b>c8ofiletransfer_tasks</b> but
    /// you can override them passing custom values the <b>projectname</b> and the <b>taskDb</b> parameters.
    /// </summary>
    /// <param name="c8o">An initilized C8o endpoint object</param>
    /// <param name="projectName">the overrided project name</param>
    /// <param name="taskDb">the overrided status database name</param>
    /// <sample>
    ///     Typical usage :
    ///     <code>
    ///         // Construct the endpoint to Convertigo Server
    ///         c8o = new C8o("http://[server:port]/convertigo/projects/[my__backend_project]");
    ///
    ///         // Buid a C8oFileTransfer object
    ///         fileTransfer = new C8oFileTransfer(c8o);
    ///
    ///         // Attach a TransferStatus monitor
    ///         fileTransfer.RaiseTransferStatus += (sender, transferStatus) => {
    ///             // Do Whatever has to be done to monitor the transfer
    ///         };
    ///
    ///         // Start Transfer engine
    ///         fileTransfer.Start();
    ///
    ///         // DO Some Stuff
    ///         ....
    ///         // Call a custom Sequence in the server responsible for getting the document to be transffered from any
    ///         // Repository and pushing it to FullSync using the lib_FileTransfer.var library.
    ///         JObject data = await c8o.CallJSON(".AddFileXfer").Async();
    ///
    ///         // This sequence should return an uuid identifying the transfer.
    ///         String uuid = ["document"]["uuid"].Value();
    ///
    ///         // Use this uuid to start the transfer and give the target filename and path on your device file system.
    ///         fileTransfer.DownloadFile(uuid, "c:\\temp\\MyTransferredFile.data");
    ///     </code>
    /// </sample>
    public init(c8o : C8o, projectName : String = "lib_FileTransfer", taskDb : String = "c8ofiletransfer_tasks")
    {
        c8oTask = C8o(c8o.EndpointConvertigo + "/projects/" + projectName, C8oSettings(c8o).SetDefaultDatabaseName(taskDb));
    }
    
    public func Start()-> Void
    {
        if (tasks == nil)
        {
            tasks = Dictionary<String, C8oFileTransferStatus>();
            
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            
            
            
            //Task.Factory.StartNew(async () =>
            dispatch_async(dispatch_get_global_queue(priority, 0)){
                CheckTaskDb();
                var skip : Int = 0;
                var condition : NSCondition
    
                var param : Dictionary<String, NSObject> = Dictionary<String, NSObject>()
                            ["limit": "222" as NSObject,
                            "include_docs" : true as NSObject]
                
    
                    while (self.alive)
                    {
                        do
                        {
                            param["skip"] = skip;
                            var res = c8oTask.CallJson("fs://.all", param).Async();
    
                            if ((res["rows"] as JSON).count > 0)
                            {
                                var task = res["rows"][0]["doc"] as JSON?;
                                if (task == nil)
                                {
                                    task = c8oTask.CallJson("fs://.get",
                                    "docid", res["rows"][0]["id"].ToString()
                                    ).Async();
                                }
                                var uuid : String = String(task["_id"]);
    
                                if (!tasks.ContainsKey(uuid))
                                {
                                    var filePath : String = task["filePath"].Value<String>();
    
                                    var transferStatus = tasks[uuid] = C8oFileTransferStatus(uuid, filePath);
                                    Notify(transferStatus);
    
                                    DownloadFile(transferStatus, task).GetAwaiter();
    
                                    skip = 0;
                                }
                                else
                                {
                                    skip = skip + 1 ;
                                }
                            }
                            else
                            {
                                condition.lock()
                                
                                        condition.wait()
                                        skip = 0;
                                
                                condition.unlock()
                            }
                        }
                        catch
                        {
                            //e.ToString();
                        }
                }
            } //, TaskCreationOptions.LongRunning);
        }
    }
    
    private func CheckTaskDb()->Void
    {
        if (!tasksDbCreated)
        {
            c8oTask.CallJson("fs://.create").Async();
            tasksDbCreated = true;
        }
    }
    
    /// <summary>
    /// Add a file to transfer to the download queue. This call must be done after getting a uuid from the Convertigo Server.
    /// the uuid is generated by the server by calling the RequestFile file Sequence.
    /// </summary>
    /// <param name="uuid">a uuid obtained by a call to the 'RequestFile' sequence on the server</param>
    /// <param name="filepath">a path where the file will be assembled when the transfer is finished</param>
    public func DownloadFile(uuid : String, filePath : String)->Void
    {
        var condition : NSCondition
        CheckTaskDb();
    
        c8oTask.CallJson("fs://.post",
                            "_id", uuid,
                            "filePath", filePath,
                            "replicated", false,
                            "assembled", false,
                            "remoteDeleted", false
                        ).Async();
    
            condition.lock()
            {
                Monitor.Pulse(this);
            }
    }
    
    
    public func DownloadFile(transferStatus : C8oFileTransferStatus, task : JSON)->Void
    {
        var needRemoveSession : Bool = false;
        var c8o:C8o? = nil;
        do
        {
            c8o = try! C8o(endpoint: c8oTask.Endpoint);
            /*C8oSettings(c8oTask).SetFullSyncLocalSuffix("_" + transferStatus.Uuid)*/)
            var fsConnector : String = nil;
    
            //
            // 0 : Authenticates the user on the Convertigo server in order to replicate wanted documents
            //
            if (!task["replicated"].Value<Bool>() || !task["remoteDeleted"].Value<Bool>())
            {
                needRemoveSession = true;
                var json = c8o.CallJson(".SelectUuid", "uuid", transferStatus.Uuid).Async();
    
                self.Debug("SelectUuid:\n" + json.ToString());
    
                if (json.SelectToken("document.selected").ToString() != "true")
                {
                    if (!task["replicated"].Value<Bool>())
                    {
                        //throw new Exception("uuid not selected");
                    }
                }
                else
                {
                    fsConnector = json.SelectToken("document.connector").ToString();
                    transferStatus.State = C8oFileTransferStatus.StateAuthenticated;
                    self.Notify(transferStatus);
                }
            }
    
            //
            // 1 : Replicate the document discribing the chunks ids list
            //
    
            if (!task["replicated"].Value<Bool>() && fsConnector != nil)
            {
                var locker : [Bool] = [Bool]()
                locker[0] = false
     
                c8o?.CallJson("fs://" + fsConnector + ".create").Async();
    
                needRemoveSession = true;
                
                var condition : NSCondition
                
                

                
                //c8o.CallJson("fs://" + fsConnector + ".replicate_pull").Then((json, param) =>
                //{
                        condition.lock()
                    
                    
                            locker[0] = true;
                            Monitor.Pulse(locker);
                    
                        condition.unlock()
                    
                    return nil;
                
                    //});
    
                transferStatus.State = C8oFileTransferStatus.StateReplicate;
                Notify(transferStatus);
    
                var allOptions : Dictionary<String, NSObject> = Dictionary<String, NSObject>()
                    [ "startkey" : "\"" + transferStatus.Uuid + "_\"",
                     "endkey" : "\"" + transferStatus.Uuid + "__\"" ]
                
    
                // Waits the end of the replication if it is not finished
                while (!locker[0])
                {
                    do
                    {
                        condition.lock()
                        
                        condition.wait()
                        //Monitor.Wait(locker, 500);
                        
                        condition.unlock()
                    
    
                        var all = c8o?.CallJson("fs://" + fsConnector + ".all", allOptions).Async();
                        var rows = all["rows"];
                        if (rows != nil)
                        {
                            var current : Int = (rows as JArray).Count;
                            if (current != transferStatus.Current)
                            {
                                transferStatus.Current = current;
                                self.Notify(transferStatus);
                            }
                        }
                    }
                    catch
                    {
                        //self.Debug(e.ToString());
                    }
                }
    
                if (transferStatus.Current < transferStatus.Total)
                {
                    //throw new Exception("replication not completed");
                }
    
                var res = c8oTask.CallJson("fs://" + fsConnector + ".post",
                    C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                    "_id", task["_id"].Value<String>(),
                    "replicated", task["replicated"] = true
                    ).Async();
                self.Debug("replicated true:\n" + res);
            }
    
            if (!task["assembled"].Value<Bool>() && fsConnector != nil)
            {
                transferStatus.State = C8oFileTransferStatus.StateAssembling;
                self.Notify(transferStatus);
                //
                // 2 : Gets the document describing the chunks list
                //
                var createdFileStream = fileManager.CreateFile(transferStatus.Filepath);
                createdFileStream.Position = 0;
    
                for var i = 0; i < transferStatus.Total; ++i
                {
                    var meta = c8o.CallJson("fs://" + fsConnector + ".get", "docid", transferStatus.Uuid + "_" + i).Async();
                    Debug(meta.ToString());
    
                    AppendChunk(createdFileStream, meta.SelectToken("_attachments.chunk.content_url").ToString());
                }
                createdFileStream.Dispose();
    
                var res = c8oTask.CallJson("fs://.post",
                    C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                    "_id", task["_id"].Value<String>(),
                    "assembled", task["assembled"] = true
                    ).Async();
                self.Debug("assembled true:\n" + res);
            }
    
            if (!task["remoteDeleted"].Value<Bool>() && fsConnector != nil)
            {
                transferStatus.State = C8oFileTransferStatus.StateCleaning;
                self.Notify(transferStatus);
    
                var res = self.c8o.CallJson("fs://" + fsConnector + ".destroy").Async();
                self.Debug("destroy local true:\n" + res.ToString());
    
                needRemoveSession = true;
                res = c8o.CallJson(".DeleteUuid", "uuid", transferStatus.Uuid).Async();
                self.Debug("deleteUuid:\n" + res);
    
                res = c8oTask.CallJson("fs://.post",
                    C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                    "_id", task["_id"].Value<String>(),
                    "remoteDeleted", task["remoteDeleted"] = true
                    ).Async();
                self.Debug("remoteDeleted true:\n" + res);
            }
    
            if (task["replicated"].Value<Bool>() && task["assembled"].Value<Bool>() && task["remoteDeleted"].Value<Bool>())
            {
                var res = c8oTask.CallJson("fs://.delete", "docid", transferStatus.Uuid).Async();
                self.Debug("local delete:\n" + res.ToString());
    
                transferStatus.State = C8oFileTransferStatus.StateFinished;
                self.Notify(transferStatus);
            }
        }
        catch //(Exception e)
        {
            //self.Notify(e);
        }
    
        if (needRemoveSession && c8o != nil)
        {
            //c8o.CallJson(".RemoveSession");
        }
    
        tasks.Remove(transferStatus.Uuid);
        var condition : NSCondition
        condition.lock()
        
            
        condition.unlock()
    }
    
    private func AppendChunk(createdFileStream : NSStream, contentPath : NSStream)->Void
    {
        var chunkStream : NSStream
        if (contentPath.StartsWith("http://") || contentPath.StartsWith("https://"))
        {
            var request = HttpWebRequest.CreateHttp(contentPath);
            var response = Task<WebResponse>.Factory.FromAsync(request.BeginGetResponse, request.EndGetResponse, request).Result as HttpWebResponse;
            chunkStream = response.GetResponseStream();
        }
    else
    {
        var contentPath2 : String = UrlToPath(contentPath);
        chunkStream = fileManager.OpenFile(contentPath2);
    }
        chunkStream.CopyTo(createdFileStream, 4096);
        chunkStream.Dispose();
        createdFileStream.Position = createdFileStream.Length;
    }
    
    private static func UrlToPath(url : String)->String
    {
    // Lesson learnt - always check for a valid URI
        do
        {
            var uri : NSUri = try! Uri(url);
            url =  try !uri.LocalPath;
        }
        catch
        {
            // not uri format
        }
        // URL decode the string
        url = Uri.UnescapeDataString(url);
        return url;
    }
    
    private func Notify(transferStatus : C8oFileTransferStatus)->Void
    {
        if (RaiseTransferStatus != nil)
        {
            RaiseTransferStatus(this, transferStatus);
        }
    }
    
    private func Notify(exception : NSException)->Void
    {
        if (RaiseException != nil)
        {
            RaiseException(this, exception);
        }
    }
    
    private func Debug(debug : String)->Void
    {
        if (RaiseDebug != nil)
        {
            RaiseDebug(this, debug);
        }
    }
}*/
