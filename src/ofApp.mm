#include "ofApp.h"

//--------------------------------------------------------------
ofApp :: ofApp (ARSession * session){
    this->session = session;
    cout << "creating ofApp" << endl;
}

ofApp::ofApp(){}

//--------------------------------------------------------------
ofApp :: ~ofApp () {
    cout << "destroying ofApp" << endl;
}

//--------------------------------------------------------------
void ofApp::setup(){	
    ofBackground(127);
    
    _stage_time[0]=0;
    _stage_time[1]=57000;
    _stage_time[2]=150000;
    _stage_time[3]=201000;
    _stage_time[4]=250000;
    _stage_time[5]=300000;
    _stage_time[6]=330000;
    
    _song=[[AVSoundPlayer alloc] init];
    [_song loadWithFile:@"music/be.wav"]; // uncompressed wav format.
//    [vocals volume:1.0];
    _stage=-1;
    
    
    int fontSize = 8;
    if (ofxiOSGetOFWindow()->isRetinaSupportedOnDevice())
        fontSize *= 2;
    
    //font.load("fonts/mono0755.ttf", fontSize,true, false, true, 0.4, 72);
    font.load("fonts/mono0755.ttf", fontSize);
    
    processor = ARProcessor::create(session);
    processor->setup(true);
    
    
    _fbo_tmp1.allocate(ofGetWidth(),ofGetHeight(),GL_RGB);
    _fbo_tmp2.allocate(ofGetWidth(),ofGetHeight(),GL_RGB);
    
    _shader_gray.load("shaders/grayScale.vert", "shaders/grayScale.frag");
    _shader_blur.load("shaders/blur.vert", "shaders/blur.frag");
    _shader_canny.load("shaders/canny.vert", "shaders/canny.frag");
    _shader_sobel.load("shaders/sobel.vert", "shaders/sobel.frag");
    
    _shader_mapscreen.load("shaders/mapScreen.vert", "shaders/mapScreen.frag");
    
    
    float s=ofGetWidth()/50000.0;
    
    DFlyObject::maxForce=0.1*s;
    DFlyObject::maxSpeed=2*s;
    DFlyObject::rad=1.0*s;
    DFlyObject::cent=ofVec3f(0,0,0);
    
    
    _touched=false;
    
    _last_millis=ofGetElapsedTimeMillis();
    _dmillis=0;
    
    setStage(0);
    
    _shader_threshold=0;
    
}

//--------------------------------------------------------------
void ofApp::update(){
    
    processor->update();
    //processor->updatePlanes();
    
    _song_time=_song.positionMs;
    
    
    _dmillis=ofGetElapsedTimeMillis()-_last_millis;
    _last_millis+=_dmillis;
    
    
    
    
    _camera_view=processor->camera->getCameraImage();
    
    
    auto pts_=processor->pointCloud.getPoints(this->session.currentFrame);
    
    if(_stage<MSTAGE-1 && _song_time>=_stage_time[_stage+1]) _stage++;
    
    switch(_stage){
        case 0:
            _shader_height=sin(ofGetFrameNum()/500.0*TWO_PI)*.2+ofMap(_song_time,0,57000,0.1,1);
            _shader_threshold=0;
            break;
        case 1: // auto add line
            _shader_height=1.0;
            _shader_threshold=0;
            if(pts_.size()>0 && ofRandom(10)<1){
                    int add_=floor(ofRandom(pts_.size()));
                    if(ofRandom(2)<1)
                        _feature_object.push_back(new DZigLine(pts_[add_]));
                    else
                        _feature_object.push_back(new DRainy(pts_[add_],floor(ofRandom(2000,10000))));
                    pts_.erase(pts_.begin()+add_);
            }
            break;
        case 2:
            _shader_height=1.0;
            _shader_threshold=0;
            if(_touched){
                processor->addAnchor(ofVec3f(_touch_point.x,_touch_point.y,-1));
                ARObject anchor=processor->anchorController->getAnchorAt(processor->anchorController->getNumAnchors()-1);
                ofVec3f pos=anchor.modelMatrix.getTranslation();
                _record_object->addVertex(pos,ofVec2f(_touch_point.x/ofGetWidth(),_touch_point.y/ofGetHeight()));
            }

            break;
        case 3:
            _shader_threshold=abs(.5*sin(ofGetFrameNum()/30.0*TWO_PI+ofRandom(-2,2)));
            break;
        case 4:
            _shader_height=1.0;
            _shader_threshold=abs(sin(ofGetFrameNum()/30.0*TWO_PI+ofRandom(-5,5)));
//            DFlyObject::cent=processor->getCameraPosition();
//            DFlyObject::cent.z=-1;
//            for(auto& p:_feature_object){
//                p->updateFlock(_feature_object);
//            }
            break;
        case 5:
            _shader_height=sin(ofGetFrameNum()/500.0*TWO_PI)*.2+ofMap(_song_time,_stage_time[5],_stage_time[6],1,0);
            if(ofRandom(30)<1){
                if(_feature_object.size()>0) _feature_object.erase(_feature_object.begin());
                if(_fly_object.size()>0) _fly_object.erase(_fly_object.begin());
//                if(_static_object.size()>0) _static_object.erase(_static_object.begin());
//                if(_record_object.size()>0) _record_object.erase(_record_object.begin());
            }
            if(_song_time==0){
              _shader_height=0;
                _feature_object.clear();
                _fly_object.clear();
//                _static_object.clear();
//                _record_object.clear();
            }
            
            break;
    }
    
    _detect_feature.insert(_detect_feature.begin(),pts_.begin(),pts_.end());
    _detect_feature.resize(MAX_MFEATURE);
  
        
        auto matrices = processor->getCameraMatrices();
        ofMatrix4x4 model = ARCommon::toMat4(session.currentFrame.camera.transform);
//        //position,matrices.cameraProjection,model * getCameraMatrices().cameraView
    
        
    
   
    if(_feature_object.size()>0){
        auto it=_feature_object.end();
        it--;
        for(;it>=_feature_object.begin();it--){
            (*it)->update(_dmillis);
            if((*it)->dead()) _feature_object.erase(it);
        }
    }
    
    if(_feature_object.size()>MAX_MFEATURE) _feature_object.erase(_feature_object.begin()) ;
//    if(_static_object.size()>MAX_MSTATIC) _static_object.erase(_static_object.begin()) ;
    
    

}

