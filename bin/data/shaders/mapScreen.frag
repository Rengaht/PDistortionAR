precision highp float;

//uniform sampler2D Sampler;
uniform sampler2D inputImageTexture;
//uniform mat4 particlePos;
uniform float window_width;
uniform float window_height;


varying vec2 texCoord;
//varying vec4 vertexColor;

//float sum;
//float dr;
//float dx;
//float dy;



void main(){
    
//    sum=.0;
//    for(int i=0;i<4;++i){
//        dr=particlePos[i][2];
//        dx=texCoord.x*window_width-particlePos[i][0];
//        dy=(1.0-texCoord.y)*window_height-particlePos[i][1];
//        sum+=dr*dr/(dx*dx+dy*dy);
//    }
//    if(sum>=1.0){
//        vec4 col = texture2D(Sampler, texCoord);
//        gl_FragColor = vec4(col);
//    }else{
        //gl_FragColor = vec4(0.0,0.0,0.0,0.0);
    if(mod(floor(texCoord.x*window_width),5.0)!=0.0){
        gl_FragColor=vec4(0.0);
    }else
        gl_FragColor = texture2D(inputImageTexture, texCoord);
//        gl_FragColor = vec4(0.0,0.0,1.0,1.0);
//        gl_FragColor = vec4(1.0,1.0,1.0,1.0);
    
//    }
}
