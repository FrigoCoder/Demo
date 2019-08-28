
float kaliset(vec2 p, float t){
    float a=0.0;
    for(int i =0; i<15;i++){
        float len=length(p);
        p=abs(p)/(len*len)-t;
        a+=len*len;
    }
    return a;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t=iTime*0.1;
    vec2 uv=vec2(fragCoord.x/iResolution.x-0.5,(fragCoord.y/iResolution.y-0.5)*iResolution.y/iResolution.x);        
    float r=kaliset(uv,t+0.1);
    float g=kaliset(uv,t+0.0);
    float b=kaliset(uv,t-0.1);
	fragColor.xyz=vec3(r,g,b)*0.001;
}
