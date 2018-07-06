precision highp float;

uniform sampler2D inputImageTexture;
uniform float texelWidth;
uniform float texelHeight;
uniform float upperThreshold;
uniform float lowerThreshold;


varying vec2 texCoord;

void main()
{
    
    //vec2 textureCoordinate = gl_FragCoord[0].st;
    vec2 textureCoordinate =texCoord;
    
    vec3 currentGradientAndDirection = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec2 gradientDirection = ((currentGradientAndDirection.gb * 2.0) - 1.0) * vec2(texelWidth, texelHeight);

    float firstSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate + gradientDirection).r;
    float secondSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate - gradientDirection).r;

    float multiplier = step(firstSampledGradientMagnitude, currentGradientAndDirection.r);
    multiplier = multiplier * step(secondSampledGradientMagnitude, currentGradientAndDirection.r);

    float thresholdCompliance = smoothstep(lowerThreshold, upperThreshold, currentGradientAndDirection.r);
    multiplier = multiplier * thresholdCompliance;

    gl_FragColor = vec4(multiplier, multiplier, multiplier, 1.0);
}
