//
//  TunnelShaderManager.swift
//  AuraGalaxy
//

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
            SKUniform(
                name: "u_galaxy_3",
                texture: SKTexture(imageNamed: "background_3")
            ),
            scrollH,
            scrollV
        ]

        tunnelShader = SKShader(
            source: """
                void main() {
                    vec2 uv = v_tex_coord - 0.5; // Center UVs
                    
                    // Polar coordinates
                    float r = length(uv);
                    float theta = atan(uv.y, uv.x);
                    
                    // Skip center (donut hole)
                    if (r < 0.1) {
                        gl_FragColor = vec4(0.0);
                        return;
                    }
                    
                    // Tunnel UVs: radial depth (1/r for perspective) + angular wrap
                    vec2 tunnel_uv;
                    tunnel_uv.x = fract(0.1 / r + u_scroll_progress_v); // Radial scroll
                    tunnel_uv.y = fract((theta + u_scroll_progress_h) / 3.1415926535 * 0.5); // Angular scroll (wrap every 360°)
                    
                    // Sample and blend textures
                    vec2 wrapped_uv_2 = fract(tunnel_uv + 0.5);
                    vec2 wrapped_uv_3 = fract(tunnel_uv + 0.3);
                    
                    vec4 color2 = texture2D(u_galaxy_2, wrapped_uv_2);
                    vec4 color3 = texture2D(u_galaxy_3, wrapped_uv_3);
                    
                    float blend_h = smoothstep(0.0, 0.4, mod(tunnel_uv.x, 1.0));
                    float blend_v = smoothstep(0.0, 0.4, mod(tunnel_uv.y, 1.0));
                    float blend = (blend_h + blend_v) * 0.3;
                    
                    vec4 tunnel_color = mix(color2, color3, clamp(blend, 0.0, 1.0));
                    
                    // Fade based on radius (darker near edges, hole in center)
                    float fade = smoothstep(0.1, 0.9, 1.0 - r); // 1.0 at edge, 0.0 at center
                    gl_FragColor = tunnel_color * fade;
                }
                """,
            uniforms: uniformList
        )
    }

    func getTunnelShader() -> SKShader? {
        return tunnelShader
    }

    func addScrollH(scroll: Float) {
        scrollH.floatValue += scroll
    }

    func addScrollV(scroll: Float) {
        scrollV.floatValue += scroll
    }
}
