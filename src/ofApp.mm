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
    _song_time=0;
    
    _shader_threshold=0;
    _sobel_threshold=.5;
    
    _screen_flow=DFlow(_shader_threshold);
    

    _uiview=new DUIView(334737);
    ofAddListener(_uiview->_event_play, this, &ofApp::setPlay);
    //ofAddListener(_uiview->_event_time, this, &ofApp::setSongTime);
    
    
    _audio_data=new PAudioData("sample");
    
    reset();
    
//    _shader_threshold=1.0;
//    _sobel_threshold=.7;
//
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
    
    _amp_vibe=_audio_data->readData((float)_song_time);
    
//    [_song.player updateMeters];
//    ofLog()<<powf(10, (0.05 * [_song.player averagePowerForChannel:1]));
    
    
    _song_time=_song.positionMs;
    
    
    _dmillis=ofGetElapsedTimeMillis()-_last_millis;
    _last_millis+=_dmillis;
    
    //// update camera ////
    auto cam_matrix=processor->getCameraMatrices();
    ofMatrix4x4 model = ARCommon::toMat4(session.currentFrame.camera.transform);
    _camera_projection=cam_matrix.cameraProjection;
    _camera_viewmatrix=model*cam_matrix.cameraView;
    
//    return;
    
    
    if(_stage<MSTAGE-1 && _song_time>=_stage_time[_stage+1]) _stage++;
    
    /* add piano piece */
    if(_ipiano<MPIANO){
        if(_song_time>=_piano_time[_ipiano]){
            ofLog()<<"add effect!";
            if(_ipiano>5){
                if(_detect_feature.size()>0){
                    addARPiece(_detect_feature.front());
                    _detect_feature.pop_front();
                }
            }
            if(_stage==1) updateFeaturePoint();
            _ipiano++;
            
        }
    }
    if(_irain<MRAIN){
        if(_song_time>=_rain_time[_irain]){
            ofLog()<<"add rain!";
            if(_detect_feature.size()>0){
                addARParticle(_detect_feature.front());
                _detect_feature.pop_front();
            }
            _irain++;
            
        }
    }else{
        if(_stage<3 && ofRandom(30)<1){
            ofLog()<<"add rain!";
            if(_detect_feature.size()>0){
                addARParticle(_detect_feature.front());
                _detect_feature.pop_front();
            }
        }
    }
    
    switch(_stage){
        case 0:
            _shader_threshold=ofMap(_song_time,0,_stage_time[1],0,.7);
            _screen_flow.update(_shader_threshold,ofxAccelerometer.getForce());
            return;
        case 1: // auto add line
            _shader_threshold=1.0;
            _sobel_threshold=.5;
            
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
            _sobel_threshold=1.0-.8*abs(sin(ofGetFrameNum()/10.0*TWO_PI+ofRandom(-5,5)));
            _sobel_threshold*=ofClamp(ofMap(_amp_vibe,.2,.8,1,0),.3,1);
            ofLog()<<_amp_vibe<<" "<<_sobel_threshold;
            
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

void ofApp::updateFeaturePoint(){
    
    auto pts_=processor->pointCloud.getPoints(this->session.currentFrame);
    pts_.resize(MAX_MDETECT/5);
    //random_shuffle(pts_.begin(), pts_.end());
    _detect_feature.insert(_detect_feature.begin(),pts_.begin(),pts_.end());
    if(_detect_feature.size()>MAX_MDETECT) _detect_feature.resize(MAX_MDETECT);
    
}

void ofApp::addARPiece(ofVec3f loc_){
    int last=-1;//ofRandom(2)<1?-1:floor(ofRandom(2000,1000));
    _feature_object.push_back(shared_ptr<DObject>(new DPiece(loc_,last)));
    if(ofRandom(3)<1){
        int m=floor(ofRandom(1,4));
        for(int i=0;i<m;++i){
        ofVec3f offset_(ofRandom(-1,1));
        offset_*=DObject::rad/10;
        _feature_object.push_back(shared_ptr<DObject>(new DPieceEdge(loc_+offset_,last)));
        }
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
    
    float flyz_=-1+(_stage<4?0:sin(ofGetFrameNum()/120.0)*2);
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
    //ofSetBackgroundColor(0);
    drawCameraView();
   //_camera_view.draw(0, 0,ofGetWidth(),ofGetHeight());
    
    ofEnableDepthTest();
    
//    return;
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
    
    if(_stage>0){
        ofPushStyle();
        float a_=ofClamp(ofMap(_amp_vibe,.7,1,0,1),.1,1);
        float t_=ofGetFrameNum()/(80-40.0*a_);
        //ofLog()<<a_;
        
        ofVec3f p2;
        for(auto it=_detect_feature.begin();it!=_detect_feature.end();++it){
            auto p=*it;
           ofSetColor(255,255,0,a_*(150+100*sin((t_+p.x*50)*TWO_PI)));
            ofDrawSphere(p.x,p.y,p.z,0.001);
            
//            if(a_>.8 && ofRandom(20)<1){
//                if(p.distance(p2)<=DObject::rad/2) ofDrawLine(p2.x,p2.y,p2.z,p.x,p.y,p.z);
//            }
            p2=p;
        }
        ofPopStyle();
    }
    
   
    
    
    cam.end();
    
    
    ofDisableDepthTest();

    _uiview->draw(_song_time);
//    ofPushStyle();
//    ofSetColor(255,255,0);
//    ofDrawRectangle(0, _wh/2,_amp,5);
//    ofPopStyle();
    //_audio_data->draw();

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
    
    _amp_vibe=0;
    
}

// ======================== BUTTON ======================== //
void ofApp::resetButton(){
  
    _feature_object.clear();
    if(_stage!=1) setStage(1);
    ofVec3f pos=arScreenToWorld(ofVec3f(ofGetWidth()/2,ofGetHeight()/2,-1));
    addARPiece(pos);
    
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
    
    
    int arr_[MPIANO+1]={0,63165,69489,75801,79351,82131,
    88432,92004,94736,101103,104215,
    104651,107382,113709,116896,118047,
    119954,126337,132581,138916,145298,
    151608,154780,157897,161069,164256,
    165046,167373,168204,170563,171345,
    173710,174481,176869,177653,180030,
        180811,183152,183956,186313,187116};
    
    for(int i=0;i<MPIANO;++i) _piano_time[i]=arr_[i];
    
    
    int arr2_[MRAIN+1]={0,113653,114463,115266,119982,120593,
        123585,123973,124370,124941,125141,125341,125538};
    for(int i=0;i<MRAIN;++i) _rain_time[i]=arr2_[i];
    
}
