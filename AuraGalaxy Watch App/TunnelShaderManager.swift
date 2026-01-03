//
//  TunnelShaderManager.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 9/10/25.
//

import SpriteKit

class TunnelShaderManager {
    static let shared = TunnelShaderManager()
    private let tunnelShader: SKShader
    private var scrollRotate = SKUniform(name: "u_scroll_progress_rotate", float: 0.0)
    private var scrollZ = SKUniform(name: "u_scroll_progress_z", float: 0.0)
    private var scrollX = SKUniform(name: "u_scroll_progress_x", float: 0.0)
    private var scrollBackgroundX = SKUniform(name: "u_scroll_background_x", float: 0.0)
    private var galaxyTextureUniform: SKUniform
    private var backgroundTexture2Uniform: SKUniform

    init() {
        let texture2 = SKTexture(imageNamed: "deep_field")
        let galaxyTexture = SKTexture(imageNamed: "background_level_1")
        let backgroundTexture2 = SKTexture(imageNamed: "background_3")
        galaxyTextureUniform = SKUniform(name: "u_background", texture: galaxyTexture)
        backgroundTexture2Uniform = SKUniform(name: "u_background_2", texture: backgroundTexture2)

        let uniformList = [
            galaxyTextureUniform,
            backgroundTexture2Uniform,
            SKUniform(name: "u_galaxy_2", texture: texture2),
            scrollRotate,
            scrollZ,
            scrollX,
            scrollBackgroundX
        ]

        tunnelShader = SKShader(
            source: """
                void main() {
                    // Shift UVs by x-offset (moves center left/right)
                    vec2 uv = v_tex_coord - vec2(0.5 + u_scroll_progress_x, 0.5);
                    float r = length(uv); // Radial distance from shifted center
                    float theta = atan(uv.y, uv.x); // Angle from shifted center
                    
                    // Donut hole and annulus (r < 0.1 is hole, 0.1 <= r < 0.2 is gradient)
                    float hole_alpha = smoothstep(0.1, 0.2, r); // 0 at r=0.1, 1 at r=0.2
                    vec2 bg_uv = v_tex_coord + vec2(u_scroll_background_x, 0.0); // Scroll background left/right
                    vec2 bg_uv_1 = fract(bg_uv); // Wrap first background
                    vec2 bg_uv_2 = fract(bg_uv + vec2(0.2, 0.0)); // Wrap second background with smaller offset
                    vec4 bg_color1 = texture2D(u_background, bg_uv_1); // background_level_1
                    vec4 bg_color2 = texture2D(u_background_2, bg_uv_2); // background_3
                    float blend = smoothstep(0.2, 0.8, mod(bg_uv.x, 1.0)); // Adjusted blend to favor bg_color1
                    vec4 hole_color = mix(bg_color1, bg_color2, clamp(blend * 0.3, 0.0, 1.0)); // Reduced blend weight
                    
                    // Polar UV mapping for tunnel scrolling (outward from hole)
                    vec2 tunnel_uv;
                    tunnel_uv.x = fract(0.3 / max(r, 0.1) + u_scroll_progress_z); // Radial: faster at edges for depth
                    tunnel_uv.y = fract((theta + u_scroll_progress_rotate) / 3.1415926535); // Angular rotation (normalized to [0,1])
                    
                    // Sample tunnel texture with wrapped UVs (seamless tiling)
                    vec4 tunnel_color = texture2D(u_galaxy_2, fract(tunnel_uv));
                    
                    // Blend hole (background) and tunnel with alpha gradient
                    gl_FragColor = mix(hole_color, tunnel_color, hole_alpha);
                }
                """,
            uniforms: uniformList
        )

        // Log initialization
        print("Tunnel shader initialized successfully")
    }

    func getTunnelShader() -> SKShader {
        return tunnelShader
    }

    func setGalaxyTexture(forLevel level: Int) {
        let textureName = "background_level_\(level)"
        let texture = SKTexture(imageNamed: textureName)
        guard texture != nil else {
            print("Warning: Failed to load texture \(textureName)")
            return
        }
        galaxyTextureUniform.textureValue = texture
    }

    func addScrollRotate(scroll: Float) {
        scrollRotate.floatValue += scroll
    }

    func addScrollZ(scroll: Float) {
        scrollZ.floatValue += scroll
    }

    func addScrollX(scroll: Float) {
        scrollX.floatValue += scroll
    }

    func setScrollBackgroundX(scroll: Float) {
        scrollBackgroundX.floatValue = scroll
    }

    func currentTunnelOffsets() -> [(Float, Float, Float, Float)] {
        return [(scrollRotate.floatValue, scrollZ.floatValue, scrollX.floatValue, scrollBackgroundX.floatValue)]
    }

    func isOutOfBounds() -> Bool {
        abs(scrollX.floatValue) > 0.5 || abs(scrollBackgroundX.floatValue) > 0.4
    }

    func reset() {
        scrollX.floatValue = 0.0
        scrollZ.floatValue = 0.0
        scrollBackgroundX.floatValue = 0.0
    }
}
