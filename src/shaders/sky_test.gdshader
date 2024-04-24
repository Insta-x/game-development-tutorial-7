shader_type sky;
 
uniform float rotation = 0.0;
uniform float altitude = 0.6;
uniform float imageSize = 0.02;
uniform sampler2D imageTexture;
 
float map(float value, float srcMin, float srcMax, float destMin, float destMax){
    return destMin + (value-srcMin) * (destMax-destMin) / (srcMax-srcMin);
}
 
mat3 rotation3dY(float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return mat3(
    vec3(c, 0.0, -s),
    vec3(0.0, 1.0, 0.0),
    vec3(s, 0.0, c)
  );
}
 
vec4 projImage(float _altitude, float _rot_x, float _viewVec_x, float _imageSize, sampler2D _image) {
    if(_rot_x > _altitude-_imageSize && _rot_x < _altitude+_imageSize){
  	  float xSizeFactor = 2.0*PI;
  	  if(_viewVec_x > -_imageSize*xSizeFactor && _viewVec_x < _imageSize*xSizeFactor){
  		  float v = map(_rot_x-_altitude, -_imageSize, _imageSize, 1.0, 0.0);
  		  float u = map(_viewVec_x, -_imageSize*xSizeFactor, _imageSize*xSizeFactor, 0.0, 1.0);
 
  		  return texture(_image, vec2(u, v));
  	  }
    }
    return vec4(0.0);
}
 
vec4 skyImageProj(vec3 viewVec, float _rotation, float _altitude, float _imageSize, sampler2D _imageSampler) {
    _altitude = fract(_altitude);
    vec3 _EYEDIR = rotation3dY(_rotation) * viewVec;
    //Since we applied the rotation directly to the viewVec we can just ingore it from now on.
 
    //float rot_z = atan(_EYEDIR.y, _EYEDIR.x)/(2.0*PI)+0.5;
    float rot_x = atan(_EYEDIR.y, _EYEDIR.z)/(2.0*PI)+0.5;
    //float rot_y = atan(_EYEDIR.z, _EYEDIR.x)/(2.0*PI)+0.5;
 
    vec4 result = projImage(_altitude, rot_x, _EYEDIR.x, _imageSize, _imageSampler);
 
    //make sure the image isn't clipped when altitude approaches the max/min values
    if(_altitude > 0.75) {
  	  result = max(result, projImage(_altitude-1.0, rot_x, _EYEDIR.x, _imageSize, _imageSampler));
    } else if (_altitude < 0.25) {
  	  result = max(result, projImage(_altitude+1.0, rot_x, _EYEDIR.x, _imageSize, _imageSampler));
    }
    return result;
}
 
void sky() {
    vec4 sun = skyImageProj(EYEDIR, rotation, altitude, imageSize, imageTexture);
    COLOR = vec3(0.3,0.3, 0.9) * (1.0-sun.a) + sun.rgb * sun.a;
}