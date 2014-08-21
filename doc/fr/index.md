<!---
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
-->

# com.gomoob.cordova.video-helper

This cordova plugin provides utility functions to manipulate videos.

## Installation

    cordova plugin add com.gomoob.cordova.video-helper

## Supported Platforms

- iOS

# VideoHelper

The `VideoHelper` object provides a set of utility function to manipulate videos.

## Methods

- __saveToUserLibrary__: saves a video to the default user media library.

## saveToUserLibrary

__Parameters__:

- __videoPath__: the full system path to the video to save. _(string)_

- __successCallback__: A callback that is passed a `Metadata` object. _(Function)_

- __errorCallback__: A callback that executes if an error occurs saving the video. _(Function)_

### Example

    // !! Assumes variable videoPath contains a valid system path to a video file on the device

    var win = function (fileEntry) {
        console.log(fileEntry);
    }

    var fail = function (error) {
        console.error("An error has occurred !");
    }

    window.VideoHelper.saveToUserLibrary(videoPath, win, fail);
    
## checkMicrophoneAccessPermission

__Parameters__:

- __successCallback__: A callback that is passed a `boolean` object. _(Function)_

- __errorCallback__: A callback that executes if an error occurs checking the microphone access permission. _(Function)_

### Example

    var win = function (permissionGranted) {
        console.log('Is permission granted : ' + permissionGranted);
    }

    var fail = function (error) {
        console.error("An error has occurred !");
    }

    window.VideoHelper.checkMicrophoneAccessPermission(win, fail);

    