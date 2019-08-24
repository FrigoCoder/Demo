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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	//get coords and direction
	vec2 uv=fragCoord.xy/iResolution.xy-.5;
	uv.y*=iResolution.y/iResolution.x;
	vec3 dir=vec3(uv,1.0);

	//mouse rotation
	vec3 from=vec3(0.,0.,-1.5);
	from+=vec3(4,2,0)*(iTime/60.0-0.5);
	
	//volumetric rendering
	float fade=1.;
	vec3 v=vec3(0.);
    for( float s=smin; s<=smax; s+=step){
		vec3 p=from+s*dir;
        float a=kaliset(p);
		v+=vec3(s,s*s,s*s*s*s)*a*fade; // coloring based on distance
		fade*=distfading; // distance fading
	}
	fragColor = vec4(v*.0001,1.);	
}
