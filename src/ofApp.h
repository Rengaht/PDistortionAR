#pragma once

#include <ARKit/ARKit.h>
#import "AVSoundPlayer.h"


#include "ofxiOS.h"
#include "ofxARKit.h"
//#include "ofxDelaunay.h"

#include "DUIview.h"
#include "DFlow.h"
#include "DFlyObject.h"
#include "DZigLine.h"
#include "DRainy.h"
#include "DSandLine.h"

#include "DPiece.h"
#include "DPieceEdge.h"

#include "PAudioData.h"


#define MSTAGE 7
#define MPIANO 40
#define MRAIN 12
#define MAX_MFEATURE 40
#define MAX_MFLY_OBJ 40
#define MAX_MDETECT 80
#define MTOUCH_SMOOTH 6


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

    
        ofCamera cam;
    
        int _last_millis;
        int _dmillis;
    
        int _ww,_wh;
    
        // ====== SONG ======== //
        AVSoundPlayer* _song;
        int _song_time;
    
        int _stage;
        void setStage(int set_);
        int _stage_time[MSTAGE+1];
    
        int _piano_time[MPIANO+1];
        int _rain_time[MRAIN+1];
        
        int _ipiano,_irain,_idot;
    
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
    
        float _sobel_threshold;
        float _shader_threshold;
    
    
        ofTexture _camera_view;
    
        void drawCameraView();
    
        DFlow _screen_flow;
    
    
        // ====== ar object ======//
        list<shared_ptr<DObject>> _feature_object;
        shared_ptr<DObject> _record_object;
        shared_ptr<DObject> _record_object_side;
    
        //vector<DStatic*> _static_object;
    
        list<shared_ptr<DFlyObject>> _fly_object;
    
        ofShader _shader_mapscreen;
    
        list<ofVec3f> _detect_feature;
    
        ofVec3f findNextInChain(ofVec3f this_,ofVec3f dir_);
        list<ofVec3f> getFeatureChain(ofVec3f loc_,int len_);
    
        void updateFeaturePoint();
    
        void addARPiece(ofVec3f loc_);
        void addARLine(ofVec3f loc_);
        void addARParticle(ofVec3f loc_);
    
        void addFlyObject();
        void updateFlyCenter();
    
    
        ofMatrix4x4 _camera_projection, _camera_viewmatrix;
        ofVec3f arScreenToWorld(ofVec3f screen_pos_);
        
    
        vector<ofVec2f> _prev_touch;
        void addTouchTrajectory();
    
        void loadEffectTime();
        void shuffleFeature();
    
        // ====== ui ======//
        DUIView *_uiview;
        void resetButton();
        void nextStage();
        void prevStage();
    
        void setPlay(int& play_);
        void setSongTime(int& time_);
    
    
        bool _touched;
        ofVec2f _touch_point;
    
        int _orientation;
    
        // ====== sample file ======//
        PAudioData *_audio_data;
        float _amp_vibe;
    
};


