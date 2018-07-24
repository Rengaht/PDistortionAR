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
    
    loadEffectTime();
    
    _idot=_irain=_ipiano=1;
    
    //NSError *err;
    _song=[[AVSoundPlayer alloc] init];
    //[_song initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle pathForResource:@"be" ofType:@"wav"]] error:&err]; // uncompressed wav format.
    [_song loadWithFile:@"music/be.wav"];
    
//    [vocals volume:1.0];
    _stage=-1;
    
    
//    int fontSize = 8;
//    if (ofxiOSGetOFWindow()->isRetinaSupportedOnDevice())
//        fontSize *= 2;
//    
//    //font.load("fonts/mono0755.ttf", fontSize,true, false, true, 0.4, 72);
//    font.load("fonts/mono0755.ttf", fontSize);
//    
    
    ofxAccelerometer.setup();
    
    processor = ARProcessor::create(session);
    processor->setup(true);
    
    _ww=ofGetWidth();
    _wh=ofGetHeight();
    
    _fbo_tmp1.allocate(_ww,_wh,GL_RGB);
    _fbo_tmp2.allocate(_ww,_wh,GL_RGB);
    
   
    
    _shader_gray.load("shaders/grayScale.vert", "shaders/grayScale.frag");
    _shader_blur.load("shaders/blur.vert", "shaders/blur.frag");
    _shader_blur.begin();
    _shader_blur.setUniform1f("window_width", _ww);
    _shader_blur.setUniform1f("window_height", _wh);
    _shader_blur.end();
    
    _shader_canny.load("shaders/canny.vert", "shaders/canny.frag");
    _shader_sobel.load("shaders/sobel.vert", "shaders/sobel.frag");
    _shader_sobel.begin();
    _shader_sobel.setUniform1f("window_width", _ww);
    _shader_sobel.setUniform1f("window_height", _wh);
    _shader_sobel.end();
    
    _shader_mapscreen.load("shaders/mapScreen.vert", "shaders/mapScreen.frag");
    _shader_mapscreen.begin();
    _shader_mapscreen.setUniform1f("window_width", _ww*10.0);
    _shader_mapscreen.setUniform1f("window_height", _wh*2.0);
    _shader_mapscreen.end();
    
    float s=_ww/10000.0;
    DFlyObject::maxForce=.2*s;
    DFlyObject::maxSpeed=8*s;
    DFlyObject::rad=1.0*s;
    DFlyObject::cent=ofVec3f(0,0,0);
    
    
    _touched=false;
    
    _last_millis=ofGetElapsedTimeMillis();
    _dmillis=0;
    
    
    _shader_threshold=0;
    _sobel_threshold=.5;
    
    _screen_flow=DFlow(_shader_threshold);
    

    _uiview=new DUIView(334737);
    ofAddListener(_uiview->_event_play, this, &ofApp::setPlay);
    //ofAddListener(_uiview->_event_time, this, &ofApp::setSongTime);
    
    
    reset();
    
    
}

