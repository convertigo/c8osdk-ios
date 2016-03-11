//
//  C8oHttpInterface.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 19/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire


internal class C8oHttpInterface
{
    internal var  c8o : C8o;
    var cookieContainer : NSObject?//CookieContainer;
    private var timeout : Int;
    
    internal init(c8o : C8o)
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
    
    internal func HandleRequest(url : String, parameters : Dictionary<String, AnyObject>)->NSData?//(NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?)?
    {
        var myResponse : NSData?
        let data : NSData? = SetRequestEntity(url, parameters: parameters)
        let cookieHeaderField = ["Set-Cookie": "x-convertigo-sdk=" + C8o.GetSdkVersion()]
        let semaphore = dispatch_semaphore_create(0)
        let queue = dispatch_queue_create("com.convertigo.co8.queue", DISPATCH_QUEUE_CONCURRENT)
        
        let request = Alamofire.upload(.POST, url, headers: cookieHeaderField, data: data!)//(.POST, mutableUrlRequest)
        request.response (
            queue: queue,
            completionHandler :{ request, response, data, error in
                
                myResponse = data
                dispatch_semaphore_signal(semaphore);
        })
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return myResponse
        
        
    }
    
    internal func HandleC8oCallRequest(url : String, parameters : Dictionary<String, NSObject>)->NSData//(NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?)?//Task<HttpWebResponse>
    {
        c8o.c8oLogger!.LogC8oCall(url, parameters: parameters);
        return HandleRequest(url, parameters: parameters)!;
    }
    
    /// <summary>
    /// Add a cookie to the cookie store.<br/>
    /// Automatically set the domain and secure flag using the c8o endpoint.
    /// </summary>
    /// <param name="name">The name.</param>
    /// <param name="value">The value.</param>
    
    internal func AddCookie(name : String, value : String)->NSObject?//->Void
    {
        //cookieContainer.Add(Uri(c8o.Endpoint), Cookie(name, value));
        return nil
    }
    
    internal var CookieStore : NSObject?/*CookieContainer*/{
        get { return nil;  }
    }
    
    private func SetRequestEntity(request : NSObject?, parameters: Dictionary<String, AnyObject>?)->NSData?{
        
        //request.ContentType = "application/x-www-form-urlencoded";
        
        // And adds to it parameters
        
        if (parameters != nil && parameters!.count > 0)
        {
            var postData : String = "";
            
            for parameter in parameters!
            {
                if let downcastStrings = parameter.1 as? [String] {
                    for item in downcastStrings {
                        postData += String(parameter.0) + "=" + String(item) + "&";
                    }
                }
                else{
                    postData += String(parameter.0) + "=" + String(parameter.1) + "&";
                }
                
            }
            postData = String(postData.characters.dropLast(1))
            
            return postData.dataUsingEncoding(NSUTF8StringEncoding)
            
            
        }
        return nil
    }
}