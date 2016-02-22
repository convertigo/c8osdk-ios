//
//  C8oProgress.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

/// <summary>
/// This class gives dome information about a running replication
/// </summary>
public class C8oProgress
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
    
    internal init()
    {
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
    
    /// <summary>
    /// A built in replication status indicator.
    /// </summary>
    /// <returns>A String in the form "Direction : current / total (running)"</returns>
    public func Description()->String
    {
        return "" // Direction + ": " + current + "/" + total + " (" + (finished ? (continuous ? "live" : "done") : "running") + ")";
    }
    
    /// <summary>
    /// true if in continuous mode, false otherwise. In continuous mode, replications are done continuously as long as
    /// the network is present. Otherwise replication stops when all the documents have been replicated
    /// </summary>
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
    
    /// <summary>
    /// For a normal repliacation will be true when the replication has finished. For a continuous replication, will be true during phase 1
    /// when all documents are being replicate to a stable state, then false during the continuous replication process. As design documents
    /// are also replicated during a database sync, never use a view before the progress.finished == true to be sure the design document holding
    /// this view is replicated locally.
    /// </summary>
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
    
    /// <summary>
    /// True is the replication is in pull mode (From server to device) false in push mode (Mobile to server)
    /// </summary>
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
    
    /// <summary>
    /// True is the replication is in push mode (From mobile to device) false in pull  mode (Server to mobile)
    /// </summary>
    public var Push : Bool
    {
        get
        {
            return pull!;
        }
    }
    
    /// <summary>
    /// The current number of revisions repliacted. can be used as a progress indicator.
    /// </summary>
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
    
    /// <summary>
    /// The total number of revisions to be repliacted so far.
    /// </summary>
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
    
    /// <summary>
    /// A Direction (Pull or push) information
    /// </summary>
    public var Direction : String
    {
        get
        {
            return (pull != nil) ?
                C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PULL :
                C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PUSH;
        }
    }
    
    /// <summary>
    /// A Status information
    /// </summary>
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
    
    /// <summary>
    /// A task information status from the underlying replication engine.
    /// </summary>
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
    
    /// <summary>
    /// The underlying replication engine replication object.
    /// </summary>
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
