//
//  FullSyncRequestable.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 19/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

import CouchbaseLite

internal class C8oFullSyncHttp : C8oFullSync
{
    
    private static var  RE_CONTENT_TYPE : NSRegularExpression = try! NSRegularExpression(pattern: "(.*?)\\s*;\\s*charset=(.*?)\\s*", options: [])
    private static var RE_FS_USE : NSRegularExpression = try! NSRegularExpression(pattern: "^(?:_use_(.*)$|__)" , options: [])
    
    private var databases : Dictionary<String, Bool> = Dictionary<String, Bool>();
    private var serverUrl : String;
    private var authBasicHeader : String;
    
    public init(serverUrl : String, username : String? = nil, password : String? = nil)
    {
        self.serverUrl = serverUrl;
        
        if (username != nil && !String.IsNullOrWhiteSpace(username) && password != nil && !String.IsNullOrWhiteSpace(password))
        {
            let str : String = username! + ":" + password!;
            let utf8str = str.dataUsingEncoding(NSUTF8StringEncoding)
            let base64Encoded = utf8str!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            authBasicHeader = "Basic " + base64Encoded
        }
    }
    
    internal override init(c8o :C8o)
    {
        super.init(c8o: c8o);
    }
    
    private func CheckDatabase(db : String)->Task
    {
        if (!databases.ContainsKey(db))
        {
            HandleCreateDatabaseRequest(db);
            databases[db] = true;
        }
    }
    
    public override func HandleFullSyncResponse(response : NSObject, listener : C8oResponseListener)->NSObject
    {
        return super.HandleFullSyncResponse(response, listener: listener);
    }
    
    public override func HandleGetDocumentRequest(string fullSyncDatatbaseName, string docid, parameters : Dictionary<String, NSObject> = nil)->Task<object>
    {
        CheckDatabase(fullSyncDatatbaseName);
        var uri : String = HandleQuery(GetDocumentUrl(fullSyncDatatbaseName, docid), parameters);
        
        var request = HttpWebRequest.CreateHttp(uri);
        request.Method = "GET";
        
        var document = Execute(request);
        var attachmentsProperty = document[FULL_SYNC__ATTACHMENTS] as JObject;
        
        if (attachmentsProperty != nil)
        {
            for iAttachment in attachmentsProperty
            {
                var attachment = iAttachment.Value as JSON
                attachment["content_url"] = GetDocumentAttachmentUrl(fullSyncDatatbaseName, docid, iAttachment.Key);
            }
        }
        
        return document;
    }
    
    public func HandleGetDocumentAttachment(fullSyncDatatbaseName : String, docidParameterValue : String, attachmentName : String)->Task<object>
    {
        CheckDatabase(fullSyncDatatbaseName);
        var uri : String = GetDocumentUrl(fullSyncDatatbaseName, docidParameterValue) + "/" + attachmentName;
        
        var request : HttpWebRequest = HttpWebRequest.CreateHttp(uri);
        request.Method = "GET";
        request.Accept = "application/octet-stream";
        
        return Execute(request);
    }
    
    public override func HandleDeleteDocumentRequest(fullSyncDatatbaseName : String, docid : String, parameters : Dictionary<String, NSObject>)->Task<object>
    {
        CheckDatabase(fullSyncDatatbaseName);
        var parameters = HandleRev(fullSyncDatatbaseName, docid, parameters);
        
        var uri : String = HandleQuery(GetDocumentUrl(fullSyncDatatbaseName, docid), parameters);
        
        var request :HttpWebRequest = HttpWebRequest.CreateHttp(uri);
        request.Method = "DELETE";
        
        return Execute(request);
    }
    
