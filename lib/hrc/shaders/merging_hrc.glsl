// merging_hrc.glsl
// Main shader that executes raytracing and merges cascade levels.

uniform vec2 merging_extent;
uniform vec2 merging_indices; // x: cascade index, y: frustum index
uniform Image merging_previous;
uniform Image merging_emissivity;
uniform Image merging_absorption;

// Fetches the radiance from the previous (upper) cascade level at the probe's offset position
vec4 coneVolume(vec2 probe, float index) {
    vec2 mem = vec2(probe.x + index, probe.y) / merging_extent;
    
    // Bounds check to ensure we only sample within the texture boundaries
    bool inside = (mem.x >= 0.0 && mem.x <= 1.0 && mem.y >= 0.0 && mem.y <= 1.0);
    return Texel(merging_previous, mem) * float(inside);
}

// Rotates probe coordinates based on frustum direction to process 90-degree angular cones in 4 directions
vec2 frustRot(vec2 probe) {
    vec2 rot = mix(probe, probe.yx, mod(merging_indices.y, 2.0));
    return mix(rot, merging_extent - rot, step(0.5, mod(merging_indices.y, 3.0)));
}

// Performs local DDA raytracing and merges upper cascade radiance at the ray's endpoint
vec4 traceAndMerge(vec2 probe, vec2 merge, float weight, float palign, float index) {
    // Determine ray start and direction in rotated frame
    vec4 ray = vec4(frustRot(probe), frustRot(merge + probe) - frustRot(probe));
    
    // Normalize step vector to have a maximum component of 1 pixel
    ray.zw = ray.zw / max(abs(ray.z), abs(ray.w));
    
    // Calculate adaptive step size based on cascade interval (LOD raymarching)
    float intrv = merge.x / palign;
    float step_size = max(1.0, floor(intrv / 8.0));
    
    float optlen = length(ray.zw) * step_size;
    vec2 step_vector = ray.zw * step_size;
    
    // Scale vectors to UV coordinate space
    ray /= merging_extent.xyxy;
    step_vector /= merging_extent.xy;
    
    vec4 radiance = vec4(0.0);
    vec4 transmit = vec4(1.0);
    
    // Traversal loop along the ray with adaptive step size
    for (float ii = 0.0; ii < merge.x; ii += step_size) {
        // Bounds check
        if (ray.x < 0.0 || ray.x > 1.0 || ray.y < 0.0 || ray.y > 1.0) {
            break;
        }
        
        // Accumulate light and attenuation
        vec4 tt = exp2(-Texel(merging_absorption, ray.xy) * optlen);
        vec4 rr = Texel(merging_emissivity, ray.xy) * (1.0 - tt);
        radiance += rr * transmit;
        transmit *= tt;
        
        // Early breakout on high absorption (light is fully blocked)
        if (max(transmit.r, max(transmit.g, transmit.b)) < 0.005) {
            break;
        }
        
        ray.xy += step_vector;
    }
    
    // Combine local traced radiance (attenuated by wedge angle) with upper cascade radiance at endpoint
    radiance = (radiance * weight) + (transmit * coneVolume(probe + merge, index));
    
    // For even planes, interpolate with the local probe's upper cascade radiance
    return mix(radiance, coneVolume(probe, index), 0.5 * (palign - 1.0));
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 texel = texture_coords * merging_extent.xy;
    float intrv = exp2(merging_indices.x);
    float plane = floor(texel.x / intrv);
    float index = mod(texel.x, intrv) - 0.5;
    
    vec2 probe = vec2(plane * intrv + 0.5, texel.y);
    float align = 2.0 - mod(plane, 2.0);
    
    // Calculate boundaries of the current angular cone
    vec2 coneL = align * vec2(intrv, -intrv + index * 2.0);
    vec2 coneR = align * vec2(intrv, -intrv + (index + 1.0) * 2.0);
    
    // Calculate angular weight (wedge angle)
    float wedge = 0.5 * (atan(coneR.y, coneR.x) - atan(coneL.y, coneL.x));
    
    // If the probe is at the very border (probe.x < 1.0), return black, otherwise trace left & right
    if (probe.x < 1.0) {
        return vec4(0.0);
    }
    
    return traceAndMerge(probe, coneL, wedge, align, index * 2.0)
         + traceAndMerge(probe, coneR, wedge, align, index * 2.0 + 1.0);
}
