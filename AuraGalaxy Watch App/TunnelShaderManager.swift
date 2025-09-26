import SpriteKit

class TunnelShaderManager {
    static let shared = TunnelShaderManager()
    private var tunnelShader: SKShader?
    private var scrollRotate = SKUniform(name: "u_scroll_progress_rotate", float: 0.0)
    private var scrollZ = SKUniform(name: "u_scroll_progress_z", float: 0.0)
    private var scrollX = SKUniform(name: "u_scroll_progress_x", float: 0.0)

    private init() {
        let uniformList = [
            SKUniform(
                name: "u_galaxy_2",
                texture: SKTexture(imageNamed: "background_2")
            ),
            scrollRotate,
            scrollZ,
            scrollX
        ]

        tunnelShader = SKShader(
            source: """
                void main() {
                    // Shift UVs by x-offset (moves center left/right)
                    vec2 uv = v_tex_coord - vec2(0.5 + u_scroll_progress_x, 0.5);
                    float r = length(uv); // Radial distance from shifted center
                    float theta = atan(uv.y, uv.x); // Angle from shifted center
                    
                    // Donut hole (black center for r < 0.1)
                    float hole_step = step(0.1, r); // 0 in hole, 1 in tunnel
                    vec4 hole_color = vec4(0.0, 0.0, 0.0, 1.0);
                    
                    // Polar UV mapping for tunnel scrolling (outward from hole)
                    vec2 tunnel_uv;
                    tunnel_uv.x = fract(0.3 / max(r, 0.1) + u_scroll_progress_z); // Radial: faster at edges for depth
                    tunnel_uv.y = fract((theta + u_scroll_progress_rotate) / 3.1415926535); // Angular rotation (normalized to [0,1])
                    
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

    func addScrollRotate(scroll: Float) {
        scrollRotate.floatValue += scroll
        print("TunnelShader scrollRotate: \(scrollRotate.floatValue)")
    }

    func addScrollZ(scroll: Float) {
        scrollZ.floatValue += scroll
        print("TunnelShader scrollZ: \(scrollZ.floatValue)")
    }

    func addScrollX(scroll: Float) {
        scrollX.floatValue += scroll
        print("TunnelShader scrollX: \(scrollX.floatValue)")
    }

    func currentTunnelOffsets() -> [(Float, Float, Float)] {
        return [(scrollRotate.floatValue, scrollZ.floatValue, scrollX.floatValue)]
    }
}
