//
//  C8o.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 03/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

import CouchbaseLite

public class C8o {
    
    public init() {
        
    }
    
    public func createDB() {
       
        print("Hello C8o SDK!");
        
        
        
        var options = CBLManagerOptions(readOnly: false, fileProtection:NSDataWritingOptions.AtomicWrite )
        
        do {
            let manager = try CBLManager(directory: CBLManager.defaultDirectory(), options: &options)
            let database = try manager.databaseNamed("testdatabase")
            database.maxRevTreeDepth = 10

            
            let properties = [
                "test" : "data",
                "test2": "data"
            ]
            
            let document = database.createDocument()
            try document.putProperties(properties)
            print(document)
            
        } catch _ {
            print("manager Creation failed")
        }
        
        print("Manager initialized");
    }
    
    public func makeRequest()  {
    
    
        Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
    
                if let JSon = response.result.value {
                    print("JSON: \(JSon)")
                    var data = JSON(JSon)
                }
                
            }
    }
    
    
    
}