//
//  VoidResponse.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 07/04/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

class VoidResponse{
    private static let VOID_RESPONSE_INSTANCE : VoidResponse = VoidResponse()
    
    private init(){
        
    }
    
    public static func getInstance()->VoidResponse{
        return VoidResponse.VOID_RESPONSE_INSTANCE
    }
}