    public override func HandlePostDocumentRequest(fullSyncDatatbaseName : String, fullSyncPolicy : FullSyncPolicy, parameters : Dictionary<String, NSObject>)->Task<object>
    {
        CheckDatabase(fullSyncDatatbaseName);
        var options : Dictionary<String, NSObject>= Dictionary<String, NSObject>();
        
        for parameter in parameters
        {
            var isUse = RE_FS_USE.Match(parameter.Key);
            if (isUse.Success)
            {
                if (isUse.Groups[1].Success)
                {
                    options[isUse.Groups[1].Value] = parameter.Value;
                }
                parameters.Remove(parameter.Key);
            }
        }
        
        var uri : String = HandleQuery(GetDatabaseUrl(fullSyncDatatbaseName), options);
        
        var request = HttpWebRequest.CreateHttp(uri);
        request.Method = "POST";
        
        // Gets the subkey separator parameter
        var subkeySeparatorParameterValue : String = C8oUtils.PeekParameterStringValue(parameters, FullSyncPostDocumentParameter.SUBKEY_SEPARATOR.name, false);
        
        if (subkeySeparatorParameterValue == nil)
        {
            subkeySeparatorParameterValue = ".";
        }
        
        var postData : JSON = JSON();
        
        for kvp in parameters
        {
            var obj = postData;
            var key : String = kvp.Key;
            var paths : [String] = key.Split(subkeySeparatorParameterValue.ToCharArray());
            
            if (paths.Length > 1)
            {
                
                for (var i = 0; i < paths.Length - 1; i++)
                {
                    var path : String = paths[i];
                    if (obj[path] is JSON)
                    {
                        obj = obj[path] as JObject;
                    } else
                    {
                        obj = (obj[path] = JSON()) as JObject;
                    }
                }
                
                key = paths[paths.Length - 1];
            }
            obj[key] = JToken.FromObject(kvp.Value);
        }
        
        postData = ApplyPolicy(fullSyncDatatbaseName, postData, fullSyncPolicy);
        
        return Execute(request, postData);
    }
    
