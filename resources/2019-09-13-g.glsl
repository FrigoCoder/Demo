#define iterations 20

vec3 kaliset(vec3 p, vec3 u){
    vec3 c=p;
    for(int i=0;i<iterations;i++){
        float len=length(p);
        p=abs(p)/(len*len)-u;
        c+=p;
    }
	return c/float(iterations);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float t=iTime/60.0;
    vec2 uv=vec2(fragCoord.x/iResolution.x-0.5,(fragCoord.y/iResolution.y-0.5)*iResolution.y/iResolution.x);        
    vec3 p=vec3(uv, 0.02)*t*60.0;
    vec3 u=vec3(t,t,t*t);
    vec3 c=kaliset(p, u);
    fragColor.xyz=c;
}
