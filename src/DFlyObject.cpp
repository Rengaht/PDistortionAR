//
//  DFlyObject.cpp
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/4.
//

#include "DFlyObject.h"

//--------------------------------------------------------------
DFlyObject::DFlyObject(ofVec3f loc_,ofMesh mesh_){
    
    loc=loc_;
    vel=ofVec3f(0);
    acc=ofVec3f(0);
    
    phi=ofRandom(TWO_PI);
    
    _mesh=mesh_;
    
}

//--------------------------------------------------------------
void DFlyObject::draw(){
    
    ofPushStyle();
//    ofSetColor(255,255*sin(phi));
//    ofSetLineWidth(5);
    
    ofPushMatrix();
    ofTranslate(loc);
    
    ofRotate(90,vel.x,vel.y,vel.z);
    
  //      ofDrawSphere(0,0,0,rad);
//    ofBeginShape();
//    ofVertex(0,0,0);
//    for(auto& p:_vertex) ofVertex(p);
//    ofEndShape();
    _mesh.draw();
    
    ofPopMatrix();
    ofPopStyle();
    
}
void DFlyObject::update(){
}

void DFlyObject::updateFlock(list<shared_ptr<DFlyObject>>& others){
    
    flock(others);
    vel+=acc;
    vel.limit(maxSpeed);
    loc+=vel;

    acc*=0;

    
}

//--------------------------------------------------------------

void DFlyObject::flock(list<shared_ptr<DFlyObject>>& others){
    
    ofVec3f sep=separate(others);
    ofVec3f ali=align(others);
    ofVec3f coh=cohesion(others);
    
    sep*=1.5;
    ali*=1.0;
    coh*=1.0;
    
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    
    //center
    ofVec3f cent_desired=cent-loc;
    ofVec3f cent_steer=cent_desired-vel;
    cent_steer.limit(maxForce*2);
    applyForce(cent_steer);
    
}

void DFlyObject::applyForce(ofVec3f force){
    acc+=force;
}

ofVec3f DFlyObject::align(list<shared_ptr<DFlyObject>>& others){
    float neighbor_dist=rad*5;
    ofVec3f sum(0);
    
    for(auto &b:others){
        float d=loc.distance(b->loc);
        if(d>0 && d<neighbor_dist){
            sum+=b->vel;
        }
    }
    sum.normalize();
    sum*=maxSpeed;
    
    ofVec3f steer=sum-vel;
    steer.limit(maxForce);
    return steer;
    
}
ofVec3f DFlyObject::cohesion(list<shared_ptr<DFlyObject>>& others){
    
    float neighbor_dist=rad*3;
    ofVec3f sum;
    int count=0;
    for(auto &b:others){
        float d=loc.distance(b->loc);
        if(d>0 && d<neighbor_dist){
            sum+=b->loc;
            count++;
        }
    }
    if(count>0){
        sum/=count;
        sum.normalize();
        sum*=maxSpeed;
        ofVec3f steer=sum-vel;
        steer.limit(maxForce);
        return steer;
    }
    return ofVec3f(0);
    
    
}
ofVec3f DFlyObject::separate(list<shared_ptr<DFlyObject>>& others){
    
    float desired_separataion=rad*3;
    ofVec3f sum(0);
    int count=0;
    for(auto &b:others){
        float d=loc.distance(b->loc);
        if(d>0 && d<desired_separataion){
            ofVec3f diff=loc-b->loc;
            diff.normalize();
            diff/=d;
            sum+=diff;
            count++;
        }
    }
    if(count>0){
        sum/=count;
        sum.normalize();
        sum*=maxSpeed;
        ofVec3f steer=sum-vel;
        steer.limit(maxForce);
        return steer;
    }
    return ofVec3f(0);
    
}
