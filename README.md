# SEAR-DC
## SEAR Data Capture

---

### Simple Occipital Structure Data Collection App written in Swift

The project itself is an extension of my Master Project work you can read about here: [SEAR-RL](http://constructive-noise.info/?cat=28)

**SEAR-RL** is a system using an Occipital Structure to allow visual impaired people to hear their surroundings.

**SEAR-DL** (this project) is a data collection app for machine learning made for project for a Machine Learning class I am taking.  The goal of the ML project is to ID object that may pose a hazard or concern to the visual impaired when using SEAR-RL.

You can use the app to collect  data for your own ML project (it should be easy to modify), or just use it as a starting point to learn how to use the Occipital Structure with Swift 4.0.

---
### Usage.

Basically, point and shoot (press the capture button in the app)

There is a UIPickerField you can populate with your own tags to ID images you take.

The App, will generate 6 pieces of datum for a data set.  
* A PGN image from the onboard iDevice Camera
* A PGN of the Occipital Structure’s Point Cloud Data
* A CSV file of the Point Cloud Data.  
* Finally, The app generates a ‘FLOPPED’ (mirrored) version of each datum. (This is just a quick way to double the amount of data you can train a ML model on).

It takes a second to record all data. You will hear the camera shutter noise, when it is done.  (Yeah, no optimization here, just hold the device still for a second and let it do its thing.)

The Project also makes a record in SEAR_DC_INFO.csv this marking any IDs set in the UIPickerField.   All records the datum and the in the SEAR_DC_INFO+DEPTH.csv are tagged with a UNIX time stamp of when the data was recorded.

To extract the data from the iDevice, just plug in and use the iTunes File Sharing. (Make sure you erase the data once you copy it off the device).

Once erased this means a new SEAR_DC_INFO.csv will be created for every session of data collection you do. So, keep that in mind, that you will have multiple SEAR_DC_INFO.csv to be merged at some point. 

---
### DATA Format.

Data format of SEAR_DC_INFO.csv file.
INSTANCE_ID, Angle, Object, Stair_Type, Occupation
For I was doing:
* INSTANCE_ID: Unix Time Stamp - The corresponding Datum will start with this value.
* Angle: is the pitch of the iDevice when taking a data capture.
* Object: was the class of the object in question
* Stair_Type: was a subclass of the Object,
* Occupation: was if the view was obstructed by a person, or object or clear. (I ended up not using this at all)

---
### Addendum

I have tried to document the code and everything pretty well, because I am a big believer in stuff like that. 

However, if anything is missing, or if you need something clarified, feel free to contact me, and I will try to fill in at my earliest chance.

---
### Thanks

Thanks in advance to 'agnomen' for his very helpful posts.

The basic instructions to setup an Occipital Structure Project can be found here: [Guide to setting up a Swift project](https://forums.structure.io/t/guide-to-setting-up-a-swift-project/4020)

When following those instructions, something to be aware of is how you import the Structure.Framework into your project.

I haven't figured out the pattern yet, but sometimes dragging the Structure.Framework into your project XCode just will not seem to find it when you build.  Like it would create a folder called 'Frameworks' and put it there.   Of course, being in that folder doesn't match the header search path in the instructions.  So when you build you get a:

"Structure.h" file not found error.

If this happens just move the Structure.Framework up a directory level, or where ever until XCode finds it.

Similarity if you get a bunch of errors when building that look like this:
    Undefined symbols for architecture arm64:
    "OBJCCLASS_$_STSensorController", referenced from:
    ...
    ld: symbol(s) not found for architecture arm64
    clang: error: linker command failed with exit code 1 (use -v to see invocation)

Make sure you have Structure.framework in the list of "Link Binaries with Libraries" on the Build Phases tab.

[Link error while using Structure SDK](https://forums.structure.io/t/link-error-while-using-structure-sdk/6779)







