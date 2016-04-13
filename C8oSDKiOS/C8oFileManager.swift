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

    internal var createFile : (String) -> Streamable;
    
    internal var openFile : (String) -> Streamable;
    
    internal init (createFile : (String) -> Streamable, openFile : (String) -> Streamable)
    {
        self.createFile = createFile;
        self.openFile = openFile;
    }
}