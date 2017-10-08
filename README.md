# SEAR-DC
## SEAR Data Capture

---

Thanks in advance to 'agnomen' for his very helpful posts.

This is a really simple Occipital Strucutre project for Swift 4.

The basic instrucutions to setup an Occipital Struture Project can be found here:

[Guide to setting up a Swift project](https://forums.structure.io/t/guide-to-setting-up-a-swift-project/4020)

When following those instrucutions, something to be aware of is you import the Structure.Framework into your problem.

I haven't figured out the pattern yet, but sometimes dragging the Structure.Framework into your project XCode just will not seem to find it when you build.  Like it would create a folder called 'Frameworks' and put it there.   Of coruse, being in that folder doesn't match the header search path in the instructions.  So when you build you get a:

"Structure.h" file not found error.

If this happens just move the Structure.Framework up a directory level, or where ever until XCode finds it.

Similarity if you get a bunch of errors when building that look like this:
    Undefined symbols for architecture arm64:
    "OBJCCLASS_$_STSensorController", referenced from:
    ...
    ld: symbol(s) not found for architecture arm64
    clang: error: linker command failed with exit code 1 (use -v to see invocation)

Make sure you have Structure.framework in the list of "Link Binaries With Libraries" on the Build Phases tab.

[Link error while using Structure SDK](https://forums.structure.io/t/link-error-while-using-structure-sdk/6779)
