/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

var argscheck = require('cordova/argscheck'),
    FileEntry = require('org.apache.cordova.file.FileEntry'),
    exec = require("cordova/exec");

var VideoHelper = function () {
    this.name = "VideoHelper";
};

/**
 * Saves a video to the default user library (such as photo/video Albums for IOS)
 *  
 * @param {DOMString} videoPath an absolute path to the video to save to the user library.
 * @param {Function} successCallback is called with the new entry
 * @param {Function} errorCallback is called with a FileError
 */
VideoHelper.prototype.saveToUserLibrary = function (videoPath, successCallback, errorCallback) {
    
    /**
     * s : string required
     * F : function optional
     */
    argscheck.checkArgs('sFF', 'VideoHelper.saveToUserLibrary', arguments);
    
    var win = function(result) {
        
        if (successCallback) {
            
            var entry = new FileEntry;
            
            entry.isDirectory = false;
            entry.isFile = true;
            entry.name = result.name;
            entry.fullPath = result.fullPath;
            entry.filesystem = new FileSystem(result.filesystemName || (result.filesystem == window.PERSISTENT ? 'persistent' : 'temporary'));
            entry.nativeURL = result.nativeURL;
            successCallback(entry);
            
        }
        
    };

    var fail = errorCallback && function(e) {
        
        // TODO Build specific helper error object to pass as argument to the error callback function
        errorCallback(e);
        
    };
    
    exec(win, fail, "VideoHelper", "saveToUserLibrary", [videoPath]);
    
};

module.exports = new ImageHelper();
