#pragma once

#include <ARKit/ARKit.h>
#import "AVSoundPlayer.h"


#include "ofxiOS.h"
#include "ofxARKit.h"
#include "ofxDelaunay.h"

#include "DFlow.h"
#include "DFlyObject.h"
#include "DZigLine.h"
#include "DRainy.h"
#include "DSandLine.h"
#include "DPiece.h"


#define MSTAGE 6
#define MEFFECT 11
#define MAX_MSTATIC 10
#define MAX_MFEATURE 60
#define MAX_MFLY_OBJ 60

class ofApp : public ofxiOSApp {
	
    public:
    
        ofApp (ARSession * session);
        ofApp();
        ~ofApp ();
    
        void setup();
        void update();
        void draw();
        void exit();
	
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);

    
        ofTrueTypeFont font;
        ofCamera cam;
    
        int _last_millis;
        int _dmillis;
    
        // ====== SONG ======== //
        AVSoundPlayer* _song;
        int _song_time;
    
        int _stage;
        void setStage(int set_);
        int _stage_time[MSTAGE+1];
    
        int _effect_time[MEFFECT+1];
        int _ieffect;
    
        // ====== AR STUFF ======== //
        ARSession * session;
        ARRef processor;
    
        void reset();
    
        // ====== camera shader ======//
        ofShader _shader_gray;
        ofShader _shader_blur;
        ofShader _shader_canny;
        ofShader _shader_sobel;
        ofFbo _fbo_tmp1,_fbo_tmp2;
    
        float _shader_height;
        float _shader_threshold;
    
        ofTexture _camera_view;
    
        void drawCameraView();
    
        DFlow _screen_flow;
    
    
        // ====== ar object ======//
        vector<DObject*> _feature_object;
        //vector<DRecord*> _record_object;
        DZigLine* _record_object;
    
        //vector<DStatic*> _static_object;
    
        vector<DFlyObject*> _fly_object;
    
        ofShader _shader_mapscreen;
    
        vector<ofVec3f> _detect_feature;
    
        ofVec3f findNextInChain(ofVec3f this_,ofVec3f dir_);
        vector<ofVec3f> getFeatureChain(ofVec3f loc_,int len_);
    
    
        // ====== ui ======//
        void resetButton();
        void nextStage();
        void prevStage();
    
        bool _touched;
        ofVec2f _touch_point;
    
    
};


