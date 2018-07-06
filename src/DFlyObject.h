//
//  DFlyObject.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/4.
//

#ifndef DFlyObject_h
#define DFlyObject_h
#include "ofMain.h"

class DFlyObject{
private:
    
    //==== flocking ====//
    void flock(vector<DFlyObject*>& others);
    void applyForce(ofVec3f force);
    ofVec3f align(vector<DFlyObject*>& others);
    ofVec3f cohesion(vector<DFlyObject*>& others);
    ofVec3f seperate(vector<DFlyObject*>& others);
    
    
public:

    ofVec3f loc,vel,acc;
    static float rad,maxForce,maxSpeed,boundary;
    static ofVec3f cent;
    
    float phi;
    
    DFlyObject();
    DFlyObject(float x,float y,float z);
    
    virtual void draw();
//    void drawTextureBox(ofTexture tex_);
    virtual void update();
    void updateFlock(vector<DFlyObject*>& others);
    
    
    
};



#endif /* DFlyObject_h */
