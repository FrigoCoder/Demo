vec3 kaliset(vec3 p, float t){
    vec3 c=vec3(0,0,0);
    for(int i=0; i<15;i++){
        float len=length(p);
        p=abs(p)/(len*len)-t;
        c+=p;
    }
	return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t=iTime/60.0;
    vec2 uv=vec2(fragCoord.x/iResolution.x-0.5,(fragCoord.y/iResolution.y-0.5)*iResolution.y/iResolution.x);        
    vec3 c=kaliset(vec3(uv/t, 0.1), t);
    fragColor.xyz=c*0.1;
}
