Mods made to mz2's original code:

GOALS :

Implement a higher FSOperation object that simply states, by file if it is a create, rename, move (move within, move outside, move inside of watched path), trash, delete or edit.
Pretty easy with low level file system operations done with CLI.
Much more difficult with high level NSDocument save of even user (via Finder) FS modifications.

CHANGES :

- removed custom SCEventStreamEventFlags to use FSEvent's standard constants. (they were redefined with the same values, but incomplete since 10.7 and I prepare for the future)
- I'm willing to be compatibble with the new (10.7+) kFSEventStreamCreateFlagFileEvents flag to get _file_ events instead of _directory_ events 
- optimized code (NSSet vs NSArray, and misuse of conformsToProtocol: method). This is a required protocol method so compiler checked the conformance for us...
- You now have to pass some flags (or 0) to the startWatchingPaths:... methods
in order to modify the way the stream is created.
- Added an SCEvent interpreter + SCFileSystemOperation object to interpret stream of events and generate higher level objects that describes what is happening on disk.

BUGS :
- It happens sometimes, that using the Finder only, not the CLI. Creating a new file (not folder) by copying in the watched paths generates a "Create" FS operation twice. I still can't find a way to fix that.
- The Cocoa atomic way of saving NSDocuments is a real pain in the ass for low level file watcher. Many files are created on disk and generates noisy events such as :
"/Users/aure/FSEventsTests/screen_express.png.sb-aea45de4-lDI8sH.sb-aea45de4-KiYT7z" then
"/Users/aure/FSEventsTests/screen_express.png.sb-aea45de4-lDI8sH" then
"/Users/aure/FSEventsTests/screen_express.png"
They are of course all the same file, but I can't find a way to robustly determine that. Remember the temporary files are not present on disk anymore when we get those events, so we can only use file name to determine such temporariness... Good luck.

- I've implemented, but not used, a complex way to buffer created file operations and do coalescing to fix such problems. This buffer adds latency so that we can merge some operations to only keep the useful ones.
- Another idea may be to use a delegate in the coalescing to ask the developer if this file is temporary or not. He knows his file naming better than us, and may state on the temporariness of those files

There are litterally much less problems with CLI file creation as it is more straightforward.

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
