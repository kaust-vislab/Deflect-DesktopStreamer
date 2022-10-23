# Deflect

KAUST fork of deflect for streaming to DisplayCluster on the Zone 2 display wall. Some changes have been made to build on modern Macs. Build instructions or current to October 2022.


## Building from source

First build oibjpeg-turbo

### build libjpegturbo
NASM is a prereq for performance. Use brew or conda to install this first. 
~~~
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
cd libjpeg-turbo
mkdir build
cd build
ccmake -GNinja -DCMAKE_INSTALL_PREFIX=../install ../.
ninja
ninja install
~~~


### Setup
~~~
git clone https://github.com/kaust-vislab/Deflect-DesktopStreamer.git
mkdir Deflect/build
cd Deflect/build
~~~


### linux
~~~

cmake -DCMAKE_INSTALL_PREFIX=../install -DUSE_PYTHON_VERSION=3 -DCMAKE_BUILD_TYPE=RELEASE -DLibJpegTurbo_INCLUDE_DIR=/home/kressjm/packages/libjpeg-turbo/install/include/ -DLibJpegTurbo_LIBRARY=/home/kressjm/packages/libjpeg-turbo/install/lib/libturbojpeg.a -DCOMMON_LIBRARY_TYPE=STATIC ../.
~~~

### Mac
Had to fix a bunch of files and then change config options
Openmp linking was a problem

** Another issue is supporting Mac's that are using the intel vs. M1 chip. We need to build
A version of desktop streamer on both of these architectures. Building the x86_64 on the M1
Was not working cleanly due to using QT5 and it not supporting both builds currently **

~~~
cmake -DCMAKE_INSTALL_PREFIX=../install -DUSE_PYTHON_VERSION=3 -DCMAKE_BUILD_TYPE=RELEASE -DLibJpegTurbo_INCLUDE_DIR=/Users/kressjm/packages/libjpeg-turbo/install/include/ -DLibJpegTurbo_LIBRARY=/Users/kressjm/packages/libjpeg-turbo/install/lib/libturbojpeg.a  -DCMAKE_OSX_ARCHITECTURES=x86_64 -DOpenMP_CXX_FLAGS="-Xpreprocessor  -fopenmp -lomp" -DOpenMP_CXX_LIB_NAMES="-lomp" -DOpenMP_C_FLAGS="-Xpreprocessor -fopenmp -lomp" -DOpenMP_C_LIB_NAMES="lomp" -DCOMMON_LIBRARY_TYPE=STATIC ../.
~~~


** now make a whole new build to support M1 **
~~~
cmake -DCMAKE_INSTALL_PREFIX=../install -DUSE_PYTHON_VERSION=3 -DCMAKE_BUILD_TYPE=RELEASE -DLibJpegTurbo_INCLUDE_DIR=/Users/kressjm/packages/libjpeg-turbo/install/include/ -DLibJpegTurbo_LIBRARY=/Users/kressjm/packages/libjpeg-turbo/install/lib/libturbojpeg.a  -DCMAKE_OSX_ARCHITECTURES=arm64 -DOpenMP_CXX_FLAGS="-Xpreprocessor  -fopenmp -lomp" -DOpenMP_CXX_LIB_NAMES="-lomp" -DOpenMP_C_FLAGS="-Xpreprocessor -fopenmp -lomp" -DOpenMP_C_LIB_NAMES="lomp" -DCOMMON_LIBRARY_TYPE=STATIC ../.
~~~

#### Creating a mac distribution
First you will need to sign the `*.app` file using something like:

`codesign --force --deep --sign - DesktopStreamer.app/  `


Then:
- Use Disk Utility to create a new empty sparse bundle disk image
- Double-click the image to open it.
- Copy your app into the image.
- Make a link to /Applications in the image.
- Hide the toolbar/sidebar/etc. as desired.
- Using View Options set to always one in icon mode.
- Also add a background image if you like using View Options. Background images often contain text such as "Drag App to Application". Layout the app and /Applications icons to match your background image.
- In another Finder window eject the sparse bundle.
- In Disk Utility use Images -> Convert... to convert the sparse bundle to a read-only DMG


This should be done for both the M1 and intel versions if we are supporting both chips.


## Overview

![Deflect features overview](doc/overview.png)

## Features

Deflect provides the following functionality:

* Stream pixels to a remote Server from one or multiple sources
* Stream stereo images from a distributed 3D application
* Receive input events from the Server and send data to it
* Transmitted events include keyboard, mouse and multi-point touch gestures
* Compressed or uncompressed streaming
* Fast multi-threaded JPEG (de)compression using libjpeg-turbo

DeflectQt (optional) provides the following additional functionality:

* Create QML applications which render offscreen and stream and receive events
  via Deflect

The following applications are provided which make use of the streaming API:

* DesktopStreamer: A small utility that lets you stream your desktop.
* SimpleStreamer: A simple example to demonstrate streaming of an OpenGL
  application.
* QmlStreamer (optional): An offscreen application to stream any given qml file.



## About

Deflect is a cross-platform library, designed to run on any modern operating
system, including all Unix variants. Deflect uses CMake to create a
platform-specific build environment. The following platforms and build
environments are tested:

* Linux: Ubuntu 16.04 and RHEL 6 (Makefile, Ninja; x64)
* Mac OS X: 10.7 - 10.10 (Makefile, Ninja; x86_64)

The [latest API documentation](http://bluebrain.github.io/Deflect-1.0/index.html)
can be found on [bluebrain.github.io](http://bluebrain.github.io).

## Funding & Acknowledgment
 
The development of this software was supported by funding to the Blue Brain Project,
a research center of the École polytechnique fédérale de Lausanne (EPFL), from the 
Swiss government’s ETH Board of the Swiss Federal Institutes of Technology.

This project has received funding from the European Union’s FP7-ICT programme
under Grant Agreement No. 604102 (Human Brain Project RUP).

This project has received funding from the European Union's Horizon 2020 Framework
Programme for Research and Innovation under the Specific Grant Agreement No. 720270
(Human Brain Project SGA1).

This project is based upon work supported by the King Abdullah University of Science
and Technology (KAUST) Office of Sponsored Research (OSR) under Award No. OSR-2017-CRG6-3438.

## License

Deflect is licensed under the LGPL, unless noted otherwise, e.g., for external dependencies.
See file LICENSE.txt for the full license. External dependencies are either LGPL or BSD-licensed.
See file ACKNOWLEDGEMENTS.txt and AUTHORS.txt for further details.

Copyright (C) 2013-2022 Blue Brain Project/EPFL, King Abdullah University of Science and
Technology and AUTHORS.txt.

This library is free software; you can redistribute it and/or modify it under the terms of the
GNU Lesser General Public License version 2.1 as published by the Free Software Foundation.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library;
if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301 USA

