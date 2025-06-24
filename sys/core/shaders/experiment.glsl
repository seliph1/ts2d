//#pragma language glsl3
// CC0: Old 2D Shadows experiment
//  I found an old shader that I for some reason never published
//  I was experimenting with 2D shadows at that time.
//  Thought it looked neat so I publish it now instead.

//#define GIVE_ME_A_LOGO_INSTEAD
//#define GIVE_ME_A_FRACTAL_INSTEAD

uniform vec4 iMouse = vec4(0.0);
uniform float iTime = 0.0;
vec2 iResolution = love_ScreenSize.xy;

#define RESOLUTION  iResolution
#define TIME        iTime
#define MAX_MARCHES 40
#define TOLERANCE   0.0001
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))
#define PI          3.141592654
#define TAU         (2.0*PI)

// -----------------------------------------------------------------------------
// Licenses
//  CC0     - https://creativecommons.org/share-your-work/public-domain/cc0/
//  MIT     - https://mit-license.org/
//  WTFPL   - https://en.wikipedia.org/wiki/WTFPL
//  Unknown - No license identified, does not mean public domain
// -----------------------------------------------------------------------------

// Glimglam distance field font

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

const float glimglam_corner0 = 0.02;
const float glimglam_corner1 = 0.075;
const float glimglam_topy    = 0.051+glimglam_corner0;
const float glimglam_smoother= 0.0125;

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float pabs(float a, float k) {
  return -pmin(a, -a, k);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float corner(vec2 p) {
  vec2 v = min(p, vec2(0));
  return length(max(p, vec2(0))) + max(v.x, v.y);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float roundedBox(vec2 p, vec2 b, vec4 r) {
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_bar(vec2 p) {
  vec2 pbar = p;
  pbar.y -= glimglam_topy;
  return abs(pbar.y)-glimglam_corner0;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_a(vec2 p) {
  p.x = abs(p.x);
  float db = roundedBox(p, vec2 (0.19, 0.166), vec4(glimglam_corner1, glimglam_corner0, glimglam_corner1, glimglam_corner0));
  float dc = corner(p-vec2(0.045, -0.07))-glimglam_corner0;

  float d = db;
  d = max(d, -dc);

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_c(vec2 p) {
  p = -p.yx;
  float db = roundedBox(p, vec2 (0.166, 0.19), vec4(glimglam_corner1, glimglam_corner0, glimglam_corner1, glimglam_corner0));
  p.x = abs(p.x);
  float dc = corner(p-vec2(0.055, glimglam_topy))-glimglam_corner0;

  float d = db;
  d = max(d, -dc);

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_e(vec2 p) {
  p = -p.yx;
  float db = roundedBox(p, vec2 (0.166, 0.19), vec4(glimglam_corner0, glimglam_corner0, glimglam_corner0, glimglam_corner0));

  float dl = abs(p.x-(0.075-glimglam_corner0))-glimglam_corner0;
  float dt = p.y-glimglam_topy;

  float d = db;
  d = max(d, -pmax(dl,dt, glimglam_smoother));

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_g(vec2 p) {
  float db = roundedBox(p, vec2 (0.19, 0.166), vec4(glimglam_corner0, glimglam_corner1, glimglam_corner1, glimglam_corner1));
  float dc = corner(-(p-vec2(-0.045, -0.055)));
  dc = abs(dc) - glimglam_corner0;
  float dd = max(p.x-0.065, p.y-glimglam_topy);
  float d = db;
  d = max(d, -max(dc, dd));
  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_h(vec2 p) {
  p.x = abs(p.x);
  float da = roundedBox(p-vec2(0.13, 0.0), vec2 (0.066, 0.166), vec4(glimglam_corner0));
  float db = roundedBox(p, vec2 (0.16, 0.05), vec4(glimglam_corner0));
  float d = da;
  d = min(d, db);
  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_i(vec2 p) {
  return roundedBox(p, vec2 (0.066, 0.166), vec4(glimglam_corner0));
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_j(vec2 p) {
  p.x = -p.x;
  float db = roundedBox(p, vec2 (0.15, 0.166), vec4(glimglam_corner0, glimglam_corner0, glimglam_corner0, glimglam_corner1));
  float dc = corner(-(p-vec2(-0.007, -0.055)))-glimglam_corner0;
  float d = db;
  d = max(d, -dc);
  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_l(vec2 p) {
  float db = roundedBox(p, vec2 (0.175, 0.166), vec4(glimglam_corner0, glimglam_corner0, glimglam_corner0, glimglam_corner1));
  float dc = corner(-(p-vec2(-0.027, -0.055)))-glimglam_corner0;
  float d = db;
  d = max(d, -dc);
  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_m(vec2 p) {
  float db = roundedBox(p, vec2 (0.255, 0.166), vec4(glimglam_corner1, glimglam_corner0, glimglam_corner0, glimglam_corner0));
  p.x = abs(p.x);
  float dl = abs(p.x-0.095)-glimglam_corner0*2.0;
  float dt = p.y-glimglam_topy;

  float d = db;
  d = max(d, -max(dl,dt));

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_n(vec2 p) {
  float db = roundedBox(p, vec2 (0.19, 0.166), vec4(glimglam_corner1, glimglam_corner0, glimglam_corner0, glimglam_corner0));

  float dl = abs(p.x)-0.07;
  float dt = p.y-glimglam_topy;

  float d = db;
  d = max(d, -max(dl,dt));

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_o(vec2 p) {
  const float sz = 0.05;
  float db = roundedBox(p, vec2(0.19, 0.166)-sz, vec4(glimglam_corner1, glimglam_corner1, glimglam_corner1, glimglam_corner1)-sz);
  db = abs(db)-sz;

  float d = db;

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_s(vec2 p) {
  p.x = -p.x;
  p = -p.yx;
  float db = roundedBox(p, vec2 (0.166, 0.19), vec4(glimglam_corner1, glimglam_corner0, glimglam_corner0, glimglam_corner1));
  vec2 pc = p;
  pc.x *= sign(pc.y);
  pc.y = abs(pc.y);
  float cr = glimglam_corner1*1.3;
  pc -=vec2(-0.055, 0.20);
  pc.x = -pc.x;
  float dc = corner(pc+cr)-cr;
  vec2 pk = p;
  pk = -abs(pk);
  float dk = pk.x+glimglam_topy;
  dc = min(dk, dc);

  float dl = abs(p.x-(0.075-glimglam_corner0))-glimglam_corner0;
  float dt = p.y-glimglam_topy;

  float d = db;
  d = max(d, -pmax(dl,dt, glimglam_smoother));
  d = pmax(d, dc, glimglam_smoother);

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_t(vec2 p) {
  float da = roundedBox(p-vec2(0.0, 0.12), vec2 (0.166, 0.05), vec4(glimglam_corner0));
  float db = roundedBox(p, vec2 (0.066, 0.166), vec4(glimglam_corner0));
  float d = da;
  d = min(d, db);
  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam_z(vec2 p) {
  p = -p.yx;
  float db = roundedBox(p, vec2 (0.166, 0.19), vec4(glimglam_corner0, glimglam_corner0, glimglam_corner0, glimglam_corner0));
  vec2 pc = p;
  pc.x *= sign(pc.y);
  pc.y = abs(pc.y);
  float cr = glimglam_corner1*1.3;
  pc -=vec2(-0.055, 0.20);
  pc.x = -pc.x;
  float dc = corner(pc+cr)-cr;
  vec2 pk = p;
  pk = -abs(pk);
  float dk = pk.x+glimglam_topy;
  dc = min(dk, dc);

  float dl = abs(p.x-(0.075-glimglam_corner0))-glimglam_corner0;
  float dt = p.y-glimglam_topy;

  float d = db;
  d = max(d, -pmax(dl,dt, glimglam_smoother));
  d = pmax(d, dc, glimglam_smoother);

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float glimglam(vec2 p) {
  float dbar = glimglam_bar(p);

  vec2 pg = p;
  pg.x -= -0.665;
  pg.x = -abs(pg.x);
  pg.x -= -0.7475;
  pg.x *= -sign(p.x+0.665);
  float dg = glimglam_g(pg);

  vec2 pi = p;
  pi.x -= -0.746;
  float di = glimglam_i(pi);

  vec2 pl = p;
  pl.x -= -0.27;
  pl.x = -abs(pl.x);
  pl.x -= -0.745;
  pl.x *= -sign(p.x+0.27);
  float dl = glimglam_l(pl);

  vec2 pa = p;
  pa.x -= 0.87;
  float da = glimglam_a(pa);

  vec2 pm = p;
  pm.x -= 0.475;
  pm.x = abs(pm.x);
  pm.x -= 0.875;
  pm.x *= sign(p.x-0.475);
  float dm = glimglam_m(pm);

  float d = 1E6;
  d = min(d, dg);
  d = min(d, dl);
  d = min(d, di);
  d = min(d, da);
  d = min(d, dm);
  d = pmax(d, -dbar, glimglam_smoother);

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float lance(vec2 p) {
  p.x -= -0.810;
  float dbar = glimglam_bar(p);

  vec2 pl = p;
  float dl = glimglam_l(pl);

  vec2 pa = p;
  pa.x -= 0.39;
  float da = glimglam_a(pa);

  vec2 pn = p;
  pn.x -= 0.795;
  float dn = glimglam_n(pn);

  vec2 pc = p;
  pc.x -= 1.2;
  float dc = glimglam_c(pc);

  vec2 pe = p;
  pe.x -= 1.605;
  float de = glimglam_e(pe);

  float d = 1E6;
  d = min(d, dl);
  d = min(d, da);
  d = min(d, dn);
  d = min(d, dc);
  d = min(d, de);
  d = pmax(d, -dbar, glimglam_smoother);

  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float jez(vec2 p) {
  p.x -= -0.401;
  float dbar = glimglam_bar(p);

  vec2 pj = p;
  float dj = glimglam_j(pj);

  vec2 pe = p;
  pe.x -= 0.36;
  float de = glimglam_e(pe);

  vec2 pz = p;
  pz.x -= 0.76;
  float dz = glimglam_z(pz);

  float d = 1E6;
  d = min(d, dj);
  d = min(d, de);
  d = min(d, dz);
  d = pmax(d, -dbar, glimglam_smoother);
  return d;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float longshot(vec2 p) {
  p.x -= -1.385;
  float dbar = glimglam_bar(p);

  vec2 pl = p;
  float dl = glimglam_l(pl);

  vec2 po = p;
  po -= vec2(1.395, 0.0);
  po.x = abs(po.x);
  po -= vec2(1.0125, 0.0);
  float do_ = glimglam_o(po);

  vec2 pn = p;
  pn -= vec2(0.785, 0.0);
  float dn = glimglam_n(pn);

  vec2 pg = p;
  pg -= vec2(1.185, 0.0);
  float dg = glimglam_g(pg);

  vec2 ps = p;
  ps -= vec2(1.585, 0.0);
  float ds = glimglam_s(ps);

  vec2 ph = p;
  ph -= vec2(1.995, 0.0);
  float dh = glimglam_h(ph);

  vec2 pt = p;
  pt -= vec2(2.78, 0.0);
  float dt = glimglam_t(pt);

  float d = 1E6;
  d = min(d, dl);
  d = min(d, do_);
  d = min(d, dn);
  d = min(d, dg);
  d = min(d, ds);
  d = min(d, dh);
  d = min(d, dt);
  d = pmax(d, -dbar, glimglam_smoother);
  return d;
}

float rayPlane(vec3 ro, vec3 rd, vec4 p ) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

// License: Unknown, author: Unknown, found: don't remember
float hash_(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(in vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}


float starn(vec2 p, float r, float n, float m) {
    // next 4 lines can be precomputed for a given shape
    float an = PI/float(n);
    float en = PI/m;  // m is between 2 and n
    vec2  acs = vec2(cos(an),sin(an));
    vec2  ecs = vec2(cos(en),sin(en)); // ecs=vec2(0,1) for regular polygon

    float bn = mod(atan(p.x,p.y),2.0*an) - an;
    p = length(p)*vec2(cos(bn),abs(sin(bn)));
    p -= r*acs;
    p += ecs*clamp( -dot(p,ecs), 0.0, r*acs.y/ecs.y);
    return length(p)*sign(p.x);
}

float df0(vec2 p, out float h) {  
  p.x += TIME*0.3;
  const float z = 0.075;
  float d1 = p.y-0.15; 
  p /= z;
  vec2 n = mod2(p, vec2(4.0));
  float h0 = hash(n+123.4);
  float h1 = fract(1667.0*h0);
  float h2 = fract(8367.0*h0);
  p *= ROT(mix(-1.0, 1.0, h1)*TIME);
//  float d0 = triangle(p);
  float sn = floor(mix(2.0, 7.0, h2));
  h = h2;
  float sm = sn/2.0+1.0;
  float d0 = starn(p, 0.5, sn, sm);
  
  float d = d0;
  d *= z;
  d = max(d, d1);
  return d;
}

float df1(vec2 p, out float h) {
  const float z = 1.0;
  p /= z;

  p.y -= -0.;
  float d = lance(p);
  d *= z;
  
  return d;
}

float apollian(vec3 p, float s) {
  float scale = 1.0;


  for(int i=0; i<3; ++i) {
    p = -1.0 + 2.0*fract(0.5*p+0.5);

    float r2 = dot(p,p);
    
    float k  = s/r2;
    p       *= k;
    scale   *= k;

  }
  
  vec3 ap = abs(p/scale);  
  float d = ap.x-0.005;
  d = max(d, ap.y);
  d = min(d, ap.z);
  return d;
}

float df2(vec2 p, out float h) {
  const float z = 1.25;
  p /= z;

  vec3 p3 = vec3(p, 0.1);
  p3.xz*=ROT(0.1*TIME);
  p3.yz*=ROT(0.123*TIME);
  float d = apollian(p3, 1.0+0.2);
  d *= z;
  
  return d;
}



float df(vec2 p, out float h) {
#if defined(GIVE_ME_A_FRACTAL_INSTEAD)
  return df2(p, h);
#elif defined(GIVE_ME_A_LOGO_INSTEAD)
  return df1(p, h);
#else  
  return df0(p, h);
#endif
}

float shadow(vec2 lp, vec2 ld, float mint, float maxt) {
  float t = mint;

  float ds = 1.0-0.4;
  
  float nd = 1E6;
  float h;
  const float soff = 0.05;
  const float smul = 1.5;
  for (int i=0; i < MAX_MARCHES; ++i) {
    vec2 p = lp + ld*t;
    float d = df(p, h);
    
    if (d < TOLERANCE || t >= maxt) {
      float sd = 1.0-exp(-smul*max(t/maxt-soff, 0.0));
      return t >= maxt ? mix(sd, 1.0, smoothstep(0.0, 0.025, nd)) : sd;
    }
    nd = min(nd, d);

    t += ds*d;
  }
  
  float sd = 1.0-exp(-smul*max(t/maxt-soff, 0.0));
  return sd;
}

const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}

vec3 effect_(vec2 p, vec2 q) {
  float aa = 2.0/RESOLUTION.y;
  
  float a = 0.25*TIME;
  vec2  lightPos  = vec2(1.25*cos(a), 0.75*sin(a));
  vec2  lightDiff = lightPos - p;
  float lightD2   = dot(lightDiff,lightDiff);
  float lightLen  = sqrt(lightD2);
  vec2  lightDir  = lightDiff / lightLen;
  vec3  lightPos3 = vec3(lightPos, 0.0);
  vec3  p3        = vec3(p, -1.0);
  float lightLen3 = distance(lightPos3, p3);
  vec3  lightDir3 = normalize(lightPos3-p3);
  vec3  n3        = vec3(0.0, 0.0, 1.0);
  vec3  ro3       = vec3(0.0, 0.0, 0.0);
  vec3  rd3       = normalize(p3 - ro3);
  float diff      = max(dot(lightDir3, n3), 0.0);
  vec3 col = vec3(0.0);
 
  float h;
  float d   = df(p, h);
  float od = abs(d)-aa*1.0;
  float ss = shadow(p,lightDir, 0.005, lightLen);
  vec3 bcol = hsv2rgb(vec3(h, 0.75, 1.0));
  col += mix(0., 1.0, diff)*0.5*mix(0.1, 1.0, ss)/(lightLen3*lightLen3);
  col = mix(col, vec3(0.0), smoothstep(aa, -aa, d));
  col = mix(col, bcol, smoothstep(aa, -aa, od));
  col += exp(-40.0*max(lightLen-0.02, 0.0));
 
  return col;
}

vec4 effect( vec4 fragColor, Image tex, vec2 fragCoord, vec2 screenCoord ) {
  vec2 q = screenCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect_(p, q); 
  col = sqrt(col);
  
  return vec4(col, 1.0);
}
