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
    
    _effect_time[0]=0;
    _effect_time[1]=65047;
    _effect_time[2]=69835;
    _effect_time[3]=75804;
    _effect_time[4]=79309;
    _effect_time[5]=82121;
    
    _effect_time[6]=88420;
    _effect_time[7]=91990;
    _effect_time[8]=94718;
    _effect_time[9]=101109;
    _effect_time[10]=107352;
    _effect_time[11]=113688;
    
    _ieffect=1;
    
    _song=[[AVSoundPlayer alloc] init];
    [_song loadWithFile:@"music/be.wav"]; // uncompressed wav format.
//    [vocals volume:1.0];
    _stage=-1;
    
    
    int fontSize = 8;
    if (ofxiOSGetOFWindow()->isRetinaSupportedOnDevice())
        fontSize *= 2;
    
    //font.load("fonts/mono0755.ttf", fontSize,true, false, true, 0.4, 72);
    font.load("fonts/mono0755.ttf", fontSize);
    
    
    ofxAccelerometer.setup();
    
    processor = ARProcessor::create(session);
    processor->setup(true);
    
    _fbo_tmp1.allocate(ofGetWidth(),ofGetHeight(),GL_RGB);
    _fbo_tmp2.allocate(ofGetWidth(),ofGetHeight(),GL_RGB);
    
    _shader_gray.load("shaders/grayScale.vert", "shaders/grayScale.frag");
    _shader_blur.load("shaders/blur.vert", "shaders/blur.frag");
    _shader_canny.load("shaders/canny.vert", "shaders/canny.frag");
    _shader_sobel.load("shaders/sobel.vert", "shaders/sobel.frag");
    
    _shader_mapscreen.load("shaders/mapScreen.vert", "shaders/mapScreen.frag");
    
    
    float s=ofGetWidth()/10000.0;
    DFlyObject::maxForce=.2*s;
    DFlyObject::maxSpeed=8*s;
    DFlyObject::rad=1.0*s;
    DFlyObject::cent=ofVec3f(0,0,0);
    
    
    _touched=false;
    
    _last_millis=ofGetElapsedTimeMillis();
    _dmillis=0;
    
    setStage(0);
    
    _shader_threshold=0;
    _sobel_threshold=.5;
    
    _screen_flow=DFlow(_shader_threshold);
    
}

//--------------------------------------------------------------
void ofApp::update(){
    
    if(_stage==0 || _stage==5) processor->updateCamera();
    else processor->update();
    //processor->updatePlanes();
    
    _song_time=_song.positionMs;
    
    
    _dmillis=ofGetElapsedTimeMillis()-_last_millis;
    _last_millis+=_dmillis;
    
    //// update camera ////
    auto cam_matrix=processor->getCameraMatrices();
    ofMatrix4x4 model = ARCommon::toMat4(session.currentFrame.camera.transform);
    _camera_projection=cam_matrix.cameraProjection;
    _camera_viewmatrix=model*cam_matrix.cameraView;
    

    _camera_view=processor->camera->getCameraImage();
    
    
    auto pts_=processor->pointCloud.getPoints(this->session.currentFrame);
    random_shuffle(pts_.begin(), pts_.end());
    
    _detect_feature.insert(_detect_feature.begin(),pts_.begin(),pts_.end());
    if(_detect_feature.size()>MAX_MFEATURE) _detect_feature.resize(MAX_MFEATURE);
    
    
    
    if(_stage<MSTAGE-1 && _song_time>=_stage_time[_stage+1]) _stage++;
    
    switch(_stage){
        case 0:
            _hint="POUR";
            _shader_threshold=ofMap(_song_time,0,_stage_time[1],0,.7);
            _screen_flow.update(_shader_threshold,ofxAccelerometer.getForce());
            break;
        case 1: // auto add line
            _hint="WATCH";
            _shader_threshold=1.0;
            _sobel_threshold=.5;
            if(_detect_feature.size()>0){

                if(_ieffect<MEFFECT){
                    if(_song_time>=_effect_time[_ieffect]) _ieffect++;
                    else break;
                }else{
                    if(ofRandom(20)>1) break;
                }
                ofLog()<<"add effect!";

//                int add_=floor(ofRandom(_detect_feature.size()));

                if(_ieffect>10 && ofRandom(2)<1){
                    for(int i=0;i<ofNoise(_ieffect)*5;++i) addARParticle(*_detect_feature.begin());
                }else{
                        addARPiece(*_detect_feature.begin());
                }
                _detect_feature.pop_front();

            }
            break;
        case 2:
            _hint="DRAW";
            _sobel_threshold=.5;
            _shader_threshold=1.0;
            if(_touched){
                addTouchTrajectory();
            }else{
                if(ofRandom(30)<1 && _detect_feature.size()>0){
                    //int add_=floor(ofRandom(_detect_feature.size()));
                    addARPiece(*_detect_feature.begin());
                    _detect_feature.pop_front();
                }
            }
            break;
        case 3:
            _hint="DRAW & FOLLOW";
            if(_touched){
                addTouchTrajectory();
            }else{
                if(ofRandom(30)<1){
                    addFlyObject();
                }
            }

            _shader_threshold=1+abs(.5*sin(ofGetFrameNum()/30.0*TWO_PI+ofRandom(-2,2)));
            _sobel_threshold=.5;
            updateFlyCenter();

            for(auto& p:_fly_object){
                p->updateFlock(_fly_object);
            }
            break;
        case 4:
            _hint="DRAW & FOLLOW";
            _shader_threshold=1+abs(sin(ofGetFrameNum()/30.0*TWO_PI+ofRandom(-5,5)));
            _sobel_threshold=.8-.6*abs(sin(ofGetFrameNum()/10.0*TWO_PI+ofRandom(-5,5)));
            if(_touched){
                addTouchTrajectory();
               
            }else{
                if(ofRandom(5)<1){
                    if(ofRandom(50)>1) addFlyObject();
                    else{
    //                    int add_=floor(ofRandom(_detect_feature.size()));
                        addARPiece(*_detect_feature.begin());
                        _detect_feature.pop_front();
                    }
                }
            }

            updateFlyCenter();

            for(auto& p:_fly_object){
                p->updateFlock(_fly_object);
            }
            break;
        case 5:
            _hint="STAY";
            
            _shader_threshold=(_song_time==0)?0:ofMap(_song_time,_stage_time[5],_stage_time[6],.8,0);
            _screen_flow.update(_shader_threshold,ofxAccelerometer.getForce());
            _sobel_threshold=.5;
            
            if(ofRandom(10)<1){
                if(_feature_object.size()>0){
                 // delete _feature_object[0];
                  _feature_object.pop_front();
                }
                if(_fly_object.size()>0){
                   // delete _fly_object[0];
                    _fly_object.pop_front();
                }
//                if(_static_object.size()>0) _static_object.erase(_static_object.begin());
//                if(_record_object.size()>0) _record_object.erase(_record_object.begin());
            }
            for(auto& p:_fly_object){
                p->updateFlock(_fly_object);
            }
            if(_song_time==0){
              _shader_threshold=0;
                _feature_object.clear();
                _fly_object.clear();
//                _static_object.clear();
//                _record_object.clear();
            }
            
            break;
    }
    
   
  
   
    for(auto& it:_feature_object) it->update(_dmillis);
    _feature_object.remove_if([](shared_ptr<DObject> obj){return obj->dead();});

    //if(_feature_object.size()>MAX_MFEATURE) _feature_object.resize(MAX_MFEATURE);
    while(_feature_object.size()>MAX_MFEATURE){
      _feature_object.pop_front();
    }
    
}