//--------------------------------------------------------------
void ofApp::update(){
    
    
    if(!_uiview->_playing || _stage==0 || _stage==5) processor->updateCamera();
    else processor->update();
    //processor->updatePlanes();
    
    _camera_view=processor->camera->getCameraImage();
    _uiview->_bad_tracking=(processor->camera->getTrackingState()!=2);
    _uiview->setHint(_stage);
    
    if(!_uiview->_playing) return;
    
    _song_time=_song.positionMs;
    
    
    _dmillis=ofGetElapsedTimeMillis()-_last_millis;
    _last_millis+=_dmillis;
    
    //// update camera ////
    auto cam_matrix=processor->getCameraMatrices();
    ofMatrix4x4 model = ARCommon::toMat4(session.currentFrame.camera.transform);
    _camera_projection=cam_matrix.cameraProjection;
    _camera_viewmatrix=model*cam_matrix.cameraView;
    

    
   
   
    
    
    if(_stage<MSTAGE-1 && _song_time>=_stage_time[_stage+1]) _stage++;
    
    /* add piano piece */
    if(_detect_feature.size()>0){
        if(_ipiano<MPIANO){
            if(_song_time>=_piano_time[_ipiano]){
                ofLog()<<"add effect!";
                addARPiece(*_detect_feature.begin());
                _ipiano++;
                _detect_feature.pop_front();
            }
        }
    }
    list<ofVec3f> pts_;
    switch(_stage){
        case 0:
            _shader_threshold=ofMap(_song_time,0,_stage_time[1],0,.7);
            _screen_flow.update(_shader_threshold,ofxAccelerometer.getForce());
            return;
        case 1: // auto add line
            _shader_threshold=1.0;
            _sobel_threshold=.5;
            
            //if(_detect_feature.size()<MAX_MFEATURE){
            if(ofGetFrameNum()%60==0){
                pts_=processor->pointCloud.getPoints(this->session.currentFrame);
                //random_shuffle(pts_.begin(), pts_.end());
                _detect_feature.insert(_detect_feature.begin(),pts_.begin(),pts_.end());
                if(_detect_feature.size()>MAX_MFEATURE) _detect_feature.resize(MAX_MFEATURE);
            }
            
            break;
        case 2:
            _sobel_threshold=.5;
            _shader_threshold=1.0;
            if(_touched){
                addTouchTrajectory();
            }
            break;
        case 3:
            _shader_threshold=1+abs(.5*sin(ofGetFrameNum()/30.0*TWO_PI+ofRandom(-2,2)));
            _sobel_threshold=.5;
            
            if(ofRandom(20)<1) addFlyObject();
            
            updateFlyCenter();
            for(auto& p:_fly_object){
                p->updateFlock(_fly_object);
            }
            break;
        case 4:
            _shader_threshold=1+abs(sin(ofGetFrameNum()/30.0*TWO_PI+ofRandom(-5,5)));
            _sobel_threshold=.8-.6*abs(sin(ofGetFrameNum()/10.0*TWO_PI+ofRandom(-5,5)));
            
            if(ofRandom(5)<1) addFlyObject();
            
            updateFlyCenter();
            for(auto& p:_fly_object){
                p->updateFlock(_fly_object);
            }
            break;
        case 5:
            _shader_threshold=1;
            //_screen_flow.update(_shader_threshold,ofxAccelerometer.getForce());
            _sobel_threshold=ofMap(_song_time,_stage_time[5],_stage_time[6],.2,2.0);
            
            if(ofRandom(10)<1){
                if(_feature_object.size()>0){
                  _feature_object.pop_front();
                }
                if(_fly_object.size()>0){
                    _fly_object.pop_front();
                }
            }
            for(auto& p:_fly_object){
                p->updateFlock(_fly_object);
            }
            
            break;
        case 6:
            _shader_threshold=1;
            _sobel_threshold=2;
            if(_song_time==0) reset();
            break;
    }
    
   
  
   
    for(auto& it:_feature_object) it->update(_dmillis);
    _feature_object.remove_if([](shared_ptr<DObject> obj){return obj->dead();});
    
    int m=_feature_object.size()-MAX_MFEATURE;
    if(m>0){
        for(int i=0;i<m;++i){
          _feature_object.pop_front();
        }
    }
    
    
    
    
}

void ofApp::addARPiece(ofVec3f loc_){
    int last=-1;//ofRandom(2)<1?-1:floor(ofRandom(2000,1000));
    _feature_object.push_back(shared_ptr<DObject>(new DPiece(loc_,last)));
    if(ofRandom(3)<1){
        ofVec3f offset_(ofRandom(-1,1));
        offset_*=DObject::rad/2;
        _feature_object.push_back(shared_ptr<DObject>(new DPieceEdge(loc_+offset_,last)));
    }
    //random_shuffle(_feature_object.begin(), _feature_object.end());

}

void ofApp::addARLine(ofVec3f loc_){
    auto vert_=getFeatureChain(loc_,floor(ofRandom(5,10)));
    if(vert_.size()>0) _feature_object.push_back(shared_ptr<DObject>(new DSandLine(*vert_.begin(),floor(ofRandom(1000,5000)),vert_)));
    
}

void ofApp::addARParticle(ofVec3f loc_){
    
    _feature_object.push_back(shared_ptr<DObject>(new DRainy(loc_,floor(ofRandom(2000,10000)))));
    //random_shuffle(_feature_object.begin(), _feature_object.end());

}