//--------------------------------------------------------------
void ofApp::draw(){
    ofEnableAlphaBlending();
    
    ofDisableDepthTest();
    
    drawCameraView();
    
    
    ofEnableDepthTest();
    
    
    cam.begin();
    processor->setARCameraMatrices();
    
    
//    _shader_mapscreen.begin();
//    _shader_mapscreen.setUniformTexture("inputImageTexture", _camera_view, 0);
    
    //_camera_view.setTextureWrap(GL_REPEAT,GL_REPEAT);
    
    _camera_view.bind();
    for(auto& p:_feature_object) p->draw();
//    for(auto& p:_static_object) p->draw();
//    for(auto& p:_record_object) p->draw();
    _camera_view.unbind();
    
//    _shader_mapscreen.end();
    
    if(_stage>0 && _stage<4){
        ofPushStyle();
        for(auto&p:_detect_feature){
            ofSetColor(255,255,0,100+150*sin(ofGetFrameNum()/10.0+p.x*1000*TWO_PI));
            ofDrawSphere(p.x,p.y,p.z,0.001);
        }
        ofPopStyle();
    }
    
    
    
    
    
    
    cam.end();
    
    
    ofDisableDepthTest();
    // ========== DEBUG STUFF ============= //
    int w = MIN(ofGetWidth(), ofGetHeight()) * 0.6;
    int h = w;
    int x = (ofGetWidth() - w)  * 0.5;
    int y = (ofGetHeight() - h) * 0.5;
    int p = 0;
    
    x = ofGetWidth()  * 0.2;
    y = ofGetHeight() * 0.11;
    p = ofGetHeight() * 0.035;
    
    
    font.drawString("stage       = " + ofToString(_stage),    x, y+=p);
    font.drawString("song time   = " + ofToString(floor(_song_time/60000))+":"+ofToString(floor((_song_time/1000)%60))+":"+ofToString(_song_time%1000),    x, y+=p);
    font.drawString("frame rate  = " + ofToString( ofGetFrameRate() ),   x, y+=p);
    //    font.drawString("screen width   = " + ofToString( ofGetWidth() ),       x, y+=p);
    //    font.drawString("screen height  = " + ofToString( ofGetHeight() ),      x, y+=p);
    
    font.drawString("state       = " + ofToString(processor->camera->getTrackingState()),x, y+=p);
    
    font.drawString("#feature obj= " + ofToString(_feature_object.size()),x, y+=p);
//    font.drawString("#static obj = " + ofToString(_static_object.size()),x, y+=p);
//    font.drawString("#record obj = " + ofToString(_record_object.size()),x, y+=p);
    
    font.drawString("#point cloud= " + ofToString(processor->pointCloud.getNumFeatures()),x, y+=p);
    font.drawString("#plane      = " + ofToString(processor->anchorController->getNumPlanes()),x, y+=p);
    font.drawString("#anchor     = " + ofToString(processor->anchorController->getNumAnchors()),x, y+=p);
    
}

