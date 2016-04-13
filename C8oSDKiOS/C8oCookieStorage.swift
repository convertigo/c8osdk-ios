//
//  C8oCookieStorage.swift
//  C8oSDKiOS
//
//  Created by Nicolas Albert on 17/03/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

@objc public class C8oCookieStorage : NSHTTPCookieStorage {
    var _cookies: [NSHTTPCookie] = []
    
    /*!
    @method cookies
    @abstract Get all the cookies
    @result An NSArray of NSHTTPCookies
    */
    public override var cookies: [NSHTTPCookie]? { get {
        return _cookies
    }}
    
    /*!
    @method setCookie:
    @abstract Set a cookie
    @discussion The cookie will override an existing cookie with the
    same name, domain and path, if any.
    */
    public override func setCookie(cookie: NSHTTPCookie) {
        _cookies.append(cookie)
    }
    
    /*!
    @method deleteCookie:
    @abstract Delete the specified cookie
    */
    public override func deleteCookie(cookie: NSHTTPCookie) {
        
    }
    
    /*!
    @method cookiesForURL:
    @abstract Returns an array of cookies to send to the given URL.
    @param URL The URL for which to get cookies.
    @result an NSArray of NSHTTPCookie objects.
    @discussion The cookie manager examines the cookies it stores and
    includes those which should be sent to the given URL. You can use
    <tt>+[NSCookie requestHeaderFieldsWithCookies:]</tt> to turn this array
    into a set of header fields to add to a request.
    */
    public override func cookiesForURL(URL: NSURL) -> [NSHTTPCookie]? {
        return _cookies
    }
    
    /*!
    @method setCookies:forURL:mainDocumentURL:
    @abstract Adds an array cookies to the cookie store, following the
    cookie accept policy.
    @param cookies The cookies to set.
    @param URL The URL from which the cookies were sent.
    @param mainDocumentURL The main document URL to be used as a base for the "same
    domain as main document" policy.
    @discussion For mainDocumentURL, the caller should pass the URL for
    an appropriate main document, if known. For example, when loading
    a web page, the URL of the main html document for the top-level
    frame should be passed. To save cookies based on a set of response
    headers, you can use <tt>+[NSCookie
    cookiesWithResponseHeaderFields:forURL:]</tt> on a header field
    dictionary and then use this method to store the resulting cookies
    in accordance with policy settings.
    */
    public override func setCookies(cookies: [NSHTTPCookie], forURL URL: NSURL?, mainDocumentURL: NSURL?) {
        _cookies.appendContentsOf(cookies)
    }
    
    /*!
    @method sortedCookiesUsingDescriptors:
    @abstract Returns an array of all cookies in the store, sorted according to the key value and sorting direction of the NSSortDescriptors specified in the parameter.
    @param sortOrder an array of NSSortDescriptors which represent the preferred sort order of the resulting array.
    @discussion proper sorting of cookies may require extensive string conversion, which can be avoided by allowing the system to perform the sorting.  This API is to be preferred over the more generic -[NSHTTPCookieStorage cookies] API, if sorting is going to be performed.
    */
    @available(iOS 5.0, *)
    public override func sortedCookiesUsingDescriptors(sortOrder: [NSSortDescriptor]) -> [NSHTTPCookie] {
        return _cookies
    }
    @available(iOS 8.0, *)
    public override func storeCookies(cookies: [NSHTTPCookie], forTask task: NSURLSessionTask) {
        _cookies.appendContentsOf(cookies)
    }
    @available(iOS 8.0, *)
    public override func getCookiesForTask(task: NSURLSessionTask, completionHandler: ([NSHTTPCookie]?) -> Void) {
        completionHandler(_cookies)
    }
}