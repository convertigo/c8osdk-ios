//
//  C8oLocalCacheResponse.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 07/04/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

class C8oLocalCacheResponse {
  
    private var response : String
    private var responseType : String
    private var expirationDate : Int
    
    public init(response : String, responseType : String, expirationDate : Int) {
        self.response = response
        self.responseType = responseType
        self.expirationDate = expirationDate
    }
    
    public func isExpired() -> Bool {
        if(expirationDate <= 0 ){
            return false
        }
        else{
            let currentDate = NSDate().timeIntervalSince1970 * 1000
            return Double(expirationDate) < currentDate
        }
    }
    public func getResponse() -> String {
        return response
    }
    
    public func getResponseType() ->String {
        return responseType
    }
    
    public func getExpirationDate() ->Int {
        return expirationDate
    }
    
    
}