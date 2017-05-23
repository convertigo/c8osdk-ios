//
//  C8oHttpInterface.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 19/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire

internal class C8oHttpInterface {
	internal var c8o: C8o
	var cookieContainer: C8oCookieStorage
	var alamofire: SessionManager
	fileprivate var timeout: Int
	fileprivate var firstCall = true
	fileprivate var firstCallMutex = NSCondition()
	
	internal init(c8o: C8o) {
		self.c8o = c8o
		
		timeout = c8o.timeout
		let cfg = URLSessionConfiguration.default
		cookieContainer = C8oCookieStorage()
		cfg.httpCookieStorage = cookieContainer
        
        if (c8o.trustAllCertificates) {
            let secu = ServerTrustPolicyManager(policies: [c8o.endpointHost: .disableEvaluation])
            alamofire = Alamofire.SessionManager(configuration: cfg, serverTrustPolicyManager: secu)
        } else {
            alamofire = Alamofire.SessionManager(configuration: cfg)
        }
        
		if (c8o.cookies != nil) {
			for a in c8o.cookies! {
				addCookie(a.0, value: a.1)
			}
		}
	}
	
	internal func onRequestCreate(_ request: NSObject) -> Void {
		
	}
	
	internal func handleRequest(_ url: String, parameters: Dictionary<String, Any>) -> (Data?, NSError?) {
		var myResponse: (Data?, NSError?)
		let data: Data? = setRequestEntity(url as NSObject, parameters: parameters)
		let headers = [
			"x-convertigo-sdk": C8o.getSdkVersion(),
			"User-Agent": "Convertigo Client SDK " + C8o.getSdkVersion()
		]
		let semaphore = DispatchSemaphore(value: 0)
		let queue = DispatchQueue(label: "com.convertigo.c8o.queues", attributes: DispatchQueue.Attributes.concurrent)
		
		firstCallMutex.lock()
		if (firstCall) {
			//let request = alamofire.upload(.POST, url, headers: headers, data: data!)
            let request = alamofire.upload(data!, to: url, method: .post, headers: headers)
                .response(queue:queue,
                          completionHandler:{ response in
                          myResponse = (response.data, response.error as! NSError?)
                          semaphore.signal()
            })
            
            
			semaphore.wait(timeout: DispatchTime.distantFuture)
			firstCall = false
			firstCallMutex.unlock()
			return myResponse
		}
		firstCallMutex.unlock()
		
        let request = alamofire.upload(data!, to: url, method: .post, headers: headers)
            .response(queue:queue,
                      completionHandler:{ response in
                        myResponse = (response.data, response.error! as NSError)
                        semaphore.signal()
            })

		semaphore.wait(timeout: DispatchTime.distantFuture)
		return myResponse
		
	}
	
	internal func handleC8oCallRequest(_ url: String, parameters: Dictionary<String, NSObject>) -> (Data?, NSError?) {
		c8o.c8oLogger!.logC8oCall(url, parameters: parameters)
		return handleRequest(url, parameters: parameters)
	}
	
	/** <summary>
	 Add a cookie to the cookie store.<br/>
	 Automatically set the domain and secure flag using the c8o endpoint.
	 </summary>
	 <param name="name">The name.</param>
	 <param name="value">The value.</param> */
	
	internal func addCookie(_ name: String, value: String) -> NSObject? {
		// cookieContainer.Add(Uri(c8o.Endpoint), Cookie(name, value));
		return nil
	}
	
	internal var cookieStore: C8oCookieStorage?/*CookieContainer*/	{
		get { return cookieContainer }
	}
	
	fileprivate func setRequestEntity(_ request: NSObject?, parameters: Dictionary<String, Any>?) -> Data? {
		
		// request.ContentType = "application/x-www-form-urlencoded";
		// And adds to it parameters
		
		if (parameters != nil && parameters!.count > 0) {
			var postData: String = ""
			
			for parameter in parameters! {
				if let downcastStrings = parameter.1 as? [String] {
					for item in downcastStrings {
                        postData += String(parameter.0).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                            + "=" + String(item).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "&"
					}
				} else {
					postData += String(parameter.0).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                        + "=" + String(describing: parameter.1).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "&"
				}
				
			}
			postData = String(postData.characters.dropLast(1))
			
			return postData.data(using: String.Encoding.utf8)
			
		}
		return nil
	}
}