void ofApp::addFlyObject(){
    
    if(_feature_object.size()<1) return;

    auto it=_feature_object.begin();
    //int index_=floor(ofRandom(_feature_object.size()));

    //for(int i=0;i<index_;++i) it++;

    auto pt=(*it)->breakdown();
     _feature_object.pop_front();
    
//    if(pt.size()<1){
//       // delete _feature_object[index_];
//        _feature_object.erase(it);
////        _feature_object.pop_front();
//        return;
//    }
    _fly_object.insert(_fly_object.end(),pt.begin(),pt.end());

    ofLog()<<"break down to "<<pt.size()<<" flyobjects!";


//    random_shuffle(_fly_object.begin(),_fly_object.end());
    
    if(_fly_object.size()>MAX_MFLY_OBJ) _fly_object.resize(MAX_MFLY_OBJ);
//    while(_fly_object.size()>MAX_MFLY_OBJ){
////            //delete _fly_object[0];
//            _fly_object.pop_front();
//    }
    
    
}

ofVec3f ofApp::arScreenToWorld(ofVec3f screen_pos){
    
    ofVec4f pos = ARCommon::screenToWorld(screen_pos,_camera_projection,_camera_viewmatrix);
    
    // build matrix for the anchor
    matrix_float4x4 translation = matrix_identity_float4x4;
    
    translation.columns[3].x = pos.x;
    translation.columns[3].y = pos.y;
    translation.columns[3].z = screen_pos.z;
    matrix_float4x4 transform = matrix_multiply(session.currentFrame.camera.transform,translation);
    return ARCommon::toMat4(transform).getTranslation();
    
}
void ofApp::updateFlyCenter(){
    
    float flyz_=-1+sin(ofGetFrameNum()/120.0)*2;
    ofVec3f center_=arScreenToWorld(ofVec3f(_ww/2,_wh/2,flyz_));
    ofVec3f camera_pos=processor->getCameraPosition();
    
    ofVec3f dir_=center_-camera_pos;
    dir_.rotate(90*sin(ofGetFrameNum()/50.0), ofVec3f(0,0,1));
    
    ofVec3f vel_=(camera_pos+dir_)-DFlyObject::cent;
    vel_.normalize();
    vel_*=DFlyObject::maxForce/2.0;
    
    DFlyObject::cent+=vel_;
    
}

void ofApp::addTouchTrajectory(){
    
    if(_touched){
        
        _prev_touch.push_back(_touch_point);
        
        if(_prev_touch.size()<MTOUCH_SMOOTH) return;
        
        ofVec2f average_(0);//_prev_touch[MTOUCH_SMOOTH-1];
        float m=MTOUCH_SMOOTH;
        for(int i=0;i<m;++i){
            average_+=_prev_touch[i]/m;
        }
        
//        processor->addAnchor(ofVec3f(average_.x,average_.y,-1));
//        ARObject anchor=processor->anchorController->getAnchorAt(processor->anchorController->getNumAnchors()-1);
//        ofVec3f pos=anchor.modelMatrix.getTranslation();
        ofVec3f pos=arScreenToWorld(ofVec3f(average_.x,average_.y,-1));
//        ofLog()<<pos;
        _record_object->addSegment(pos);
        
//        if(_record_object_side!=nil){
//            ofVec3f offset_(0,ofRandom(-1,1),ofRandom(-3,3));
//            offset_*=DObject::rad*.2;
//            
//            _record_object_side->addSegment(pos+offset_);
//        }
        
//        processor->anchorController->removeAnchor(anchor.getUUID());
        
        if(_prev_touch.size()>m) _prev_touch.erase(_prev_touch.begin());
    }
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofEnableAlphaBlending();
    
    ofDisableDepthTest();
    
    drawCameraView();
   //_camera_view.draw(0, 0,ofGetWidth(),ofGetHeight());
    
    ofEnableDepthTest();
    
    
    cam.begin();
    processor->setARCameraMatrices();
    
    

    //_camera_view.bind();
    _shader_mapscreen.begin();
    _shader_mapscreen.setUniformTexture("inputImageTexture", _camera_view, 0);
//    _shader_mapscreen.setUniform1f("window_width", ofGetWidth()*10.0);
//    _shader_mapscreen.setUniform1f("window_height", ofGetHeight()*2.0);
    _shader_mapscreen.setUniform1f("frame_count", ((float)ofGetFrameNum()/150.0));
//
    for(auto& p:_feature_object)
        if(p->_shader_fill) p->draw();
    for(auto& p:_fly_object)
        if(p->_shader_fill) p->draw();
//
    _shader_mapscreen.end();
//
    _camera_view.bind();
//
    for(auto& p:_feature_object)
        if(!p->_shader_fill) p->draw();

    for(auto& p:_fly_object)
        if(!p->_shader_fill) p->draw();
//
    _camera_view.unbind();
    
    
    
   
    
    if(_stage>0 && _stage<4){
        ofPushStyle();
        for(auto&p:_detect_feature){
            ofSetColor(255,255,0,100+150*sin(ofGetFrameNum()/10.0+p.x*1000*TWO_PI));
//            ofSetColor(255,255,0);
            ofDrawSphere(p.x,p.y,p.z,0.001);
        }
        ofPopStyle();
    }
    
    
    
    cam.end();
    
    
    ofDisableDepthTest();

    
    _uiview->draw(_song_time);
    
}

