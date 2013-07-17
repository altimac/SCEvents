Mods made to mz2's original code:

- removed custom SCEventStreamEventFlags to use FSEvent's standard constants. (they were redefined with the same values, but incomplete since 10.7 and I prepare for the future)
- I'm willing to be compatibble with the new (10.7+) kFSEventStreamCreateFlagFileEvents flag to get _file_ events instead of _directory_ events 
- optimized code (NSSet vs NSArray, and misuse of conformsToProtocol: method). This is a required protocol method so compiler checked the conformance for us...
- You now have to pass some flags (or 0) to the startWatchingPaths:... methods
in order to modify the way the stream is created.
===



SCEvents
========

A GCD and ARC Enabled Fork of Stuart Connolly's SCEvents Objective-C wrapper for Mac OS X's FSEvents C API.

Original code available for download from here: http://stuconnolly.com/downloads/scevents/

License
========

Copyright (c) 2011 Stuart Connolly. All rights reserved.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