void ofApp::addARPiece(ofVec3f loc_){
    int last=ofRandom(2)<1?-1:floor(ofRandom(2000,1000));
    if(ofRandom(2)<1){
        _feature_object.push_back(shared_ptr<DObject>(new DPiece(loc_,last)));
    }else{
        _feature_object.push_back(shared_ptr<DObject>(new DPieceEdge(loc_,last)));
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
    int index_=floor(ofRandom(_feature_object.size()));
    
    for(int i=0;i<index_;++i) it++;

    auto pt=(*it)->breakdown();

    if(pt.size()<1){
       // delete _feature_object[index_];
        _feature_object.erase(it);
//        _feature_object.pop_front();
        return;
    }
    _fly_object.insert(_fly_object.end(),pt.begin(),pt.end());

    ofLog()<<"break down to "<<pt.size()<<" flyobjects!";


//    random_shuffle(_fly_object.begin(),_fly_object.end());
    
//    if(_fly_object.size()>MAX_MFLY_OBJ) _fly_object.resize(MAX_MFLY_OBJ);
    while(_fly_object.size()>MAX_MFLY_OBJ){
//            //delete _fly_object[0];
            _fly_object.pop_front();
    }
    
    
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
    ofVec3f center_=arScreenToWorld(ofVec3f(ofGetWidth()/2,ofGetHeight()/2,flyz_));
    ofVec3f camera_pos=processor->getCameraPosition();
    
    ofVec3f dir_=center_-camera_pos;
    dir_.rotate(90*sin(ofGetFrameNum()/50.0), ofVec3f(0,0,1));
    
    ofVec3f vel_=(camera_pos+dir_)-DFlyObject::cent;
    vel_.normalize();
    vel_*=DFlyObject::maxForce/2.0;
    
    DFlyObject::cent+=vel_;
    
}

void ofApp::addTouchTrajectory(){
    
    //TODO: smooth!
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
        _record_object->addSegment(pos);
        
//        processor->anchorController->removeAnchor(anchor.getUUID());
        
        if(_prev_touch.size()>m) _prev_touch.erase(_prev_touch.begin());
    }
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofEnableAlphaBlending();
    
    ofDisableDepthTest();
    
    drawCameraView();
//    _camera_view.draw(0, 0,ofGetWidth(),ofGetHeight());
    
    ofEnableDepthTest();
    
    
    cam.begin();
    processor->setARCameraMatrices();
    
    

    _shader_mapscreen.begin();
    _shader_mapscreen.setUniformTexture("inputImageTexture", _camera_view, 0);
    _shader_mapscreen.setUniform1f("window_width", ofGetWidth()*10.0);
    _shader_mapscreen.setUniform1f("window_height", ofGetHeight()*2.0);
    _shader_mapscreen.setUniform1f("frame_count", ((float)ofGetFrameNum()/150.0));
//
    for(auto& p:_feature_object)
        if(p->_shader_fill) p->draw();
//
//
    _shader_mapscreen.end();
//
    _camera_view.bind();
//
    for(auto& p:_feature_object)
        if(!p->_shader_fill) p->draw();

    for(auto& p:_fly_object) p->draw();
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
    // ========== DEBUG STUFF ============= //
    int p = ofGetHeight() * 0.035;
    
//    font.drawString("stage       = " + ofToString(_stage),    x, y+=p);
    font.drawString(ofToString(floor(_song_time/60000))+"-"+ofToString(floor((_song_time/1000)%60))+"-"+ofToString(_song_time%1000)
                                +"|"+ofToString(ofGetFrameRate()),p/2,p);
//    font.drawString(ofToString( ofGetFrameRate() ),p/2,p*2);
//    font.drawString("state       = " + ofToString(processor->camera->getTrackingState()),x, y+=p);

    if(processor->camera->getTrackingState()!=2){
      _hint="!!! bad tracking state !!!";
    }else{
        if(ofGetFrameNum()%120<60) _hint="////// "+_hint+" //////";
        else _hint="\\\\\\\\\\\\ "+_hint+" \\\\\\\\\\\\";
    }
    ofRectangle rec_=font.getStringBoundingBox(_hint,0,0);
    font.drawString(_hint,ofGetWidth()/2-rec_.width/2, ofGetHeight()/2-rec_.height/2);
    
    
//    font.drawString("#feature obj= " + ofToString(_feature_object.size()),x, y+=p);
//    font.drawString("#static obj = " + ofToString(_static_object.size()),x, y+=p);
//    font.drawString("#record obj = " + ofToString(_record_object.size()),x, y+=p);

    //font.drawString("#point cloud= " + ofToString(processor->pointCloud.getNumFeatures()),x, y+=p);
    //font.drawString("#plane      = " + ofToString(processor->anchorController->getNumPlanes()),x, y+=p);
    //font.drawString("#anchor     = " + ofToString(processor->anchorController->getNumAnchors()),x, y+=p);
    
    
    
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
    
    DZigLine* rec_;
    switch(_stage){
        case 1:
            break;
        case 2:
            rec_=new DZigLine();
            _feature_object.push_back(shared_ptr<DObject>(rec_));
            _record_object=_feature_object.back();
            break;
        case 3:
            rec_=new DSandLine();
            _feature_object.push_back(shared_ptr<DObject>(rec_));
            _record_object=_feature_object.back();
            break;
        case 4:
            rec_=ofRandom(2)<1?new DSandLine():new DZigLine();
            _feature_object.push_back(shared_ptr<DObject>(rec_));
            _record_object=_feature_object.back();
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
    
    
    float ww=ofGetWidth();
    float wh=ofGetHeight();
    
    

    if(_shader_threshold<=0){
        processor->draw();

    }else{

       
       
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
        
        _shader_sobel.setUniformTexture("inputImageTexture", _fbo_tmp2.getTexture(), 0);
        _shader_sobel.setUniform1f("window_width", ww);
        _shader_sobel.setUniform1f("window_height", wh);
        _shader_sobel.setUniform1f("show_threshold", _shader_threshold);
        _shader_sobel.setUniform1f("sobel_threshold", _sobel_threshold);
        if(_shader_threshold<1.0) _shader_sobel.setUniformMatrix4f("particlePos", _screen_flow.getParticleMat());
        

        _camera_view.draw(0, 0, ww,wh);
        //window_.draw();

        _shader_sobel.end();
        _fbo_tmp1.end();

        _fbo_tmp1.draw(0,0,ww,wh);
        
//        _shader_mapscreen.begin();
//        _shader_mapscreen.setUniformTexture("inputImageTexture", _camera_view, 0);
//        _shader_mapscreen.setUniform1f("window_width", ofGetWidth()*10.0);
//        _shader_mapscreen.setUniform1f("window_height", ofGetHeight()*2.0);
//        _shader_mapscreen.setUniform1f("frame_count", ((float)ofGetFrameNum()/12s0.0));
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
    
    _feature_object.clear();
    _fly_object.clear();
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
    
    float s=ofGetWidth()/10000.0;
    
    switch(_stage){
        case 0:
            reset();
            break;
        case 1:
            _ieffect=1;
            break;
        case 3:
            _fly_object.clear();
            DFlyObject::maxForce=.1*s;
            DFlyObject::maxSpeed=6*s;
            break;
        case 4:
            DFlyObject::maxForce=.2*s;
            DFlyObject::maxSpeed=8*s;
            break;
    }
    

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

//void ofApp::toggleShader(){
//    _use_shader=!_use_shader;
//}
//
//void ofApp::toggleDFlyObject(){
//    _update_object=!_update_object;
//}
