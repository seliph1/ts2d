float opU(float d1, float d2) {
	return min(d1, d2);
}

float opI(float d1, float d2) {
	return max(d1, d2);
}

float opS(float d1, float d2) {
	return max(d1, -d2);
}

float circle(vec2 p, float r) {
	return length(p) - r;
}

float ring(vec2 p, float r, float thick) {
	return abs(circle(p, r)) - thick;
}

float pie(vec2 p, float angle) {
    return dot(vec2(abs(p.x), p.y), vec2(cos(angle), sin(angle)));
}

float arc(vec2 p, float r, float thick, float angle) {
	return opS(ring(p, r, thick), pie(p, angle));
}

float round_box(vec2 p, vec2 d, float r) {
	p = abs(p) - d;
    return min(max(p.x,p.y),0.0) + length(max(p,0.0)) - r;
}

float line_segment(vec2 p, vec2 a, vec2 b, float r) {
	vec2 ab = b - a;
    vec2 ap = p - a;
    return length(ap - ab * clamp(dot(ab, ap) / dot(ab, ab), 0.0, 1.0)) - r;
}

// triangle's sdf comes form iq's https://www.shadertoy.com/view/XsXSz4
// it use perp dot product to decide whether p inside or outside of triangle
// more info: http://mathworld.wolfram.com/PerpDotProduct.html
// vector's perpendicular has two directions below or above
// choose direction according to triangle's ccw or cw
// so in this implementation, a, b, c must be given ccw

float perp_dot(vec2 a, vec2 b) {
	return dot(vec2(-a.y, a.x), b);
}

float triangle(vec2 p, vec2 a, vec2 b, vec2 c) {
	vec2 ab = b - a, bc = c - b, ca = a - c;
    vec2 ap = p - a, bp = p - b, cp = p - c;
    vec2 pab = ap - ab * clamp(dot(ab, ap) / dot(ab, ab), 0.0, 1.0);
    vec2 pbc = bp - bc * clamp(dot(bc, bp) / dot(bc, bc), 0.0, 1.0);
    vec2 pca = cp - ca * clamp(dot(ca, cp) / dot(ca, ca), 0.0, 1.0);
    
    vec2 d = min(min(
        vec2(dot(pab, pab), perp_dot(ab, ap)),
    	vec2(dot(pbc, pbc), perp_dot(bc, bp))),
        vec2(dot(pca, pca), perp_dot(ca, cp)));
    
    return -sqrt(d.x) * sign(d.y);
}

mat2 ccw(float a) {
    float ca = cos(a);
    float sa = sin(a);
	return mat2(ca, sa, -sa, ca);
}

float map(vec2 p) {
    float d = circle(p - vec2(-1.3, 0.45), 0.25);
    d = opU(d, ring(p - vec2(-0.6, 0.45), 0.22, 0.04));
    d = opU(d, round_box(p - vec2(0.1, 0.45), vec2(0.2), 0.05));
    d = opU(d, line_segment(p - vec2(0.8, 0.45), vec2(-0.2), vec2(0.2), 0.05));
    d = opU(d, triangle(p - vec2(1.3, 0.45), vec2(-0.25), vec2(0.25, -0.25), vec2(0.0, 0.25)));
    
    d = opU(d, opS(
        circle(p - vec2(-1.3, -0.45), 0.25),
        round_box(p - vec2(-1.3, -0.45 + 0.25 * sin(iTime * 3.0)), vec2(0.3, 0.1), 0.0)));
    
    d = opU(d, opI(
        circle(p - vec2(-0.6, -0.45), 0.25),
    	round_box(p - vec2(-0.6, -0.45 + 0.25 * sin(iTime * 3.0)), vec2(0.3, 0.1), 0.0)));
    
    d = opU(d, opU(
        circle(p - vec2(0.1, -0.45), 0.25),
    	round_box(p - vec2(0.1, -0.45 + 0.25 * sin(iTime * 3.0)), vec2(0.3, 0.1), 0.0)));
    
    d = opU(d, triangle((p - vec2(0.8, -0.45)) * ccw(iTime),
        vec2(-0.2165, -0.125), vec2(0.2165, -0.125), vec2(0.0, 0.25)));
    
    d = opU(d, arc(p - vec2(1.3, -0.45), 0.2, 0.03, 0.6));
    
    return d;
}

float plot_edge(float d) {
	return smoothstep(3.0 / iResolution.y, 0.0, abs(d));
}

float plot_solid(float d) {
	return smoothstep(3.0 / iResolution.y, 0.0, max(0.0, d));
}

vec3 shadow(vec2 ro, vec2 mo) {
    vec2 rd = normalize(mo - ro);
    for(int i = 0; i < 48; ++i) {
        float d = map(ro);
        float tmax = length(mo - ro);
        if(d > tmax) return vec3(0.2);
        if(d < 0.01) return vec3(0.0);
        ro += d * rd;
    }
    return vec3(0.2);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec2 mo = (iMouse.xy * 2.0 - iResolution.xy) / iResolution.y;
    
    vec3 bg = vec3(0.5) * (1.0 - length(uv) * 0.3);
    bg *= clamp(min(mod(fragCoord.x, 20.0), mod(fragCoord.y, 20.0)), 0.9, 1.0);
    bg = mix(bg, vec3(1.0), plot_solid(circle(uv - vec2(mo), 0.06)));
    bg += shadow(uv, mo);
    
    float d = map(uv);
    bg = mix(bg, vec3(1.0, 0.4, 0.0), plot_solid(d));
    bg = mix(bg, vec3(0.0), plot_edge(d));
    
	fragColor = vec4(bg, 1.0);
}