//--------------------------------------------------------------
void ofApp::exit(){
    [_song release];
    _song=nil;
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    
    if(_uiview->checkTouch(ofPoint(touch.x,touch.y))) return;
    
    
    _touched=true;
    _touch_point.x=touch.x;
    _touch_point.y=touch.y;
    
    DZigLine* rec_;
//    DSandLine* sand_;
    switch(_stage){
        case 1:
            break;
        case 2:
            rec_=new DZigLine();
            _feature_object.push_back(shared_ptr<DObject>(rec_));
            _record_object=_feature_object.back();
            
//            if(ofRandom(3)<1){
//                sand_=new DSandLine();
//                _feature_object.push_back(shared_ptr<DObject>(sand_));
//                _record_object_side=_feature_object.back();
//            }else{
//                _record_object_side.reset();
//            }
            break;
//        case 3:
//            rec_=new DSandLine();
//            _feature_object.push_back(shared_ptr<DObject>(rec_));
//            _record_object=_feature_object.back();
//            break;
//        case 4:
//            rec_=ofRandom(2)<1?new DSandLine():new DZigLine();
//            _feature_object.push_back(shared_ptr<DObject>(rec_));
//            _record_object=_feature_object.back();
//            break;
    }
   
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    
    if(_uiview->checkTouch(ofPoint(touch.x,touch.y))) return;
    
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
    
    
    
    

    if(_shader_threshold<=0){
        processor->draw();

    }else{

       
       
        _fbo_tmp1.begin();
        _shader_gray.begin();
        _shader_gray.setUniformTexture("inputImageTexture", _camera_view, 0);
        _camera_view.draw(0, 0, _ww, _wh);
        _shader_gray.end();
        _fbo_tmp1.end();

        _fbo_tmp2.begin();
        _shader_blur.begin();
        _shader_blur.setUniformTexture("inputImageTexture", _fbo_tmp1.getTexture(), 0);
        _fbo_tmp1.draw(0, 0, _ww, _wh);
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
        
        _shader_sobel.setUniformTexture("inputImageTexture", _fbo_tmp2.getTexture(), 0);
//        _shader_sobel.setUniform1f("window_width", ww);
//        _shader_sobel.setUniform1f("window_height", wh);
        _shader_sobel.setUniform1f("show_threshold", _shader_threshold);
        _shader_sobel.setUniform1f("sobel_threshold", _sobel_threshold);
        if(_shader_threshold<1.0) _shader_sobel.setUniformMatrix4f("particlePos", _screen_flow.getParticleMat());
        

        _camera_view.draw(0, 0, _ww,_wh);
        //window_.draw();

        _shader_sobel.end();
        _fbo_tmp1.end();

        _fbo_tmp1.draw(0,0,_ww,_wh);
        
//        _shader_mapscreen.begin();
//        _shader_mapscreen.setUniformTexture("inputImageTexture", _camera_view, 0);
//        _shader_mapscreen.setUniform1f("window_width", ofGetWidth()*10.0);
//        _shader_mapscreen.setUniform1f("window_height", ofGetHeight()*2.0);
//        _shader_mapscreen.setUniform1f("show_threshold", _shader_threshold);
//        _shader_mapscreen.setUniform1f("sobel_threshold", _sobel_threshold);
//
//        _camera_view.draw(0,0,ww,wh);
//
//        _shader_mapscreen.end();
        
        //processor->draw();

        //_screen_flow.draw();
        
    
    
    }
//
    
    
}

void ofApp::reset(){
    ofLog()<<"reset scene!";
    
    if(processor->anchorController!=nil){
        
        processor->anchorController->clearAnchors();
        processor->restartSession();
    }
    //processor->anchorController->clearPlaneAnchors();
    
    //processor->restartSession();
    //[session runWithConfiguration:session.configuration options:ARSessionRunOptionResetTracking|ARSessionRunOptionRemoveExistingAnchors];
    
    _detect_feature.clear();
    _feature_object.clear();
    _fly_object.clear();
//    _static_object.clear();
//    _record_object.clear();
    
    setStage(0);
    _uiview->setPlay(false);
    
    _ipiano=1;
    _idot=1;
    _irain=1;
    
}

