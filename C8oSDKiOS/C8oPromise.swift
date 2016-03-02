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
    
    private var c8oOnResponses : Array<Pair<(T?, Dictionary<String, NSObject>?)->(), Bool>> = Array<Pair<(T?, Dictionary<String, NSObject>?)->(), Bool>>()
    //= Array<Dictionary<NSObject, Bool>>();
    private var c8oProgress : NSObject? //Dictionary<C8oOnProgress, bool>;
    private var c8oFail : NSObject? //Dictionary<C8oOnFail, bool>;
    private var syncMutex : NSObject = NSObject();
    
    private var lastResult : T?;
    private var lastException : NSException?;
    
    public init(c8o : C8o)
    {
        self.c8o = c8o
        //super.init();
        
    }
    

    public func Then(c8oOnResponse : NSObject/*C8oOnResponse<T>*/)->C8oPromise<T>
    {
        /*let myCondition : NSCondition
        myCondition.lock()*/
        //c8oOnResponses.append(Dictionary</*C8oOnResponse<T>*/ NSObject, Bool>(c8oOnResponse, false));
        
        return self;
    }
    

    public func ThenUI(c8oOnResponse : (response : T?, parameters : Dictionary<String, NSObject>?)->())-> C8oPromise<T>
    {
        let condition : NSCondition = NSCondition()
        condition.lock()
            let keyValue : Pair = Pair<(T?, Dictionary<String, NSObject>?)->(), Bool>(key: c8oOnResponse, value: true)
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
    

    public func Sync()-> T?
    {
        
       /* var condition : NSCondition
        condition.lock()
        
        Then((response, parameters) =>
            {
                lock (syncMutex)
                    {
                        lastResult = response;
                        Monitor.Pulse(syncMutex);
                }
                return null;
            });
        condition.wait()
        condition.unlock()
        
        
        if (lastException != nil)
        {
            throw lastException;
        }
        */
        return nil //lastResult;
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
        /*var condition : NSCondition
        
        do
        {
            condition.lock()
            
            if (c8oOnResponses.count > 0)
            {
                var handler = c8oOnResponses[0];
                c8oOnResponses.RemoveAt(0);
                
                var promise = C8oPromise<T>[1];
                
                if (handler.Value)
                {
                    var exception : NSException? = nil;
                    
                    condition.lock()
                    
                    c8o.RunUI(() =>
                        {
                            condition.lock()
                            
                            do
                            {
                                promise[0] = handler.Key.Invoke(response, parameters);
                            }
                            catch
                            {
                                exception = e;
                            }
                            //Monitor.Pulse(promise);
                            
                        });
                    condition.wait();
                    if (exception != nil)
                    {
                        //throw exception;
                    }
                    condition.unlock()
                    
                }
                else
                {
                    promise[0] = handler.Key.Invoke(response, parameters);
                }
                
                if (promise[0] != nil)
                {
                    if (promise[0].c8oFail = default(Dictionary<C8oOnFail, bool>))
                    {
                        promise[0].c8oFail = c8oFail;
                    }
                    if (promise[0].c8oProgress.Equals(default(Dictionary<C8oOnProgress, bool>)))
                    {
                        promise[0].c8oProgress = c8oProgress;
                    }
                    promise[0].Then((resp, param) =>
                        {
                            OnResponse(resp, param);
                            return nil;
                        });
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
            
        }*/
    }
    
    internal func OnProgress(progress : C8oProgress) ->Void
    {
        var condition : NSCondition
        
        
       /* if (!c8oProgress.Equals(default(KeyValuePair<C8oOnProgress, bool>)))
        {
            if (c8oProgress.Value)
            {
                var locker = new object();
                condition.lock()
                
                c8o.RunUI(() =>
                    {
                        condition.lock()
                        
                        do
                        {
                            c8oProgress.Key.Invoke(progress);
                        }
                        catch NSException
                        {
                            OnFailure(e, Dictionary<string, object>() { { C8o.ENGINE_PARAMETER_PROGRESS, progress } });
                        }
                        finally
                            {
                                //Monitor.Pulse(locker);
                        }
                        condition.unlock()
                        
                    });
                condition.wait()
                condition.unlock()
                //Monitor.Wait(locker);
                
            }
            else
            {
                c8oProgress.Key.Invoke(progress);
            }
        }*/
    }
    
    
    
    internal func OnFailure(exception : NSException, parameters : Dictionary<String, NSObject>)-> Void
    {
        /*lastException = exception;
        var condition : NSCondition*/
        
        /*if (c8oFail != default(Dictionary<C8oOnFail, bool>))
        {
            if (c8oFail.Value)
            {
                
                condition.lock()
                
                c8o.RunUI(() =>
                    {
                        condition.lock()
                        
                        try
                            {
                                c8oFail.Key.Invoke(exception, parameters);
                        }
                        catch (Exception e)
                        {
                            exception = e;
                        }
                        finally
                            {
                                //Monitor.Pulse(locker);
                        }
                        condition.unlock()
                    });
                
                condition.wait()
                condition.unlock()
                
            }
            else
            {
                c8oFail.Key.Invoke(exception, parameters);
            }
        }
        
        condition.lock()
        
        //Monitor.Pulse(syncMutex);
        condition.unlock()
     */   
    }
}
