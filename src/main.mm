#include "ofApp.h"




float DFlyObject::maxForce=.2;
float DFlyObject::maxSpeed=5;
float DFlyObject::rad=.1;
float DFlyObject::boundary=0;
ofVec3f DFlyObject::cent=ofVec3f(0);

float DObject::rad=.1;

float DFlow::maxForce=3;
float DFlow::maxSpeed=20;
float DFlow::rad=100;



int main() {
    
    //  here are the most commonly used iOS window settings.
    //------------------------------------------------------
    ofiOSWindowSettings settings;
    settings.enableRetina = true; // enables retina resolution if the device supports it.
    settings.enableDepth = true; // enables depth buffer for 3d drawing.
    settings.enableAntiAliasing = false; // enables anti-aliasing which smooths out graphics on the screen.
    settings.numOfAntiAliasingSamples = 0; // number of samples used for anti-aliasing.
    settings.enableHardwareOrientation = false; // enables native view orientation.
    settings.enableHardwareOrientationAnimation = false; // enables native orientation changes to be animated.
    settings.glesVersion = OFXIOS_RENDERER_ES2; // type of renderer to use, ES1, ES2, etc.
    
    ofAppiOSWindow * window = (ofAppiOSWindow *)(ofCreateWindow(settings).get());
    
    bool bUseNative = true;
    if (bUseNative){
        /**
         *
         *  Below is how you start using a native ios setup.
         *
         *  First a ofAppiOSWindow is created and added to ofSetupOpenGL()
         *  Notice that no app is being sent to ofRunApp() - this happens later when we actually need the app.
         *
         *  One last thing that needs to be done is telling ofAppiOSWindow which AppDelegate to use.
         *  This is a custom AppDelegate and inside it you can start coding your native iOS application.
         *  The AppDelegate must extend ofxiOSAppDelegate.
         *
         **/
        
        window->startAppWithDelegate("MyAppDelegate");
    }
    else {
        /**
         *
         *  This is the normal way of running an app using ofxiOS.
         *  This code has been left in this example to show that ofxiOS still works
         *
         **/
        
        return ofRunApp(new ofApp());
    }
}