// ======================== BUTTON ======================== //
void ofApp::resetButton(){
  
    reset();
}

void ofApp::setPlay(int& play_){
    if(play_==1){
      [_song play];
        //processor->restartSession();
    }else{
      [_song pause];
      //processor->pauseSession();
    }
}
void ofApp::setSongTime(int& time_){
    [_song positionMs:time_];
    for(int i=0;i<MSTAGE-1;++i){
        if(time_>=_stage_time[i] && time_<_stage_time[i+1]) _stage=i;
    }
    
}


void ofApp::nextStage(){
    
    setStage(_stage+1);
}
void ofApp::prevStage(){
    
    if(_stage==1) reset();
    else setStage(_stage-1);
    
}
void ofApp::setStage(int set_){
    
    if(set_>=MSTAGE|| set_<0) return;
    
   
    //[_song play];
    
//    [_song setCurrentTime:_stage_time[set_]];
    [_song positionMs:_stage_time[set_]];
    _stage=set_;
    
    float s=_ww/10000.0;
    
    switch(_stage){
        case 0:
            //reset();
            _shader_threshold=0;
            break;
        case 1:
            _ipiano=1;
            _idot=1;
            _irain=1;
            break;
        case 3:
            shuffleFeature();
            _fly_object.clear();
            DFlyObject::maxForce=.1*s;
            DFlyObject::maxSpeed=6*s;
            break;
        case 4:
            DFlyObject::maxForce=.2*s;
            DFlyObject::maxSpeed=8*s;
            break;
        case 5:
            DFlyObject::maxForce=.5*s;
            DFlyObject::maxSpeed=20*s;
            break;
        case 6:
            _feature_object.clear();
            _fly_object.clear();
            break;
    }
    _uiview->setHint(_stage);
    

}
void ofApp::shuffleFeature(){
    
    //TODO
    
}

ofVec3f ofApp::findNextInChain(ofVec3f this_,ofVec3f dir_){
    
//    auto it=_detect_feature.begin();
//    float ang_=ofRandom(TWO_PI);
//
//    while(it!=_detect_feature.end()){
//
//        if(abs(it->angleRad(this_))<HALF_PI/8 && it->distance(this_)<DObject::rad){
//
//            _detect_feature.erase(it);
//            return *it;
//
//        }else
//            it++;
//
//    }
//    return ofVec3f(0);
    
    
   
    dir_.rotate(ofRandom(-60,60),ofVec3f(0,1,0));
    return this_+dir_*ofRandom(.8,2);

}


list<ofVec3f> ofApp::getFeatureChain(ofVec3f loc_,int len_){
    
    list<ofVec3f> chain_;
    if(_detect_feature.size()<1) return chain_;
    
    ofVec3f last_=loc_;
    chain_.push_back(last_);
    
    
    ofVec3f dir_(DObject::rad,0,0);
//    dir_.rotate(ofRandom(-20,20),ofVec3f(0,1,0));
    
    for(int i=0;i<len_-1;++i){
        
        auto p=findNextInChain(last_,dir_);
        if(p==ofVec3f(0)) break;
        
        chain_.push_back(p);
        last_=p;
    }
    ofLog()<<"find "<<len_<<" chian of "<<chain_.size();
    
    return chain_;
    
}

void ofApp::loadEffectTime(){
    _stage_time[0]=0;
    _stage_time[1]=63115;
    _stage_time[2]=151553;
    _stage_time[3]=202912;
    _stage_time[4]=234312;
    _stage_time[5]=272936;
    _stage_time[6]=291082;
    
    _piano_time[0]=0;
    _piano_time[1]=88420;
    _piano_time[2]=91981;
    _piano_time[3]=94718;
    _piano_time[4]=101091;
    
    _piano_time[5]=104171;
    _piano_time[6]=104568;
    _piano_time[7]=107334;
    _piano_time[8]=113688;
    _piano_time[9]=116805;
    
    _piano_time[10]=118035;
    _piano_time[11]=119977;
    _piano_time[12]=126331;
    _piano_time[13]=132593;
    _piano_time[14]=138910;
    
    _piano_time[15]=145254;
    _piano_time[16]=151571;
    _piano_time[17]=154697;
    
    
}
