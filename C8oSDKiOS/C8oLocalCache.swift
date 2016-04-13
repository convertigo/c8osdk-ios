//
//  C8oLocalCache.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


@objc public class C8oLocalCache : NSObject
{
    public static var PARAM : String = "__localCache"
    
    
   public class Priority{
    
        var isAvailable: (c8o : C8o)->(Bool)
    
    /*public static var SERVER : Priority = Priority(c8o : C8o->(Bool))
        public static var LOCAL : Priority = Priority(isAviable: (c8o: C8o(), bool: true))
*/
        public init (isAvailable : (c8o : C8o)->(Bool))
        {
            self.isAvailable = isAvailable
        }
        
    }
    
    internal var priority : C8oLocalCache.Priority?
    internal var ttl : Int
    internal var enabled : Bool
    
    public init(priority : Priority? , ttl : Int = -1, enabled : Bool = true)
    {
        if (priority == nil)
        {
            //throw new System.ArgumentException("Local Cache priority cannot be null")
        }
        self.priority = priority
        self.ttl = ttl
        self.enabled = enabled
    }
}


/*public class Priority
{
private init()
{

}
func IsAvailable() ->(C8o -> Bool){}

public static var SERVER : C8oLocalCache.Priority = Priority(c8o : C8o) -> Bool{return true}
/*{
return true
})*/

public static func LOCAL(c8o: C8o)->Bool
{
return true
}

/*
public static var LOCAL : Priority = Priority(c8o =>
{
return true
})*/

/*var IsAvailable: (C8o) ->Bool

private func Priority(isAvailable : (C8o) ->Bool)
{
IsAvailable = isAvailable

}*/
}*/

/*public enum Priority  {

case SERVER, LOCAL

var abc :
func isAviable(c8o : C8o)->Bool
{
switch(self)
{
case .SERVER :
return true
break

case .LOCAL :
return true
break
}
}



}*/
