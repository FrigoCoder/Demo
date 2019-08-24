// Star Nest by Pablo Roman Andrioli

// This content is under the MIT License.

#define iterations 15
#define formuparam 0.53

#define smin 0.1
#define smax 4.0
#define step 0.1

#define distfading 0.730

float kaliset(vec3 p){
    float pa,a=pa=0.;
    for (int i=0; i<iterations; i++) {
        p=abs(p)/dot(p,p)-formuparam; // the magic formula
        a+=abs(length(p)-pa); // absolute sum of average change
        pa=length(p);
    }
    return a*a*a; // add contrast
}

vec3 color(float s){
    return vec3(s,s*s,s*s*s*s)*pow(distfading, (s/step)-1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera
    vec3 cam=vec3(0.,0.,-1.0);
    cam+=vec3(4,2,0)*(iTime/60.0-0.5);
    
	//get coords and direction
	vec2 uv=fragCoord.xy/iResolution.xy-.5;
	uv.y*=iResolution.y/iResolution.x;
	vec3 dir=vec3(uv,1.0);


	//volumetric rendering
	vec3 v=vec3(0.);
    for( float s=smin; s<=smax; s+=step){
		vec3 p=cam+s*dir;
        float a=kaliset(p);
        v+=color(s)*a;
	}
	fragColor = vec4(v*.0001,1.);	
}
