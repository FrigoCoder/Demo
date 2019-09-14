#define iterations 15

vec3 kaliset(vec3 p, vec3 t){
    vec3 c=p;
    for(int i=0;i<iterations;i++){
        float len=length(p);
        p=abs(p)/(len*len)-t;
        c+=p;
    }
	return c/float(iterations);
}

void mainImage(out vec4 c, in vec2 xy)
{
    float t=iTime/60.0;
    vec2 uv=vec2(xy.x/iResolution.x-0.5,(xy.y-iResolution.y*0.5)/iResolution.x);        
    vec3 p=vec3(uv/t,0.1);
    vec3 u=vec3(1.0,1.0,0.1)*t;
    c.xyz=kaliset(p,u);
}
