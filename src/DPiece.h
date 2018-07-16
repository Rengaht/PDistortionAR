//
//  DPiece.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/16.
//

#ifndef DPiece_h
#define DPiece_h


class DPiece:public DObject{
    
    ofMesh _mesh;
    ofVec2f _texture_pos;
    float _phi;
    float _wid;
    
    float _start_pos;
    float _vel;
    
public:
    DPiece(ofVec3f pos):DPiece(pos,-1){}
    DPiece(ofVec3f pos,int last_):DObject(pos,last_){
        _texture_pos=ofVec2f(ofRandom(1),ofRandom(1));
//        _texture_pos=ofVec2f(.5,.5);
        _phi=ofRandom(360);
        _wid=rad*ofRandom(.2,.5);
        
        _start_pos=rad*2;
        _vel=-_start_pos/ofRandom(200,800);
        
        generate();
    }
    void generate(){
        
        
        _mesh.setMode(OF_PRIMITIVE_TRIANGLE_FAN);
        
        _mesh.addVertex(ofPoint(0,0,0));
        _mesh.addTexCoord(_texture_pos);
        
//        float start_=ofRandom(30);
        float ang_=0;//start_;
        float trad_=min(1-_texture_pos.x,_texture_pos.x)*_wid;
        
        while(ang_<=360){
            ofVec3f p(1,0,0);
            p.rotate(ang_,ofVec3f(0,1,0));
            
            _mesh.addVertex(p*_wid);
            _mesh.addTexCoord(ofVec2f(_texture_pos.x+p.x*trad_,_texture_pos.y+p.z*trad_));
            
            ang_+=ofRandom(10,90);
        }
        ofVec3f p(1,0,0);
        _mesh.addVertex(p*_wid);
        _mesh.addTexCoord(ofVec2f(_texture_pos.x+p.x*trad_,_texture_pos.y+p.z*trad_));
        
        //ofLog()<<"create "<<_mesh.getNumVertices()/3<<" triangles";
        
    }
    void draw(){
        
        ofPushStyle();
        ofDisableArbTex();
        
        ofPushMatrix();
        ofTranslate(_loc.x,_loc.y+_start_pos,_loc.z);
        ofRotate(_phi,0,1,0);
        
        //_triangle.triangleMesh.draw();
        _mesh.draw();
        
        ofPopMatrix();
        
        ofPopStyle();
    }
    void update(int dt){
        DObject::update(dt);
        
        if(_start_pos>0) _start_pos+=_vel*dt;
        
        float m=_mesh.getNumVertices();
        float s_;
        for(int i=1;i<m;++i){
            auto p=_mesh.getVertex(i);
            p.y=_wid*ofRandom(-.1,.1);
            
            if(i==1) s_=p.y;
            else if(i==m-1) p.y=s_;
            
            _mesh.setVertex(i,p);
        }
        
        
    }
    vector<DFlyObject*> breakdown(){
        vector<DFlyObject*> _fly;
        
       _fly.push_back(new DFlyObject(_loc,_mesh));

        return _fly;
    }
};


#endif /* DPiece_h */
