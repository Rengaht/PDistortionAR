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

uniform sampler2D inputImageTexture;
uniform float window_width;
uniform float window_height;


varying vec2 texCoord;

void main(){
    textureCoordinate = texCoord;
    vec2 dir=vec2(1.0/window_width,1.0/window_height);
    
//    leftTextureCoordinate = textureCoordinate + vec2(-1.0, 0.0);
//    rightTextureCoordinate = textureCoordinate + vec2(1.0, 0.0);
//
//    topTextureCoordinate = textureCoordinate + vec2(0.0, -1.0);
//    topLeftTextureCoordinate = textureCoordinate + vec2(-1.0, -1.0);
//    topRightTextureCoordinate = textureCoordinate + vec2(1.0, -1.0);
//
//    bottomTextureCoordinate = textureCoordinate + vec2(0.0,1.0);
//    bottomLeftTextureCoordinate = textureCoordinate + vec2(-1.0,1.0);
//    bottomRightTextureCoordinate = textureCoordinate + vec2(1.0,1.0);
    
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


    float blur = leftIntensity + rightIntensity + topIntensity + bottomIntensity + bottomLeftIntensity + topRightIntensity + topLeftIntensity + bottomRightIntensity + texture2D(inputImageTexture, textureCoordinate).r;
    blur *= 0.11111;

   gl_FragColor = vec4(vec3(blur), 1.0);
}
