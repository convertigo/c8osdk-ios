//
//  C8oFileManager.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


internal class C8oFileManager
{

    public var CreateFile : (String) -> Streamable;
    
    public var OpenFile : (String) -> Streamable;
    
    public init (CreateFile : (String) -> Streamable, OpenFile : (String) -> Streamable)
    {
        self.CreateFile = CreateFile;
        self.OpenFile = OpenFile;
    }
}