#define iterations 20

vec3 kaliset(vec3 p, vec3 t){
    vec3 c=p;
    for(int i=0; i<iterations;i++){
        float len=length(p);
        p=abs(p)/(len*len)-t;
        c+=p;
    }
	return c/float(iterations);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv=vec2(fragCoord.x/iResolution.x-0.5,(fragCoord.y/iResolution.y-0.5)*iResolution.y/iResolution.x);        
    vec3 c=kaliset(vec3(uv, 0.02)*iTime, vec3(1.0,1.0,0.1)*0.02*iTime);
    fragColor.xyz=c;
}  
