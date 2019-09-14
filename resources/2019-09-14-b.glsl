#define iterations 20

vec3 kaliset(vec3 p, vec3 u){
    vec3 c=p;
    for(int i=0; i<iterations;i++){
        float len=length(p);
        p=abs(p)/(len*len)-u;
        c+=p;
    }
	return c/float(iterations);
}

void mainImage(out vec4 col, in vec2 xy)
{
    float m=iTime/60.0;
    vec2 uv=vec2(xy.x/iResolution.x-0.5,(xy.y-iResolution.y/2.0)/iResolution.x);
    vec3 p=vec3(uv, 1.0/60.0)*iTime;
    vec3 u=vec3(1.0, 1.0, 1.0/60.0)*m;
    vec3 c=kaliset(p, u);
    col.xyz=c;
}
