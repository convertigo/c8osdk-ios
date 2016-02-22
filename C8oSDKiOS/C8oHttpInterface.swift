//
//  C8oHttpInterface.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 19/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


internal class C8oHttpInterface
{
    internal var  c8o : C8o;
    var cookieContainer : NSObject?//CookieContainer;
    private var timeout : Int;
    
    public init(c8o : C8o)
    {
        self.c8o = c8o;
        
        timeout = c8o.Timeout;
        
        cookieContainer = nil;
        
        if (c8o.Cookies != nil)
        {
            //cookieContainer.Add(Uri(c8o.Endpoint), c8o.Cookies);
        }
    }
    
    internal func OnRequestCreate(request : NSObject/*HttpWebRequest*/)->Void
    {
        
    }
    
    public func HandleRequest(url : String, parameters : Dictionary<String, NSObject>)->NSObject?//Task<HttpWebResponse>
    {
        /*var request = (HttpWebRequest) HttpWebRequest.Create(url);
        OnRequestCreate(request);
        
        request.Method = "POST";
        request.Headers["x-convertigo-sdk"] = C8o.GetSdkVersion();
        request.CookieContainer = cookieContainer;
        
        SetRequestEntity(request, parameters);
        
        var task = Task<WebResponse>.Factory.FromAsync(request.BeginGetResponse, request.EndGetResponse, request);
        if (timeout > -1)
        {
            var taskWithTimeout = await Task.WhenAny(task, Task.Delay(timeout)).ConfigureAwait(false);
            if (taskWithTimeout is Task<WebResponse>)
            {
                return task.Result as HttpWebResponse;
            }
            throw new Exception("Timeout exception");
        }
        else
        {
            return await task as HttpWebResponse;
        }*/
        return nil
    }
    
    public func HandleC8oCallRequest(url : String, parameters : Dictionary<String, NSObject>)->NSObject?//Task<HttpWebResponse>
    {
        c8o.c8oLogger!.LogC8oCall(url, parameters: parameters);
        return HandleRequest(url, parameters: parameters);
    }
    
    /// <summary>
    /// Add a cookie to the cookie store.<br/>
    /// Automatically set the domain and secure flag using the c8o endpoint.
    /// </summary>
    /// <param name="name">The name.</param>
    /// <param name="value">The value.</param>
    
    public func AddCookie(name : String, value : String)->NSObject?//->Void
    {
        //cookieContainer.Add(Uri(c8o.Endpoint), Cookie(name, value));
        return nil
    }
    
    public var CookieStore : NSObject?//CookieContainer
        {
        get { return nil;  }
    }
    
    private func SetRequestEntity(request : NSObject?/*HttpWebRequest*/, parameters: Dictionary<String, NSObject>)->Void
    {
        /*request.ContentType = "application/x-www-form-urlencoded";
        
        // And adds to it parameters
        if (parameters != nil && parameters.count > 0)
        {
            var postData : String = "";
            
            for parameter in parameters
            {
                postData += Uri.EscapeDataString(parameter.Key) + "=" + Uri.EscapeDataString("" + parameter.Value) + "&";
            }
            
            postData = postData.Substring(0, postData.Length - 1);
            
            // postData = "__connector=HTTP_connector&__transaction=transac1&testVariable=TEST 01";
            byte[] byteArray = Encoding.UTF8.GetBytes(postData);
            
            // First get the request stream before send it (don't use async because of a .net bug for the request)
            var task = Task<Stream>.Factory.FromAsync(request.BeginGetRequestStream, request.EndGetRequestStream, request);
            task.Wait();
            
            using (var entity = task.Result)
            {
                // Add the post data to the web request
                entity.Write(byteArray, 0, byteArray.Length);
            }
        }*/
    }
}