const rcShader = `
    #ifdef GL_FRAGMENT_PRECISION_HIGH
    precision highp float;
    #else
    precision mediump float;
    #endif
    uniform vec2 resolution;
    uniform sampler2D sceneTexture;
    uniform sampler2D distanceTexture;
    uniform sampler2D gradientTexture;
    uniform sampler2D lastTexture;
    uniform vec2 cascadeExtent;
    uniform float cascadeCount;
    uniform float cascadeIndex;
    uniform float basePixelsBetweenProbes;
    uniform float cascadeInterval;
    uniform float rayInterval;
    uniform float intervalOverlap;
    uniform bool addNoise;
    uniform bool enableSun;
    uniform float sunAngle;
    uniform float srgb;
    uniform float firstCascadeIndex;
    uniform float lastCascadeIndex;
    uniform float baseRayCount;
    uniform bool bilinearFixEnabled;
    
    in vec2 vUv;
    out vec3 FragColor;
    
    const float SQRT_2 = 1.41;
    const float PI = 3.14159265;
    const float TAU = 2.0 * PI;
    const float goldenAngle = PI * 0.7639320225;
    const float sunDistance = 1.0;
    
    const vec3 skyColor = vec3(0.2, 0.24, 0.35) * 4.0;
    const vec3 sunColor = vec3(0.95, 0.9, 0.8) * 3.0;
    
    const vec3 oldSkyColor = vec3(0.02, 0.08, 0.2);
    const vec3 oldSunColor = vec3(0.95, 0.95, 0.9);
    
    vec3 oldSunAndSky(float rayAngle) {
      // Get the sun / ray relative angle
      float angleToSun = mod(rayAngle - sunAngle, TAU);
    
      // Sun falloff based on the angle
      float sunIntensity = smoothstep(1.0, 0.0, angleToSun);
    
      // And that's our sky radiance
      return oldSunColor * sunIntensity + oldSkyColor;
    }
    
    vec3 sunAndSky(float rayAngle) {
        // Get the sun / ray relative angle
        float angleToSun = mod(rayAngle - sunAngle, TAU);
    
        // Sun falloff
        float sunIntensity = pow(max(0.0, cos(angleToSun)), 4.0 / sunDistance);
    
        return mix(sunColor * sunIntensity, skyColor, 0.3);
    }
    
    float rand(vec2 co) {
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    }
    
    vec4 safeTextureSample(sampler2D tex, vec2 uv, float lod) {
        vec4 color = texture(tex, uv);
        return vec4(color.rgb, color.a);
    }
    
    vec4 colorSample(sampler2D tex, vec2 uv, bool srgbSample) {
        vec4 color = texture(tex, uv);
        if (!srgbSample) {
          return color;
        }
        return vec4(pow(color.rgb, vec3(srgb)), color.a);
    }
    
    vec4 raymarch(vec2 rayStart, vec2 rayEnd, float scale, vec2 oneOverSize, float minStepSize) {
      vec2 rayDir = normalize(rayEnd - rayStart);
      float rayLength = length(rayEnd - rayStart);
      vec2 ratio = normalize(oneOverSize);
    
      vec2 rayUv = rayStart * oneOverSize;
    
      for (float dist = 0.0; dist < rayLength;) {
        if (any(lessThan(rayUv, vec2(0.0))) || any(greaterThan(rayUv, vec2(1.0))))
          break;
    
        float df = textureLod(distanceTexture, rayUv, 0.0).r;
    
        if (df <= minStepSize) {
          vec4 sampleLight = textureLod(sceneTexture, rayUv, 0.0);
          sampleLight.rgb = pow(sampleLight.rgb, vec3(srgb));
          return sampleLight;
        }
    
        dist += df * scale;
        rayUv += rayDir * (df * scale * oneOverSize);
      }
    
      return vec4(0.0);
    }
    
    vec2 getUpperCascadeTextureUv(float index, vec2 offset, float spacingBase) {
      float upperSpacing = pow(spacingBase, cascadeIndex + 1.0);
      vec2 upperSize = floor(cascadeExtent / upperSpacing);
      vec2 upperPosition = vec2(
        mod(index, upperSpacing),
        floor(index / upperSpacing)
      ) * upperSize;
    
      vec2 clamped = clamp(offset, vec2(0.5), upperSize - 0.5);
      return (upperPosition + clamped) / cascadeExtent;
    }
    
    vec4 merge(vec4 currentRadiance, float index, vec2 position, float spacingBase, vec2 localOffset) {
      // Early return conditions
      if (currentRadiance.a > 0.0 || cascadeIndex >= max(1.0, cascadeCount - 1.0)) {
        return currentRadiance;
      }
    
      // Calculate the position within the upper cascade cell
      vec2 offset = (position + localOffset) / spacingBase;
    
      vec2 upperProbePosition = getUpperCascadeTextureUv(index, offset, spacingBase);
    
      // Sample from the next cascade
      vec3 upperSample = vec3(0);
    
      upperSample = textureLod(
        lastTexture,
        upperProbePosition,
        basePixelsBetweenProbes == 1.0 ? 0.0 : log(basePixelsBetweenProbes) / log(2.0)
      ).rgb;
    
      return currentRadiance + vec4(upperSample, 1.0);
    }
    
    void main() {
        vec2 coord = floor(vUv * cascadeExtent);
    
        float base = baseRayCount;
        float rayCount = pow(base, cascadeIndex + 1.0);
        float spacingBase = sqrt(baseRayCount);
        float spacing = pow(spacingBase, cascadeIndex);
    
        // Hand-wavy rule that improved smoothing of other base ray counts
        float modifierHack = base < 16.0 ? pow(basePixelsBetweenProbes, 1.0) : spacingBase;
    
        vec2 size = floor(cascadeExtent / spacing);
        vec2 probeRelativePosition = mod(coord, size);
        vec2 rayPos = floor(coord / size);
    
        float modifiedInterval = modifierHack * rayInterval * cascadeInterval;
    
        float start = (cascadeIndex == 0.0 ? 0.0 : pow(base, (cascadeIndex - 1.0))) * modifiedInterval;
        float end = ((1.0 + 3.0 * intervalOverlap) * (pow(base, cascadeIndex)) - pow(cascadeIndex, 2.0)) * modifiedInterval;
    
        vec2 interval = vec2(start, end);
    
        vec2 probeCenter = (probeRelativePosition + 0.5) * basePixelsBetweenProbes * spacing;
    
        float preAvgAmt = baseRayCount;
    
        // Calculate which set of rays we care about
        float baseIndex = (rayPos.x + (spacing * rayPos.y)) * preAvgAmt;
        // The angle delta (how much it changes per index / ray)
        float angleStep = TAU / rayCount;
    
        // Can we do this instead of length?
        float scale = min(resolution.x, resolution.y);
        vec2 oneOverSize = 1.0 / resolution;
        float minStepSize = min(oneOverSize.x, oneOverSize.y) * 0.5;
        float avgRecip = 1.0 / (preAvgAmt);
    
        vec2 normalizedProbeCenter = probeCenter * oneOverSize;
    
        vec4 totalRadiance = vec4(0.0);
        float noise = addNoise ? rand(vUv * (cascadeIndex + 1.0)) : 0.0;
    
        vec4 mergedRadiance = vec4(0.0);
        vec4 radiances[4] = vec4[4](vec4(0), vec4(0), vec4(0), vec4(0));
        float upperSpacing = pow(spacingBase, cascadeIndex + 1.0);
        vec2 upperSize = floor(cascadeExtent / upperSpacing);
        vec2 upperProbeRelativePosition = mod(coord, upperSize);
    
        vec2 upperProbeCenter = (floor(probeCenter - 0.5 * spacing) / 2.0) * 2.0;
    
        vec2 offset = (probeCenter / upperProbeCenter);
        vec2 weight = fract(offset);
    
        for (int i = 0; i < int(preAvgAmt); i++) {
            float index = baseIndex + float(i);
            float angle = (index + 0.5 + noise) * angleStep;
            vec2 rayDir = vec2(cos(angle), -sin(angle));
            vec2 rayStart = probeCenter + rayDir * interval.x;
            vec2 rayEnd = rayStart + rayDir * interval.y;
            vec4 raymarched = raymarch(rayStart, rayEnd, scale, oneOverSize, minStepSize);
            vec4 mergedRadiance = merge(
              raymarched, index, probeRelativePosition, spacingBase, vec2(0.5)
            );
    
            if (enableSun && cascadeIndex == cascadeCount - 1.0) {
                mergedRadiance.rgb = max(addNoise ? oldSunAndSky(angle) : sunAndSky(angle), mergedRadiance.rgb);
            }
    
            totalRadiance += mergedRadiance * avgRecip;
        }
    
        FragColor = (cascadeIndex > firstCascadeIndex)
            ? totalRadiance.rgb
            : pow(totalRadiance.rgb, vec3(1.0 / srgb));
    }
`;