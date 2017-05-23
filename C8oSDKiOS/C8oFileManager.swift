//
//  C8oFileManager.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

internal class C8oFileManager {
	
	internal var createFile: (String) -> Stream;
	
	internal var openFile: (String) -> Stream;
	
	internal init (createFile: @escaping (String) -> Stream, openFile: @escaping (String) -> Stream) {
		self.createFile = createFile;
		self.openFile = openFile;
	}
}
