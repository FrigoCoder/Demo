#define iterations 20

vec3 kaliset(vec3 p, vec3 t){
    vec3 c=abs(p);
    for(int i=0;i<iterations;i++){
        float len=length(p);
        p=abs(p)/(len*len)-t;
        c+=p;
    }
	return c/float(iterations);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t=iTime/60.0;
    vec2 uv=vec2(fragCoord.x/iResolution.x-0.5,(fragCoord.y/iResolution.y-0.5)*iResolution.y/iResolution.x);        
    vec3 c=kaliset(vec3(uv, 0.02)*t*60.0, vec3(0.8, 0.8, 0.1)*t);
    fragColor.xyz=c;
}