    public override func HandleAllDocumentsRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject> )->Task<object>
    {
        CheckDatabase(fullSyncDatatbaseName);
        var uri : String = HandleQuery(GetDocumentUrl(fullSyncDatatbaseName, "_all_docs"), parameters);
        
        var request : HttpWebRequest  = HttpWebRequest.CreateHttp(uri);
        request.Method = "GET";
        
        return Execute(request);
    }
    
    public override func HandleGetViewRequest(fullSyncDatatbaseName :String , ddoc :String , view : String,  parameters : Dictionary<String, NSObject>)->Task<object>
    {
        CheckDatabase(fullSyncDatatbaseName);
        var uri : String = HandleQuery(GetDocumentUrl(fullSyncDatatbaseName, "_design/" + ddoc) + "/_view/" + view, parameters);
        
        var request : HttpWebRequest = HttpWebRequest.CreateHttp(uri);
        request.Method = "GET";
        
        return Execute(request);
    }
    
    public override func HandleSyncRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->Task<object>
    {
    CheckDatabase(fullSyncDatatbaseName);
    Task.Run(async () =>
    {
    await HandleReplicatePushRequest(fullSyncDatatbaseName, parameters, c8oResponseListener);
    }).GetAwaiter();
    return HandleReplicatePullRequest(fullSyncDatatbaseName, parameters, c8oResponseListener);
    }
    
    public override func HandleReplicatePullRequest(fullSyncDatatbaseName :String, parameters : Dictionary<String, NSObject> , c8oResponseListener : C8oResponseListener)->Task<object>
    {
    CheckDatabase(fullSyncDatatbaseName);
    return postReplicate(fullSyncDatatbaseName, parameters, c8oResponseListener, true);
    }
    
    public override func HandleReplicatePushRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->Task<object>
    {
    CheckDatabase(fullSyncDatatbaseName);
    return postReplicate(fullSyncDatatbaseName, parameters, c8oResponseListener, false);
    }
    
    private func postReplicate(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener, isPull : Bool)->Task<object>
    {
        var createTarget : Bool = true;
        var continuous : Bool = false;
        var cancel : Bool = false;
    
    if (parameters.ContainsKey("create_target"))
    {
        createTarget = parameters["create_target"].ToString().Equals("true", StringComparison.OrdinalIgnoreCase);
    }
    
    if (parameters.ContainsKey("continuous"))
    {
    continuous = parameters["continuous"].ToString().Equals("true", StringComparison.OrdinalIgnoreCase);
    }
    
    if (parameters.ContainsKey("cancel"))
    {
    cancel = parameters["cancel"].ToString().Equals("true", StringComparison.OrdinalIgnoreCase);
    }
    
        local :JSON = fullSyncDatatbaseName + localSuffix;
        var remote: JSON = JSON();
    
    remote["url"] = fullSyncDatabaseUrlBase + fullSyncDatatbaseName + "/";
    
    var cookies = c8o.CookieStore;
    
    if (cookies.count > 0)
    {
    var headers = JSON();
    var cookieHeader = new StringBuilder();
    
    for cookie in cookies.GetCookies(Uri(c8o.Endpoint))
    {
    cookieHeader.Append(cookie.Name).Append("=").Append(cookie.Value).Append("; ");
    }
    
    cookieHeader.Remove(cookieHeader.Length - 2, 2);
    
    headers["Cookie"] = cookieHeader.ToString();
    remote["headers"] = headers;
    }
    
    var request = HttpWebRequest.CreateHttp(serverUrl + "/_replicate");
    request.Method = "POST";
    
    var json = JSON();
    
        var sourceId : String = (isPull ? remote["url"] : local).ToString();
        var targetId : string = (isPull ? local : remote["url"]).ToString();
    
    json["source"] = isPull ? remote : local;
    json["target"] = isPull ? local : remote;
    json["create_target"] = createTarget;
    json["continuous"] = false;
    json["cancel"] = true;
    
    var response = Execute(request, json);
    c8o.Log._Warn("CANCEL REPLICATE:\n" + response.ToString());
    
    if (cancel)
    {
    return response;
    }
    
    json["cancel"] = false;
    
    request = HttpWebRequest.CreateHttp(serverUrl + "/_replicate");
    request.Method = "POST";
    
    response = null;
    
    var param = Dictionary<string, object>(parameters);
    var progress = C8oProgress();
    progress.Pull = isPull;
    progress.Status = "Active";
    progress.Finished = false;
    
    
    Task.Run(async () =>
    {
        var checkPoint_Interval : Int = 1000;
    
    while (response == nil)
    {
    Task.Delay(TimeSpan.FromMilliseconds(checkPoint_Interval));
    
    if (response != nil)
    {
    break;
    }
    
    var req = HttpWebRequest.CreateHttp(serverUrl + "/_active_tasks");
    req.Method = "GET";
    
    var res = Execute(req);
    
    if (response != nil)
    {
    break;
    }
    
    c8o.Log._Warn(res.ToString());
    
        var task : JSON? = nil;
    for item in res["item"]
    {
    if (String(item["target"]) == targetId && String(item["source"]()) == sourceId)
    {
    task = item as JObject;
    break;
    }
    }
    
    if (task != null)
    {
    checkPoint_Interval = task["checkpoint_interval"].ToObject(typeof(long)) as Int;
    
    progress.Raw = task;
    progress.Total = task["source_seq"].Value<long>();
    progress.Current = task["revisions_checked"].Value<long>();
    progress.TaskInfo = task.ToString();
    
    c8o.Log._Warn(progress.ToString());
    
    if (progress.Changed)
    {
    var newProgress = progress;
    progress = C8oProgress(progress);
    
    if (c8oResponseListener != null && c8oResponseListener is C8oResponseProgressListener)
    {
    param[C8o.ENGINE_PARAMETER_PROGRESS] = newProgress;
    (c8oResponseListener as C8oResponseProgressListener).OnProgressResponse(progress, param);
    }
    }
    }
    }
    }).GetAwaiter();
    
    response = Execute(request, json);
    response.Remove("_c8oMeta");
    
    progress.Total = response["source_last_seq"].Value<long>();
    progress.Current = response["source_last_seq"].Value<long>();
    progress.TaskInfo = response.ToString();
    progress.Status = "Stopped";
    progress.Finished = true;
    
    if (c8oResponseListener != null && c8oResponseListener is C8oResponseProgressListener)
    {
    (c8oResponseListener as C8oResponseProgressListener).OnProgressResponse(progress, param);
    }
    
    if (continuous)
    {
    progress.Status = "Idle";
    json["continuous"] = true;
    
    request = HttpWebRequest.CreateHttp(serverUrl + "/_replicate");
    request.Method = "POST";
    
    response = Execute(request, json);
    c8o.Log._Warn(response.ToString());
    
    /*
    string localId = response["_local_id"].ToString();
    localId = localId.Substring(0, localId.IndexOf('+'));
    
    do {
    request = HttpWebRequest.CreateHttp(GetDatabaseUrl(fullSyncDatatbaseName) + "/_local/" + localId);
    c8o.Log(C8oLogLevel.WARN, request.RequestUri.ToString());
    request.Method = "GET";
    
    response = await Execute(request);
    c8o.Log(C8oLogLevel.WARN, response.ToString());
    } while(response["hystory"] != null);
    */
    }
    
    return VoidResponse.GetInstance();
    }
    
    public override func HandleResetDatabaseRequest(string fullSyncDatatbaseName)->Task<object>
    {
       var uri : String = GetDatabaseUrl(fullSyncDatatbaseName);
    
    var request = HttpWebRequest.CreateHttp(uri);
    request.Method = "DELETE";
    
    databases.Remove(fullSyncDatatbaseName);
    Execute(request);
    
    request = HttpWebRequest.CreateHttp(uri);
    request.Method = "PUT";
    
    var ret = Execute(request);
    databases[fullSyncDatatbaseName] = true;
    return ret;
    }
    
    public override func HandleCreateDatabaseRequest(fullSyncDatatbaseName)->Task<object>
    {
    string uri = GetDatabaseUrl(fullSyncDatatbaseName);
    
    var request = HttpWebRequest.CreateHttp(uri);
    request.Method = "PUT";
    
    var ret = await Execute(request);
    databases[fullSyncDatatbaseName] = true;
    return ret;
    }
    
    public async override Task<object> HandleDestroyDatabaseRequest(string fullSyncDatatbaseName)
    {
    string uri = GetDatabaseUrl(fullSyncDatatbaseName);
    
    HttpWebRequest request = HttpWebRequest.CreateHttp(uri);
    request.Method = "DELETE";
    
    databases.Remove(fullSyncDatatbaseName);
    return await Execute(request);
    }
    
    public override Task<C8oLocalCacheResponse> GetResponseFromLocalCache(string c8oCallRequestIdentifier)
    {
    return null;
    }
    
    //public override Object GetResponseFromLocalCache(string c8oCallRequestIdentifier)
    //{
    //    Dictionary<string, object> localCacheDocument = HandleGetDocumentRequest(C8o.LOCAL_CACHE_DATABASE_NAME, c8oCallRequestIdentifier) as Dictionary<string, object>;
    
    //    if (localCacheDocument == null)
    //    {
    //        throw new C8oUnavailableLocalCacheException(C8oExceptionMessage.ToDo());
    //    }
    
    
    //    string responsestring = "" + localCacheDocument[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE];
    //    string responseTypestring = "" + localCacheDocument[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE];
    //    Object expirationDate = localCacheDocument[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE];
    
    //    long expirationDateLong;
    
    //    if (expirationDate != null)
    //    {
    //        if (expirationDate is long)
    //        {
    //            expirationDateLong = (long) expirationDate;
    //            double currentTime = C8oUtils.GetUnixEpochTime(DateTime.Now);
    //            if (expirationDateLong < currentTime)
    //            {
    //                throw new C8oUnavailableLocalCacheException(C8oExceptionMessage.timeToLiveExpired());
    //            }
    //        }
    //        else
    //        {
    //            throw new C8oUnavailableLocalCacheException(C8oExceptionMessage.invalidLocalCacheResponseInformation());
    //        }
    //    }
    
    //    if (responseTypeString.Equals(C8o.RESPONSE_TYPE_JSON))
    //    {
    //        return C8oTranslator.StringToJson(responseString);
    //    }
    //    else if (responseTypeString.Equals(C8o.RESPONSE_TYPE_XML))
    //    {
    //        return C8oTranslator.StringToXml(responseString);
    //    }
    //    else
    //    {
    //        throw new C8oException(C8oExceptionMessage.ToDo());
    //    }
    //}
    
    public override /*async*/ Task SaveResponseToLocalCache(string c8oCallRequestIdentifier, C8oLocalCacheResponse localCacheResponse)
    {
    return null;
    }
    
    //public override void SaveResponseToLocalCache(string c8oCallRequestIdentifier, string responseString, string responseType, int localCacheTimeToLive)
    //{
    //    Dictionary<string, object> properties = new Dictionary<string, object>();
    //    properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE] = responseString;
    //    properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE] = responseType;
    
    //    if (localCacheTimeToLive != null)
    //    {
    //        long expirationDate = (long) C8oUtils.GetUnixEpochTime(DateTime.Now) + localCacheTimeToLive;
    //        properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE] = expirationDate;
    //    }
    
    //    handlePostDocumentRequest(C8o.LOCAL_CACHE_DATABASE_NAME, FullSyncPolicy.OVERRIDE, properties);
    //}
    
    private async Task<IDictionary<string, object>> HandleRev(string fullSyncDatatbaseName, string docid, IDictionary<string, object> parameters)
    {
    var parameter = C8oUtils.GetParameter(parameters, FullSyncDeleteDocumentParameter.REV.name, false);
    if (parameter.Key == null)
    {
    string rev = await GetDocumentRev(fullSyncDatatbaseName, docid);
    if (rev != null)
    {
    parameters[FullSyncDeleteDocumentParameter.REV.name] = rev;
    }
    }
    return parameters;
    }
    
    private async Task<string> GetDocumentRev(string fullSyncDatatbaseName, string docid)
    {
    var head = await HeadDocument(fullSyncDatatbaseName, docid);
    string rev = null;
    try
    {
    var _c8oMeta = head["_c8oMeta"] as JObject;
    if ("success" == _c8oMeta["status"].ToString())
    {
    rev = (_c8oMeta["headers"] as JObject)["ETag"].ToString();
    rev = rev.Substring(1, rev.Length - 2);
    }
    }
    catch (Exception e)
    {
    c8o.Log._Debug("Cannot find revision of docid=" + docid, e);
    }
    
    return rev;
    }
    
    private async Task<JObject> HeadDocument(string fullSyncDatatbaseName, string docid)
    {
    string uri = GetDocumentUrl(fullSyncDatatbaseName, docid);
    
    var request = HttpWebRequest.CreateHttp(uri);
    request.Method = "HEAD";
    
    return await Execute(request);
    }
    
    private string GetDatabaseUrl(string db)
    {
    if (String.IsNullOrWhiteSpace(db))
    {
    throw new ArgumentException("blank 'db' not allowed");
    }
    
    db = WebUtility.UrlEncode(db);
    
    return serverUrl + '/' + db + localSuffix;
    }
    
    private string GetDocumentUrl(string db, string docid)
    {
    if (String.IsNullOrWhiteSpace(docid))
    {
    throw new ArgumentException("blank 'docid' not allowed");
    }
    
    if (!docid.StartsWith("_design/")) {
    docid = WebUtility.UrlEncode(docid);
    }
    
    return GetDatabaseUrl(db) + '/' + docid;
    }
    
    private string GetDocumentAttachmentUrl(string db, string docid, string attName)
    {
    if (String.IsNullOrWhiteSpace(attName))
    {
    throw new ArgumentException("blank 'docid' not allowed");
    }
    
    return GetDocumentUrl(db, docid) + '/' + attName;
    }
    
    private string HandleQuery(string url, IDictionary<string, object> query)
    {
    StringBuilder uri = new StringBuilder(url);
    if (query != null && query.Count > 0)
    {
    uri.Append("?");
    foreach (KeyValuePair<string, object> kvp in query)
    {
    uri.Append(WebUtility.UrlEncode(kvp.Key)).Append("=").Append(WebUtility.UrlEncode(kvp.Value.ToString())).Append("&");
    }
    uri.Remove(uri.Length - 1, 1);
    }
    return uri.ToString();
    }
    private async Task<JObject> ApplyPolicy(string fullSyncDatatbaseName, JObject document, FullSyncPolicy fullSyncPolicy)
    {
    if (fullSyncPolicy == FullSyncPolicy.NONE)
    {
    
    } else if (fullSyncPolicy == FullSyncPolicy.CREATE)
    {
    document.Remove("_id");
    document.Remove("_rev");
    } else
    {
    string docid = document["_id"].ToString();
    
    if (docid != null)
    {
    if (fullSyncPolicy == FullSyncPolicy.OVERRIDE)
    {
    string rev = await GetDocumentRev(fullSyncDatatbaseName, docid);
    
    if (rev != null)
    {
    document["_rev"] = rev;
    }
    } else if (fullSyncPolicy == FullSyncPolicy.MERGE)
    {
    var dbDocument = await HandleGetDocumentRequest(fullSyncDatatbaseName, docid) as JObject;
    
    if (dbDocument["_id"] != null)
    {
    document.Remove("_rev");
    Merge(dbDocument, document);
    document = dbDocument;
    }
    }
    }
    }
    
    document.Remove("_c8oMeta");
    
    return document;
    }
    
    private void Merge(JObject jsonTarget, JObject jsonSource)
    {
    foreach (var kvp in jsonSource)
    {
    try
    {
    var targetValue = jsonTarget[kvp.Key];
    if (targetValue != null)
    {
    if (targetValue is JObject && kvp.Value is JObject)
    {
    Merge(targetValue as JObject, kvp.Value as JObject);
    } else if (targetValue is JArray && kvp.Value is JArray)
    {
    Merge(targetValue as JArray, kvp.Value as JArray);
    } else
    {
    jsonTarget[kvp.Key] = kvp.Value;
    }
    } else
    {
    jsonTarget[kvp.Key] = kvp.Value;
    }
    }
    catch (Exception e)
    {
    c8o.Log._Info("Failed to merge json documents", e);
    }
    }
    }
    
    private void Merge(JArray targetArray, JArray sourceArray)
    {
    int targetSize = targetArray.Count;
    int sourceSize = sourceArray.Count;
    
    for (int i = 0; i < sourceSize; i++)
    {
    try
    {
    JToken targetValue = targetSize > i ? targetArray[i] : null;
    JToken sourceValue = sourceArray[i];
    if (sourceValue != null && targetValue != null)
    {
    if (targetValue is JObject && sourceValue is JObject)
    {
    Merge(targetValue as JObject, sourceValue as JObject);
    }
    if (targetValue is JArray && sourceValue is JArray)
    {
    Merge(targetValue as JArray, sourceValue as JArray);
    } else
    {
    targetArray[i] = sourceValue;
    }
    } else if (sourceValue != null && targetValue == null)
    {
    targetArray.Add(sourceValue);
    }
    }
    catch (Exception e)
    {
    c8o.Log._Info("Failed to merge json arrays", e);
    }
    }
    }
    
    private async Task<JObject> Execute(HttpWebRequest request, JObject document = null)
    {
    if (request.Accept == null)
    {
    request.Accept = "application/json";
    }
    
    if (authBasicHeader != null)
    {
    request.Headers["Authorization"] = authBasicHeader;
    }
    
    if (document != null)
    {
    request.ContentType = "application/json";
    
    using (var postStream = Task<Stream>.Factory.FromAsync(request.BeginGetRequestStream, request.EndGetRequestStream, request).Result)
    {
    
    // postData = "__connector=HTTP_connector&__transaction=transac1&testVariable=TEST 01";
    byte[] byteArray = Encoding.UTF8.GetBytes(document.ToString());
    // Add the post data to the web request
    
    postStream.Write(byteArray, 0, byteArray.Length);
    }
    }
    
    HttpWebResponse response;
    try
    {
    response = await Task<WebResponse>.Factory.FromAsync(request.BeginGetResponse, request.EndGetResponse, request) as HttpWebResponse;
    }
    catch (WebException e)
    {
    response = e.Response as HttpWebResponse;
    if (response == null)
    {
    throw new C8oHttpException(C8oExceptionMessage.RunHttpRequest(), e);
    }
    }
    catch (Exception e)
    {
    if (e.InnerException is WebException)
    {
    response = (e.InnerException as WebException).Response as HttpWebResponse;
    } else
    {
    throw new C8oHttpException(C8oExceptionMessage.RunHttpRequest(), e);
    }
    }
    
    var matchContentType = RE_CONTENT_TYPE.Match(response.ContentType);
    
    string contentType;
    string charset;
    if (matchContentType.Success)
    {
    contentType = matchContentType.Groups[1].Value;
    charset = matchContentType.Groups[2].Value;
    } else
    {
    contentType = response.ContentType;
    charset = "UTF-8";
    }
    
    JObject json;
    
    if (contentType == "application/json" || contentType == "test/plain")
    {
    
    StreamReader streamReader = new StreamReader(response.GetResponseStream(), Encoding.GetEncoding(charset));
    string entityContent = streamReader.ReadToEnd();
    try
    {
    json = JObject.Parse(entityContent);
    }
    catch
    {
    json = new JObject();
    try
    {
    json["item"] = JArray.Parse(entityContent);
    }
    catch
    {
    json["data"] = entityContent;
    }
    }
    } else
    {
    json = new JObject();
    
    if (response.ContentType.StartsWith("text/"))
    {
    StreamReader streamReader = new StreamReader(response.GetResponseStream(), Encoding.GetEncoding(charset));
    string entityContent = streamReader.ReadToEnd();
    json["data"] = entityContent;
    } else
    {
    // TODO base64
    }
    }
    
    if (json == null)
    {
    json = new JObject();
    }
    
    var c8oMeta = new JObject();
    
    int code = (int) response.StatusCode;
    c8oMeta["statusCode"] = code;
    
    string status =
    code < 100 ? "unknown" :
    code < 200 ? "informational" :
    code < 300 ? "success" :
    code < 400 ? "redirection" :
    code < 500 ? "client error" :
    code < 600 ? "server error" : "unknown";
    c8oMeta["status"] = status;
    
    c8oMeta["reasonPhrase"] = response.StatusDescription;
    
    var headers = new JObject();
    
    foreach (string name in response.Headers.AllKeys)
    {
    headers[name] = response.Headers[name];
    }
    
    c8oMeta["headers"] = headers;
    
    json["_c8oMeta"] = c8oMeta;
    
    response.Dispose();
    
    return json;
    }
}