//--------------------------------------------------------------
void ofApp::exit(){
    [_song release];
    _song=nil;
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    _touched=true;
    _touch_point.x=touch.x;
    _touch_point.y=touch.y;
    
    switch(_stage){
        case 1:
            break;
        case 2:
            DRecord* rec_=new DRecord();
            _feature_object.push_back(rec_);
            _record_object=rec_;
            break;
    }
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    //if(abs(_touch_point.x-touch.x)>30 && abs(_touch_point.y-touch.y)>30){
        _touch_point.x=touch.x;
        _touch_point.y=touch.y;
    //}
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    _touched=false;
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}


void ofApp::drawCameraView(){
    
    if(_shader_height<=0){
        processor->draw();
        
    }else{
        
        float ww=ofGetWidth();
        float wh=ofGetHeight();
        
        _fbo_tmp1.begin();
        _shader_gray.begin();
        _shader_gray.setUniformTexture("inputImageTexture", _camera_view, 0);
        _camera_view.draw(0, 0, ww, wh);
        _shader_gray.end();
        _fbo_tmp1.end();
        
        _fbo_tmp2.begin();
        _shader_blur.begin();
        _shader_blur.setUniformTexture("inputImageTexture", _fbo_tmp1.getTexture(), 0);
        _shader_blur.setUniform1f("window_width", ww);
        _shader_blur.setUniform1f("window_height", wh);
        _fbo_tmp1.draw(0, 0, ww, wh);
        _shader_blur.end();
        _fbo_tmp2.end();

//        _fbo_tmp1.begin();
//        _shader_blur.begin();
//        _shader_blur.setUniformTexture("inputImageTexture", _fbo_tmp2.getTexture(), 0);
//        _fbo_tmp2.draw(0, 0, ww, wh);
//        _shader_blur.end();
//        _fbo_tmp1.end();
//
//        _fbo_tmp2.begin();
//        _shader_blur.begin();
//        _shader_blur.setUniformTexture("inputImageTexture", _fbo_tmp1.getTexture(), 0);
//        _camera_view.draw(0, 0, ww, wh);
//        _shader_blur.end();
//        _fbo_tmp2.end();
        
        //    _fbo_tmp2.draw(0,0);
        
        //
        //    _shader_canny.begin();
        //        //processor->draw();
        //        _shader_canny.setUniformTexture("inputImageTexture", _fbo_tmp2.getTexture(), 0);
        //        _shader_canny.setUniform1f("texelWidth", 1.0);
        //        _shader_canny.setUniform1f("texelHeight", 1.0);
        //        _shader_canny.setUniform1f("upperThreshold", 0.4);
        //        _shader_canny.setUniform1f("lowerThreshold", 0.1);
        //        _fbo_tmp2.draw(0, 0, ofGetWidth(), ofGetHeight());
        //
        //    _shader_canny.end();
        
        
        
        
        _fbo_tmp1.begin();
        _shader_sobel.begin();
        //_shader_sobel.setUniformTexture("originTexture", _camera_view, 0);
        _shader_sobel.setUniformTexture("inputImageTexture", _fbo_tmp2.getTexture(), 0);
        _shader_sobel.setUniform1f("window_width", ww);
        _shader_sobel.setUniform1f("window_height", wh);
        _shader_sobel.setUniform1f("show_height", _shader_height);
        _shader_sobel.setUniform1f("show_threshold", _shader_threshold);
        //_shader_sobel.setUniform1f("frame_distort", ofRandom(1));
        
        _camera_view.draw(0, 0, ww,wh);
        //window_.draw();

        _shader_sobel.end();
        _fbo_tmp1.end();
        
        //        _shader_gray.begin();
        //            _shader_gray.setUniformTexture("inputImageTexture", _fbo_tmp1.getTexture(), 0);
        //            _fbo_tmp1.draw(0, 0, ww, wh);
        //        _shader_gray.end();
        _fbo_tmp1.draw(0,0,ww,wh);
    }
    
}

void ofApp::reset(){
    ofLog()<<"reset anchor!";
    //    processor->anchorController->clearAnchors();
    //    processor->restartSession();
    //processor->anchorController->clearPlaneAnchors();
    
    //processor->restartSession();
    //[session runWithConfiguration:session.configuration options:ARSessionRunOptionResetTracking|ARSessionRunOptionRemoveExistingAnchors];
    
    _feature_object.clear();
//    _static_object.clear();
//    _record_object.clear();
}

// ======================== BUTTON ======================== //
void ofApp::resetButton(){
  
    reset();
    setStage(0);
    
}
void ofApp::nextStage(){
    
    setStage(_stage+1);
}
void ofApp::prevStage(){
    
    setStage(_stage-1);
}
void ofApp::setStage(int set_){
    
    if(set_>=MSTAGE|| set_<0) return;
    
   
    [_song play];
    
    [_song positionMs:_stage_time[set_]];
    _stage=set_;
    
    if(set_==0) reset();
    

}



//void ofApp::toggleShader(){
//    _use_shader=!_use_shader;
//}
//
//void ofApp::toggleDFlyObject(){
//    _update_object=!_update_object;
//}
