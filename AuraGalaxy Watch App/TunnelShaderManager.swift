import SpriteKit

class TunnelShaderManager {
    static let shared = TunnelShaderManager()
    private var tunnelShader: SKShader?
    private var scrollH = SKUniform(name: "u_scroll_progress_h", float: 0.0)
    private var scrollV = SKUniform(name: "u_scroll_progress_v", float: 0.0)

    private init() {
        let uniformList = [
            SKUniform(
                name: "u_galaxy_2",
                texture: SKTexture(imageNamed: "background_2")
            ),
            scrollH,
            scrollV
        ]

        // Step 0: Baseline (your working Test 4 with explicit centering - should work)
//        tunnelShader = SKShader(
//            source: """
//                void main() {
//                    vec2 uv = v_tex_coord; // No centering yet
//                    vec2 tunnel_uv;
//                    tunnel_uv.x = uv.x + u_scroll_progress_v;
//                    tunnel_uv.y = uv.y + u_scroll_progress_h;
//                    vec4 color = texture2D(u_galaxy_2, fract(tunnel_uv));
//                    gl_FragColor = vec4(color.rgb, 1.0);
//                }
//                """,
//            uniforms: uniformList
//        )

        // Step 1: Add centering (subtract 0.5) - centers the scroll on screen middle (should work)
//        tunnelShader = SKShader(
//            source: """
//                void main() {
//                    vec2 uv = v_tex_coord - vec2(0.5); // Center UVs
//                    vec2 tunnel_uv;
//                    tunnel_uv.x = uv.x + u_scroll_progress_v;
//                    tunnel_uv.y = uv.y + u_scroll_progress_h;
//                    vec4 color = texture2D(u_galaxy_2, fract(tunnel_uv));
//                    gl_FragColor = vec4(color.rgb, 1.0);
//                }
//                """,
//            uniforms: uniformList
//        )

        // Step 2: Add polar coordinates (compute r and theta, but don't use yet - tests if math functions work)
//        tunnelShader = SKShader(
//            source: """
//                void main() {
//                    vec2 uv = v_tex_coord - vec2(0.5); // Center UVs
//                    float r = length(uv); // Radial distance
//                    float theta = atan(uv.y, uv.x); // Angle
//                    vec2 tunnel_uv;
//                    tunnel_uv.x = uv.x + u_scroll_progress_v;
//                    tunnel_uv.y = uv.y + u_scroll_progress_h;
//                    vec4 color = texture2D(u_galaxy_2, fract(tunnel_uv));
//                    gl_FragColor = vec4(color.rgb, 1.0); // Ignore r/theta for now
//                }
//                """,
//            uniforms: uniformList
//        )

        // Step 3: Add donut hole (black center using step/mix - no conditionals)
//        tunnelShader = SKShader(
//            source: """
//                void main() {
//                    vec2 uv = v_tex_coord - vec2(0.5); // Center UVs
//                    float r = length(uv); // Radial distance
//                    float theta = atan(uv.y, uv.x); // Angle (unused for now)
//                    
//                    // Donut hole (black for r < 0.1)
//                    float hole_step = step(0.1, r); // 0 in hole (r < 0.1), 1 outside
//                    vec4 hole_color = vec4(0.0, 0.0, 0.0, 1.0); // Black hole
//                    
//                    vec2 tunnel_uv;
//                    tunnel_uv.x = uv.x + u_scroll_progress_v;
//                    tunnel_uv.y = uv.y + u_scroll_progress_h;
//                    vec4 tunnel_color = texture2D(u_galaxy_2, fract(tunnel_uv));
//                    
//                    // Blend: hole inside, texture outside
//                    gl_FragColor = mix(hole_color, tunnel_color, hole_step);
//                }
//                """,
//            uniforms: uniformList
//        )

        // Step 4: Add polar UV mapping (remap UVs to polar for tunnel effect - full "diving" illusion)
        tunnelShader = SKShader(
            source: """
                void main() {
                    vec2 uv = v_tex_coord - vec2(0.5); // Center UVs
                    float r = length(uv); // Radial distance from center
                    float theta = atan(uv.y, uv.x); // Angle for polar coords
                    
                    // Donut hole (black center for r < 0.1)
                    float hole_step = step(0.1, r); // 0 in hole, 1 in tunnel
                    vec4 hole_color = vec4(0.0, 0.0, 0.0, 1.0);
                    
                    // Polar UV mapping for tunnel scrolling (outward from hole)
                    vec2 tunnel_uv;
                    tunnel_uv.x = fract(0.3 / max(r, 0.1) + u_scroll_progress_v); // Radial: faster at edges for depth
                    tunnel_uv.y = fract((theta + u_scroll_progress_h) / 3.1415926535); // Angular rotation (normalized to [0,1])
                    
                    // Sample texture with wrapped UVs (seamless tiling)
                    vec4 tunnel_color = texture2D(u_galaxy_2, fract(tunnel_uv));
                    
                    // Blend hole and tunnel
                    gl_FragColor = mix(hole_color, tunnel_color, hole_step);
                }
                """,
            uniforms: uniformList
        )

        // Log initialization
        if tunnelShader == nil {
            print("Error: Tunnel shader failed to initialize")
        } else {
            print("Tunnel shader initialized successfully")
        }
        let texture2 = SKTexture(imageNamed: "background_2")
        let texture3 = SKTexture(imageNamed: "background_3")
        print("Texture background_2 loaded: \(texture2 != nil)")
        print("Texture background_3 loaded: \(texture3 != nil)")
    }

    func getTunnelShader() -> SKShader? {
        return tunnelShader
    }

    func addScrollH(scroll: Float) {
        scrollH.floatValue += scroll
        print("TunnelShader scrollH: \(scrollH.floatValue)")
    }

    func addScrollV(scroll: Float) {
        scrollV.floatValue += scroll
        print("TunnelShader scrollV: \(scrollV.floatValue)")
    }

    func currentTunnelOffsets() -> [(Float, Float)] {
        return [(scrollH.floatValue, scrollV.floatValue)]
    }
}
