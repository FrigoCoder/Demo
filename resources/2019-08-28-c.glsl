float kaliset(vec3 p, float t){
    float a=0.0;
    for(int i=0; i<15;i++){
        float len=length(p);
        p=abs(p)/(len*len)-t;
        a+=len*len;
    }
    return a;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t=iTime/60.0;
    vec2 uv=vec2(fragCoord.x/iResolution.x-0.5,(fragCoord.y/iResolution.y-0.5)*iResolution.y/iResolution.x);        
    uv*=iTime;
    float r=kaliset(vec3(uv, 0.2),t);
    float g=kaliset(vec3(uv, 0.3),t);
    float b=kaliset(vec3(uv, 0.4),t);
	fragColor.xyz=vec3(r,g,b)*0.001;
}
