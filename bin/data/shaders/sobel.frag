precision highp float;

vec2 textureCoordinate;
vec2 leftTextureCoordinate;
vec2 rightTextureCoordinate;

vec2 topTextureCoordinate;
vec2 topLeftTextureCoordinate;
vec2 topRightTextureCoordinate;

vec2 bottomTextureCoordinate;
vec2 bottomLeftTextureCoordinate;
vec2 bottomRightTextureCoordinate;

//uniform sampler2D originTexture;
uniform sampler2D Sampler;
uniform sampler2D inputImageTexture;
uniform float window_width;
uniform float window_height;

uniform mat4 particlePos;
//uniform float show_angle;
//uniform vec2 force_vector;

uniform float show_threshold;
uniform float sobel_threshold;

varying vec2 texCoord;

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

float cnoise(vec2 P){
    vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
    vec4 ix = Pi.xzxz;
    vec4 iy = Pi.yyww;
    vec4 fx = Pf.xzxz;
    vec4 fy = Pf.yyww;
    vec4 i = permute(permute(ix) + iy);
    vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
    vec4 gy = abs(gx) - 0.5;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;
    vec2 g00 = vec2(gx.x,gy.x);
    vec2 g10 = vec2(gx.y,gy.y);
    vec2 g01 = vec2(gx.z,gy.z);
    vec2 g11 = vec2(gx.w,gy.w);
    vec4 norm = 1.79284291400159 - 0.85373472095314 *
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));
    vec2 fade_xy = fade(Pf.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}


void main(){
    textureCoordinate = texCoord;
    
    vec2 dir=vec2(1.0/window_width,1.0/window_height);
    
    if(show_threshold<1.0){//} && texCoord.y>show_threshold){
        float sum;
        float dr,dx,dy;
        sum=.0;
//        for(int i=0;i<4;++i){
//            dr=particlePos[i][2];
//            dx=texCoord.x*window_width-particlePos[i][0];
//            dy=(1.0-texCoord.y)*window_height-particlePos[i][1];
//            sum+=dr*dr/(dx*dx+dy*dy);
//        }

        dr=mix(window_width/4.0,window_width/3.0,show_threshold);
        for(float i=0.0;i<4.0;++i){
            int ix=int(floor(i*2.0/4.0));
            int iy=int(floor(mod((i*2.0),4.0)));
            int jx=int(floor((i*2.0+1.0)/4.0));
            int jy=int(floor(mod((i*2.0+1.0),4.0)));
            
            dx=texCoord.x*window_width-particlePos[ix][iy];
            dy=(1.0-texCoord.y)*window_height-particlePos[jx][jy];
            sum+=dr*dr*2.0/(dx*dx+dy*dy);
        }
//        dr=particlePos[3][2];
        dx=texCoord.x*window_width;
        dy=(texCoord.y-show_threshold)*window_height;
        sum+=dr*dr/(dx*dx+dy*dy);
//
//        dr=particlePos[3][2];
        dx=window_width-texCoord.x*window_width;
        dy=(texCoord.y-show_threshold)*window_height;
        sum+=dr*dr/(dx*dx+dy*dy);
        
        if(sum<(1.0-show_threshold-0.1*cnoise(textureCoordinate))){
            gl_FragColor=texture2D(Sampler,textureCoordinate);
            return;
        }
    }
//    //if((textureCoordinate.y+0.1*cnoise(textureCoordinate))>(show_height+tan(show_angle))){
//    vec2 p=normalize(vec2(.5,show_height)-textureCoordinate);
//    if(abs(acos(dot(p,force_vector)))<=1.57){
//        gl_FragColor=texture2D(Sampler,textureCoordinate);
//        return;
//    }
    if(mod(floor(texCoord.x*window_width),4.0)!=mod(floor(texCoord.y*window_height),4.0)){
        gl_FragColor=vec4(0,0,0,1.0);
        return;
    }
    
    
    leftTextureCoordinate = textureCoordinate + vec2(-dir.x, 0.0);
    rightTextureCoordinate = textureCoordinate + vec2(dir.x, 0.0);
    
    topTextureCoordinate = textureCoordinate + vec2(0.0, -dir.y);
    topLeftTextureCoordinate = textureCoordinate + vec2(-dir.x, -dir.y);
    topRightTextureCoordinate = textureCoordinate + vec2(dir.x, -dir.y);
    
    bottomTextureCoordinate = textureCoordinate + vec2(0.0,dir.y);
    bottomLeftTextureCoordinate = textureCoordinate + vec2(-dir.x,dir.y);
    bottomRightTextureCoordinate = textureCoordinate + vec2(dir.x,dir.y);
    
   float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
   float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
   float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
   float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
   float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
   float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
   float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
   float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;

//   float h = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
//   float v = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
//   float mag = length(vec2(h, v));
//gl_FragColor = vec4(vec3(mag), 1.0);
    
    vec2 gradientDirection;
    gradientDirection.x = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    gradientDirection.y = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;

    float gradientMagnitude = length(gradientDirection);
    vec2 normalizedDirection = normalize(gradientDirection);
    normalizedDirection = sign(normalizedDirection) * floor(abs(normalizedDirection) + 0.617316); // Offset by 1-sin(pi/8) to set to 0 if near axis, 1 if away
    normalizedDirection = (normalizedDirection + 1.0) * 0.5; // Place -1.0 - 1.0 within 0 - 1.0

    //gl_FragColor = vec4(gradientMagnitude, normalizedDirection.x, normalizedDirection.y, 1.0);
    if(gradientMagnitude>sobel_threshold){
//          gl_FragColor=vec4(0,0,0,1.0);
        gl_FragColor=mix(vec4(vec3(gradientMagnitude),1.0),texture2D(Sampler,textureCoordinate),show_threshold/2.0);
    }else{
      gl_FragColor=vec4(0,0,0,1.0);
//        gl_FragColor=vec4(vec3(1.0-gradientMagnitude),1.0);
    }
    
    
    
}
