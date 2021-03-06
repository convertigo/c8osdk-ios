Pod::Spec.new do |s|
    s.name         = 'C8oSDK'
    s.module_name  = 'C8o'
    s.version      = '2.4.0'
    
    s.author       = 'Convertigo'
    s.license      = 'Apache License 2.0'
    
    s.summary      = 'Convertigo client SDK for iOS.'
    s.description  = <<-DESC
    Convertigo Client SDK is a set of native libraries used by iOS applications to access Convertigo mBaaS services.
    An application using the SDK can easily access Convertigo services such as Sequences and Transactions.
    
    Enterprises will use the Client SDK to abstract the programmer from handling the communication protocols, local cache, FullSync offline data management, UI thread management and remote logging.
    So the developer can focus on building the application.
    DESC
    
    s.homepage     = 'http://www.convertigo.com/convertigo-sdk/'
    documentation_url = 'http://www.convertigo.com/document/convertigo-client-sdk/'
    social_media_url  = 'https://twitter.com/convertigo'
    
    s.source           = { :git => 'https://github.com/convertigo/c8osdk-ios.git', :tag => '2.4.0'}
    s.ios.deployment_target = '10.0'
    s.source_files       = 'C8oSDKiOS/*.swift', 'C8oSDKiOS/Internal/*.swift'
    s.static_framework = true
    s.script_phase = { :name => 'Hello World', :script => 'echo "C8oSDK: Add umbrella header for CBL dependency" && [ ! -d "./couchbase-lite-ios/Couchbaselite.framework/Modules" ] && mkdir ./couchbase-lite-ios/Couchbaselite.framework/Modules || echo "path already exists" && touch ./couchbase-lite-ios/Couchbaselite.framework/Modules/module.modulemap && echo \'framework module CouchbaseLite { module All { umbrella header "../Headers/CouchbaseLite.h" export * module * { export * }} module JSView { umbrella header "../../Extras/CBLRegisterJSViewCompiler.h" export * module * { export * }}}\' > ./couchbase-lite-ios/Couchbaselite.framework/Modules/module.modulemap', :execution_position => :before_compile }
    s.platform     = :ios, '10.0'
    s.swift_version = '5.0'
    s.dependency 'SwiftyJSON', '5.0.0'
    s.dependency 'Alamofire', '5.2.1'
    s.dependency 'AEXML', '4.5.0'
    s.dependency 'couchbase-lite-ios', '1.4.4'
    s.dependency 'couchbase-lite-ios/ForestDB', '1.4.4'
end
