//
//  DPool.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/5.
//

#ifndef DPool_h
#define DPool_h

#include "DObject.h"


class DPool:public DObject{
    
    ofMesh _mesh;
    
    public:
    
    DPool(ofVec3f loc_,float last_):DObject(loc_,last_){
        generateMesh();
    }
    void generateMesh(){
        
        int m=ofRandom(6,20);
        float r=DObject::rad*ofRandom(.8,1.2);
        
        _mesh.setMode(OF_PRIMITIVE_LINE_STRIP);
        float tpos=ofRandom(1);
        for(int i=0;i<m;++i){
            _mesh.addVertex(ofVec3f(r*i+r*ofRandom(-.4,.4),rad+r*ofRandom(-.4,.4),rad+r*ofRandom(-.4,.4)));
            _mesh.addTexCoord(ofVec2f(tpos,(float)i/m));
        }
        
        
        
//        float eang=TWO_PI/floor(ofRandom(3,5));
//        vector<float> corner;
//        float ang=0;
//        while(ang<TWO_PI){
//            corner.push_back(ang);
//            ang+=ofRandom(.8,1.2)*eang;
//        }
//
//        int mcorner=corner.size();
//        float r=DObject::rad*ofRandom(.8,1.2);
//
//        float tx=ofRandom(.2,.8);
//        float ty=ofRandom(.2,.8);
//
//        _mesh.setMode(OF_PRIMITIVE_TRIANGLES);
//        //top
//        for(int i=0;i<mcorner;++i){
//            _mesh.addVertex(ofVec3f(0,0,0));
//            _mesh.addVertex(ofVec3f(r*sin(corner[i]),r*cos(corner[i]),0));
//            _mesh.addVertex(ofVec3f(r*sin(corner[(i+1)%mcorner]),r*cos(corner[(i+1)%mcorner]),0));
//
//            _mesh.addTexCoord(ofVec2f(tx,ty));
//            _mesh.addTexCoord(ofVec2f(tx+.5*sin(corner[i]),ty+.5*cos(corner[i])));
//            _mesh.addTexCoord(ofVec2f(tx+.5*sin(corner[(i+1)%mcorner]),ty+.5*cos(corner[(i+1)%mcorner])));
//
//
//        }
//        //wall
//        for(int i=0;i<mcorner;++i){
//            _mesh.addVertex(ofVec3f(r*sin(corner[i]),r*cos(corner[i]),0));
//            _mesh.addVertex(ofVec3f(r*sin(corner[(i+1)%mcorner]),r*cos(corner[(i+1)%mcorner]),0));
//            _mesh.addVertex(ofVec3f(r*sin(corner[(i+1)%mcorner]),r*cos(corner[(i+1)%mcorner]),r));
//
//
//            float ts=corner[i]/TWO_PI;
//            float td=corner[(i+1)%mcorner]/TWO_PI;
//
//            _mesh.addTexCoord(ofVec2f(tx+ts,ty+0));
//            _mesh.addTexCoord(ofVec2f(tx+td,ty+0));
//            _mesh.addTexCoord(ofVec2f(tx+td,ty+1));
//
//            _mesh.addVertex(ofVec3f(r*sin(corner[(i+1)%mcorner]),r*cos(corner[(i+1)%mcorner]),r));
//            _mesh.addVertex(ofVec3f(r*sin(corner[(i)%mcorner]),r*cos(corner[(i)%mcorner]),r));
//            _mesh.addVertex(ofVec3f(r*sin(corner[i]),r*cos(corner[i]),0));
//
//            _mesh.addTexCoord(ofVec2f(tx+td,ty+1));
//            _mesh.addTexCoord(ofVec2f(tx+ts,ty+1));
//            _mesh.addTexCoord(ofVec2f(tx+ts,ty+0));
//
//        }
//        //bottom
//        for(int i=0;i<mcorner;++i){
//            _mesh.addVertex(ofVec3f(0,0,r));
//            _mesh.addVertex(ofVec3f(r*sin(corner[i]),r*cos(corner[i]),r));
//            _mesh.addVertex(ofVec3f(r*sin(corner[(i+1)%mcorner]),r*cos(corner[(i+1)%mcorner]),r));
//
//            _mesh.addTexCoord(ofVec2f(tx,.5));
//            _mesh.addTexCoord(ofVec2f(tx+.5*sin(corner[i]),ty+.5*cos(corner[i])));
//            _mesh.addTexCoord(ofVec2f(tx+.5*sin(corner[(i+1)%mcorner]),ty+.5*cos(corner[(i+1)%mcorner])));
//
//        }
        
    }
    
    void draw(){
        ofPushStyle();
        ofSetLineWidth(10);
        
        ofPushMatrix();
        ofTranslate(_loc);
        //ofRotate(90,vel.x,vel.y,vel.z);
            _mesh.draw();
        ofPopMatrix();
        
        ofPopStyle();
        
    }
    
    
    
    
};



#endif /* DPool_h */
