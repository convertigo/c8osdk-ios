//
//  C8oProgress.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


public class C8oProgress : NSObject
{
    private var changed :Bool? = false;
    private var continuous :Bool? = false;
    private var finished :Bool? = false;
    private var pull :Bool? = true;
    private var current : Int? = -1;
    private var total : Int? = -1;
    private var status : String? = "";
    private var taskInfo : String? = "";
    private var raw : NSObject? ;
    
    internal override init()
    {
        super.init()
        self.changed = nil
        self.continuous = nil
        self.finished = nil
        self.pull = nil
        self.current = nil
        self.total = nil
        self.status = nil
        self.taskInfo = nil
        self.raw = nil
    
    }
    
    internal init(progress : C8oProgress)
    {
        super.init()
        continuous = progress.continuous;
        finished = progress.finished;
        pull = progress.pull;
        current = progress.current;
        total = progress.total;
        status = progress.status;
        taskInfo = progress.taskInfo;
        raw = progress.raw;
    }
    
    internal var Changed : Bool
    {
        get
        {
            return changed!;
        }
    
        set(value)
        {
            changed = value;
        }
    }
    
    public func Description()->String
    {
        return "" // Direction + ": " + current + "/" + total + " (" + (finished ? (continuous ? "live" : "done") : "running") + ")";
    }
    
    public var Continuous : Bool
    {
        get
        {
            return continuous!;
        }
    
        set(value)
        {
            if (value != continuous)
            {
                changed = true;
                continuous = value;
            }
        }
    }
    

    public var Finished: Bool
    {
        get
        {
            return finished!;
        }
    
        set(value)
        {
            if (value != finished)
            {
                changed = true;
                finished = value;
            }
        }
    }
    

    public var Pull : Bool
    {
        get
        {
            return pull!;
        }
    
        set(value)
        {
            if (value != pull)
            {
                changed = true;
                pull = value;
            }
        }
    }
    

    public var Push : Bool
    {
        get
        {
            return pull!;
        }
    }
    

    public var Current : Int
    {
        get
        {
            return current!;
        }
    
        set(value)
        {
            if (value != current)
            {
                changed = true;
                current = value;
            }
        }
    }
    

    public var Total : Int
    {
        get
        {
            return total!;
        }
    
        set(value)
        {
            if (value != total)
            {
                changed = true;
                total = value;
            }
        }
    }
    

    public var Direction : String
    {
        get
        {
            return (pull != nil) ?
                C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PULL :
                C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PUSH;
        }
    }
    

    public var Status : String
    {
        get
        {
            return status!;
        }
    
        set (value)
        {
            if (value != status)
            {
                changed = true;
        status = value;
            }
        }
    }
    

    public var TaskInfo : String
    {
        get
        {
            return taskInfo!;
        }
    
        set(value)
        {
            if (value != taskInfo)
            {
                changed = true;
                taskInfo = value;
            }
        }
    }
    

    public var Raw : NSObject
    {
        get
        {
            return raw!;
        }
    
        set(value)
        {
            if (value != raw)
            {
                changed = true;
                raw = value;
            }
        }
    }
}
