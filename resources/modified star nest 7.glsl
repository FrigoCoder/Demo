// Star Nest by Pablo Roman Andrioli

// This content is under the MIT License.

#define iterations 15
#define formuparam 0.53

#define smin 0.0
#define smax 4.0
#define step 0.1

float kaliset(vec3 p){
    float a=0.;
    for (int i=0; i<iterations; i++) {
	    float len=length(p);
        p=abs(p)/(len*len)-formuparam; // the magic formula
        a+=abs(length(p)-len); // absolute sum of average change
    }
    return a*a*a; // add contrast
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera
    vec3 cam=vec3(0.,0.,-1.0);
    cam+=vec3(4,2,0)*(iTime/60.0-0.5);
    
	// get coords and direction
	vec2 uv=fragCoord.xy/iResolution.xy-.5;
	uv.y*=iResolution.y/iResolution.x;
	vec3 dir=vec3(uv,1.0)*step;

	// volumetric rendering
    vec3 p=cam;
    vec3 v=vec3(0.);
    float fade=1.0;
    for( float s=smin; s<=smax; s+=step){
        p+=dir;
        float a=kaliset(p);
        v+=vec3(s,s*s,s*s*s*s)*a*fade;
        fade*=0.73;
	}
	fragColor = vec4(v*.0001,1.);	
}
