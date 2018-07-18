//
//  DPieceEdge.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/17.
//

#ifndef DPieceEdge_h
#define DPieceEdge_h


class DPieceEdge:public DObject{
    
    ofMesh _mesh;
    ofVec2f _texture_pos;
    float _texture_rad;
    
    float _phi;
    float _wid;
    
    float _start_pos;
    float _vel;
    float _turn;
    
public:
    
    DPieceEdge(ofVec3f pos):DPieceEdge(pos,-1){}
    DPieceEdge(ofVec3f pos,int last_):DObject(pos,last_){
        _texture_pos=ofVec2f(ofRandom(.2,.8),ofRandom(.2,.8));
        
        _texture_rad=min(min(_texture_pos.x,1-_texture_pos.x),min(_texture_pos.y,1-_texture_pos.y))/3.0;
        
        //        _texture_pos=ofVec2f(.5,.5);
        _phi=ofRandom(360);
        _wid=rad*ofRandom(.5,.8);
        
        _start_pos=_wid*ofRandom(10,20);
        _vel=-_start_pos/ofRandom(200,400);
        
        _turn=ofRandom(1,2.5);
        _shader_fill=true;
        
        generate();
    }
    void generate(){
        
        
        //_mesh.setMode(OF_PRIMITIVE_LINE_STRIP);
        _mesh.setMode(OF_PRIMITIVE_TRIANGLE_STRIP);
        
        float start_=ofRandom(90);
        float ang_=start_;
        
    
        while(ang_<=360*_turn){
            ofVec3f p(1,0,0);
            p.rotate(ang_,ofVec3f(0,1,0));
            p*=ofRandom(.8,1.2);
            p.y+=_wid/5*ofNoise(p.x);
            
            _mesh.addVertex(p*_wid);
            _mesh.addVertex(p*_wid+ofVec3f(0,_wid/8.0*ofNoise(p.z),0));
            
//            _mesh.addTexCoord(ofVec2f(_texture_pos.x+p.x*_texture_rad,_texture_pos.y+p.z*_texture_rad));
//            _mesh.addTexCoord(ofVec2f(_texture_pos.x+p.x*_texture_rad,_texture_pos.y+p.z*_texture_rad));

            _mesh.addTexCoord(ofVec2f(_texture_pos.x+_texture_rad*ang_/360/_turn,_texture_pos.y));
            _mesh.addTexCoord(ofVec2f(_texture_pos.x+_texture_rad*ang_/360/_turn,_texture_pos.y));
            
            
//            _mesh.addColor(ofColor(ofRandom(255),ofRandom(255),ofRandom(255)));
            
            ang_+=ofRandom(10,80);
        }
//        ofVec3f p(1,0,0);
//        _mesh.addVertex(p*_wid);
//        _mesh.addTexCoord(ofVec2f(_texture_pos.x+p.x*trad_,_texture_pos.y+p.z*trad_));
        
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
        for(int i=0;i<m;i+=2){
            auto p=_mesh.getVertex(i);
            p.y=_wid/5*ofNoise(p.x)+_wid*ofRandom(-.1,.1);

            _mesh.setVertex(i,p);
            p.y+=_wid/8.0*ofNoise(p.z);
            _mesh.setVertex(i+1,p);
            
        }

        
    }
    vector<DFlyObject*> breakdown(){
        vector<DFlyObject*> _fly;
        
        int m=_mesh.getNumVertices();
        for(int i=0;i<m-1;i++){
            ofMesh mesh_;
            mesh_.setMode(OF_PRIMITIVE_LINES);
            
            ofVec3f loc=_mesh.getVertex(i);
            mesh_.addVertex(_mesh.getVertex(i)-loc);
            mesh_.addVertex(_mesh.getVertex(i+1)-loc);
            mesh_.addTexCoord(_mesh.getTexCoord(i));
            mesh_.addTexCoord(_mesh.getTexCoord(i+1));
            
            
            _fly.push_back(new DFlyObject(_loc,mesh_));
            
        }
        return _fly;
    }
};


#endif /* DPieceEdge_h */
