//
//  C8oPromise.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


public class C8oPromise<T> : C8oPromiseFailSync<T>
{
    
    private var c8o : C8o;
    
    private var c8oOnResponses : Array<Pair<(T, Dictionary<String, NSObject>)throws ->(C8oPromise<T>?), Bool>> = Array<Pair<(T, Dictionary<String, NSObject>)throws ->(C8oPromise<T>?), Bool>>()
    
    private var c8oProgress : Pair<(C8oProgress)throws ->(),Bool>?
    private var c8oFail : Pair<(NSException, Dictionary<String, NSObject>)throws ->(),Bool>?;
    private var syncMutex : NSCondition = NSCondition();
    
    private var lastResult : T?;
    private var lastException : ErrorType?;
    
    public init(c8o : C8o)
    {
        self.c8o = c8o
        //super.init();
        
    }
    
    
    public func Then(c8oOnResponse : (response : T, parameters : Dictionary<String, NSObject>)->(C8oPromise<T>?))-> C8oPromise<T>?
    {
        let condition : NSCondition = NSCondition()
        condition.lock()
        let keyValue : Pair = Pair<(T, Dictionary<String, NSObject>) throws ->(C8oPromise<T>?), Bool>(key: c8oOnResponse, value: false)
        self.c8oOnResponses.append(keyValue)
        condition.unlock()
        return self;
    }
    
    
    public func ThenUI(c8oOnResponse : (response : T, parameters : Dictionary<String, NSObject>)->(C8oPromise<T>?))-> C8oPromise<T>?
    {
        let condition : NSCondition = NSCondition()
        condition.lock()
        let keyValue : Pair = Pair<(T, Dictionary<String, NSObject>) throws ->(C8oPromise<T>?), Bool>(key: c8oOnResponse, value: true)
        self.c8oOnResponses.append(keyValue)
        condition.unlock()
        return self;
        
    }
    
    
    public func Progress(c8oOnProgress : NSObject/*C8oOnProgress*/)->C8oPromiseFailSync<T>
    {
        //c8oProgress = Dictionary<C8oOnProgress, bool>(c8oOnProgress, false);
        return self;
    }
    
    
    public func ProgressUI(c8oOnProgress : NSObject/*C8oOnProgress*/)->C8oPromiseFailSync<T>
    {
        // c8oProgress = Dictionary<C8oOnProgress, bool>(c8oOnProgress, true);
        return self;
    }
    
    
    public func Fail(c8oOnFail : NSObject/*C8oOnFail*/)->C8oPromiseSync<T>
    {
        //c8oFail = Dictionary<C8oOnFail, bool>(c8oOnFail, false);
        return self;
    }
    
    
    public func FailUI(c8oOnFail : NSObject/*C8oOnFail*/)->C8oPromiseSync<T>
    {
        //c8oFail = Dictionary<C8oOnFail, bool>(c8oOnFail, true);
        return self;
    }
    
    
    public func Sync() throws -> T?
    {
        
        
        syncMutex.lock()
        
        self.Then { response , parameters in
            
            
            self.syncMutex.lock()
            self.lastResult = response
            self.syncMutex.signal()
            self.syncMutex.unlock()
            //let ret : C8oPromise? = nil
            return nil as C8oPromise<T>?
            
        }
        self.syncMutex.wait()
        self.syncMutex.unlock()
        if(lastException != nil){
            throw lastException!
        }
        return lastResult
        
    }
    
    
    public func Async()->NSObject?/*Task<T>*/
    {
        /* TaskCompletionSource<T> task = new TaskCompletionSource<T>();
        
        Then((response, parameters) =>
        {
        task.TrySetResult(response);
        return null;
        }).Fail((exception, parameters) =>
        {
        task.TrySetException(exception);
        });
        
        return task.Task;*/
        return nil
    }
    
    internal func OnResponse(response :T, parameters : Dictionary<String, NSObject>)->Void
    {
        let condition : NSCondition = NSCondition()
        
        do
        {
            condition.lock()
            
            if (c8oOnResponses.count > 0)
            {
                let handler = c8oOnResponses[0];
                c8oOnResponses.removeAtIndex(0)
                
                var promise : [C8oPromise<T>?] = [C8oPromise<T>?](count: 1, repeatedValue: C8oPromise<T>?())
                
                promise[0] = nil
                if (handler.value)
                {
                    var exception : NSException? = nil;
                    let condition2 : NSCondition = NSCondition()
                    condition2.lock()
                    
                    c8o.RunUI { block in
                        //let conditionUI : NSCondition = NSCondition()
                        condition2.lock()
                        do
                        {
                            promise[0] = try! handler.key(response, parameters)!
                        }
                        catch let e as NSException
                        {
                            exception = e
                        }
                        
                        condition2.signal()
                        condition2.unlock()
                    }
                    condition2.wait();
                    if (exception != nil)
                    {
                        //throw exception;
                    }
                    condition2.unlock()
                    
                }
                else
                {
                    promise[0] = try! handler.key(response, parameters)
                }
                
                if (promise[0] != nil)
                {
                    if (promise[0]!.c8oFail == nil)
                    {
                        promise[0]!.c8oFail = c8oFail
                    }
                    if (promise[0]!.c8oProgress == nil)
                    {
                        promise[0]!.c8oProgress = c8oProgress
                    }
                    promise[0]!.Then { resp, param in
                        self.OnResponse(resp, parameters: param)
                        let a : C8oPromise? = nil
                        return a!
                    }
                    
                }
            }
            else
            {
                lastResult = response;
            }
            condition.unlock()
        }
        catch // (Exception exception)
        {
            //OnFailure(exception, parameters);
            
        }
    }
    
    internal func OnProgress(progress : C8oProgress) ->Void
    {
        let condition : NSCondition = NSCondition()
        
        if (c8oProgress != nil)
        {
            if (c8oProgress!.value)
            {
                condition.lock()
                
                c8o.RunUI {
                    let conditionUI : NSCondition = NSCondition()
                    conditionUI.lock()
                    
                    do
                    {
                        try! self.c8oProgress?.key(progress)
                    }
                    catch let e as NSException
                    {
                        self.OnFailure(e, parameters: [C8o.ENGINE_PARAMETER_PROGRESS : progress ])
                    }
                    /*finally
                    {
                    //Monitor.Pulse(locker);
                    }*/
                    condition.signal()
                    conditionUI.unlock()
                    
                }
                condition.wait()
                condition.unlock()
                //Monitor.Wait(locker);
                
            }
            else
            {
                try! c8oProgress?.key(progress);
            }
        }
    }
    
    
    
    internal func OnFailure(var exception : NSException, parameters : Dictionary<String, NSObject>)-> Void
    {
        let lastException = exception
        if (c8oFail != nil)
        {
            if (c8oFail!.value)
            {
                let condition : NSCondition = NSCondition()
                condition.lock()
                
                c8o.RunUI {
                    let conditionUI : NSCondition = NSCondition()
                    conditionUI.lock()
                    
                    do
                    {
                        try! self.c8oFail?.key(exception, parameters);
                    }
                    catch let e as NSException
                    {
                        exception = e
                    }
                    conditionUI.unlock()
                    condition.signal()
                }
                
                condition.wait()
                condition.unlock()
                
            }
            else
            {
                try! self.c8oFail?.key(exception, parameters);
            }
        }
        
        /*condition.lock()
        
        //Monitor.Pulse(syncMutex);
        condition.unlock()*/
        
    }
}
