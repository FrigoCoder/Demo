
float kaliset(vec3 p){
    float a=0.0;
    for (int i=0; i<15; i++) {
	    float len=length(p);
        p=abs(p)/(len*len)-0.53; // the magic formula
        a+=abs(length(p)-len); // absolute sum of average change
    }
    return a*a*a; // add contrast
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera
    float t=iTime/60.0-0.5;
    vec3 cam=vec3(4.0*t,2.0*t,-1);
    
	// direction
	vec3 dir=vec3(fragCoord.x/iResolution.x-0.5,
                  (fragCoord.y/iResolution.y-0.5)*iResolution.y/iResolution.x,
                  1.0)*0.1;

	// volumetric rendering
    vec3 p=cam;
    vec3 v=vec3(0,0,0);
    float fade=1.0;
    for( int step=0; step<=40; step++ ){
        p+=dir;
        float a=kaliset(p);
        float s=float(step)*0.1;
        v+=vec3(s,s*s,s*s*s*s)*a*fade;
        fade*=0.73;
	}
	fragColor.xyz = v*0.0001;
}
