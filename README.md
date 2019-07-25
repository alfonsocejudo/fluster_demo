# fluster_demo

A Flutter app to demonstrate the [Fluster](https://github.com/alfonsocejudo/fluster) package.

![Image](flusterdemo.gif?raw=true)

If you wish to run the app in an emulator or device, you will have to add your
own API key in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...
  <application ...
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR KEY HERE"/>
```

More info about the Google Maps API key + everything else at the [google_maps_flutter](https://github.com/flutter/plugins/tree/master/packages/google_maps_flutter) repo.