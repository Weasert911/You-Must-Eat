shader_type canvas_item;


// ----------------------
// PS1 / LOW RES LOOK
// ----------------------

uniform float pixel_size = 3;
uniform float color_depth = 16.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;


// ----------------------
// CRT GLASS
// ----------------------

uniform float curvature = 3.0;
uniform float bulge = 0.45;
uniform float vignette_strength = 0.35;


// ----------------------
// SCANLINES
// ----------------------

uniform float scanline_opacity = 0.45;
uniform float scanline_count = 240.0;


// ----------------------
// SIGNAL
// ----------------------

uniform float signal_jitter = 0.0015;
uniform float rolling_bar_speed = 0.15;
uniform float static_amount = 0.025;


// ----------------------
// GLITCH SEQUENCE
// ----------------------

uniform float sequence_progress : hint_range(0.0,10.0) = 0.0;


// ----------------------
// GREEN PHOSPHOR
// ----------------------

uniform vec3 green_tint : source_color = vec3(0.2,1.0,0.3);


// ----------------------
// DITHER
// ----------------------

const mat4 dither_table = mat4(
vec4(0.0,0.5,0.125,0.625),
vec4(0.75,0.25,0.875,0.375),
vec4(0.1875,0.6875,0.0625,0.5625),
vec4(0.9375,0.4375,0.8125,0.3125)
);


float rand(vec2 co){
    return fract(sin(dot(co,vec2(12.9898,78.233))) * 43758.5453);
}


// ----------------------
// CONVEX CRT
// ----------------------

vec2 curve(vec2 uv){

    vec2 p = uv * 2.0 - 1.0;

    float r = dot(p,p);

    p *= 1.0 + r * bulge;

    p.x *= 1.0 + pow(abs(p.y)/curvature,2.0);
    p.y *= 1.0 + pow(abs(p.x)/curvature,2.0);

    return p * 0.5 + 0.5;
}


void fragment(){

    vec2 crt_uv = curve(SCREEN_UV);


    // -------------------
    // CRT BEZEL
    // -------------------

    if(crt_uv.x < 0.0 || crt_uv.x > 1.0 || crt_uv.y < 0.0 || crt_uv.y > 1.0){

        COLOR = vec4(0.0,0.0,0.0,1.0);

    } else {

        vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;

        vec2 grid_uv =
        round(crt_uv * screen_res / float(pixel_size))
        / (screen_res / float(pixel_size));


        // -------------------
        // SIGNAL JITTER
        // -------------------

        grid_uv.x += sin(TIME * 120.0 + grid_uv.y * 80.0) * signal_jitter;


        // -------------------
        // CAMERA SWITCH GLITCH
        // -------------------

        if(sequence_progress > 0.0){

            float strength = smoothstep(0.0,2.0,sequence_progress);

            // horizontal sync loss
            float tear = step(0.96, sin(TIME * 4.0 + grid_uv.y * 80.0));

            grid_uv.x += tear * 0.05 * strength;

            // brief vertical misalignment
            grid_uv.y += sin(TIME * 40.0) * 0.003 * strength;

        }


        // -------------------
        // SAMPLE IMAGE
        // -------------------

        vec3 color = texture(screen_texture, grid_uv).rgb;


        // -------------------
        // GREEN PHOSPHOR
        // -------------------

        float luminance = dot(color, vec3(0.299,0.587,0.114));

        color = luminance * green_tint;


        // -------------------
        // STATIC
        // -------------------

        float noise = rand(FRAGCOORD.xy + TIME * 30.0);

        color += (noise - 0.5) * static_amount;


        // -------------------
        // DITHER
        // -------------------

        ivec2 uv_int = ivec2(FRAGCOORD.xy / float(pixel_size));

        float dither_val = dither_table[uv_int.x % 4][uv_int.y % 4];

        color += (dither_val - 0.5) / color_depth;


        // -------------------
        // COLOR BANDING
        // -------------------

        color = floor(color * color_depth) / color_depth;


        // -------------------
        // SCANLINES
        // -------------------

        float scanline = sin(crt_uv.y * scanline_count * PI * 2.0);

        scanline = scanline * 0.5 + 0.5;

        color *= mix(1.0, scanline, scanline_opacity);


        // -------------------
        // ROLLING SYNC BAR
        // -------------------

        float bar = sin((crt_uv.y + TIME * rolling_bar_speed) * 8.0);

        color *= 0.92 + 0.08 * bar;


        // -------------------
        // VIGNETTE
        // -------------------

        float dist = distance(crt_uv, vec2(0.5));

        color *= smoothstep(0.75, vignette_strength, dist);


        COLOR = vec4(color,1.0);
    }
}
