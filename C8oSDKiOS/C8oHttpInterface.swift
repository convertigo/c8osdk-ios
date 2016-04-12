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
    internal var  c8o : C8o
    var cookieContainer : C8oCookieStorage
    var alamofire : Manager
    private var timeout : Int
    
    internal init(c8o : C8o)
    {
        self.c8o = c8o
        
        timeout = c8o.timeout
        let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
        cookieContainer = C8oCookieStorage()
        cfg.HTTPCookieStorage = cookieContainer
        alamofire = Alamofire.Manager(configuration: cfg)
        
        // TODO : add cookies in the cookie container
        if (c8o.cookies != nil)
        {
            //cookieContainer.append(Pair<String, Dictionary<String, String>>(key: c8o.Endpoint, value: c8o.Cookies!));
        }
    }
    
    internal func onRequestCreate(request : NSObject)->Void
    {
        
    }
    
    internal func handleRequest(url : String, parameters : Dictionary<String, AnyObject>)->(NSData?, NSError?)
    {
        var myResponse : (NSData?, NSError?)
        let data : NSData? = setRequestEntity(url, parameters: parameters)
        let headers = [
            "x-convertigo-sdk" : C8o.getSdkVersion(),
            "User-Agent" : "Convertigo Client SDK " + C8o.getSdkVersion()
        ]
        let semaphore = dispatch_semaphore_create(0)
        let queue = dispatch_queue_create("com.convertigo.c8o.queue", DISPATCH_QUEUE_CONCURRENT)

        let request = alamofire.upload(.POST, url, headers: headers, data: data!)
        request.response(
            queue: queue,
            completionHandler :{ request, response, data, error in
                myResponse = (data , error)
                dispatch_semaphore_signal(semaphore)
        })
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return myResponse
        
        
    }
    
    internal func handleC8oCallRequest(url : String, parameters : Dictionary<String, NSObject>)->(NSData?, NSError?)
    {
        c8o.c8oLogger!.logC8oCall(url, parameters: parameters);
        return handleRequest(url, parameters: parameters);
    }
    
    /// <summary>
    /// Add a cookie to the cookie store.<br/>
    /// Automatically set the domain and secure flag using the c8o endpoint.
    /// </summary>
    /// <param name="name">The name.</param>
    /// <param name="value">The value.</param>
    
    internal func addCookie(name : String, value : String)->NSObject?//->Void
    {
        //cookieContainer.Add(Uri(c8o.Endpoint), Cookie(name, value));
        return nil
    }
    
    internal var cookieStore : C8oCookieStorage?/*CookieContainer*/{
        get { return cookieContainer  }
    }
    
    private func setRequestEntity(request : NSObject?, parameters: Dictionary<String, AnyObject>?)->NSData?{
        
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