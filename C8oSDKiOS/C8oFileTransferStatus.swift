//
//  C8oFileTransferStatus.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
/*
public class C8oFileTransferStatus
{
    public static var  StateQueued : DownloadState =  DownloadState("queued");
    public static var  StateAuthenticated : DownloadState =  DownloadState("authenticated");
    public static var  StateReplicate : DownloadState =  DownloadState("replicating");
    public static var  StateAssembling : DownloadState =  DownloadState("assembling");
    public static var  StateCleaning : DownloadState =  DownloadState("cleaning");
    public static var  StateFinished : DownloadState =  DownloadState("finished");
    
    public class DownloadState
    {
        var description : String;
        
        internal init (description: String)
        {
            self.description = description;
        }
        
        public func Description()->String
        {
            return self.description;
        }
    }
    
    private var state : DownloadState = StateQueued;
    
    public var State : DownloadState
    {
        get
        {
            return state;
        }
        set(value)
        {
            state = value;
        }
    }
    
    private var uuid : String;
    
    public var Uuid: String
    {
        get
        {
            return uuid;
        }
    }
    
    private var filepath : String;
    
    public var Filepath : String
    {
        get
        {
            return filepath;
        }
    }
    
    public var current : Int;
    
    public var Current : Int
    {
        get
        {
            return current;
        }
    
        set(value)
        {
            current = value;
        }
    }
    
    public var total : Int;
    
    public var Total : Int
    {
        get
        {
            return total;
        }
    }
    
    public var Progress : Double
    {
        get
        {
            return total > 0 ? current * 1.0f / total : 0;
        }
    }
    
    internal init (uuid : String, filepath : String)
    {
        self.uuid = uuid;
        self.filepath = filepath;
        var index =  advance(uuid.endIndex)
        total = Int(uuid.substringWithRange(NSRange() + 1));
    }
}*/
