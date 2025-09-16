//
//  TunnelShaderManager.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 9/15/25.
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
                    vec2 uv = v_tex_coord - 0.5;

                    float r = length(uv);
                    float a = atan(uv.y, uv.x) + u_scroll_progress_h;

                    if (r > 0.0) {
                        vec2 tunnel_uv = vec2(0.1 / r + u_scroll_progress_v, a / 3.1415926535);

                        vec2 wrapped_uv_2 = fract(tunnel_uv + 0.5);
                        vec2 wrapped_uv_3 = fract(tunnel_uv + 0.3);

                        vec4 color2 = texture2D(u_galaxy_2, wrapped_uv_2);
                        vec4 color3 = texture2D(u_galaxy_3, wrapped_uv_3);

                        float blend_h = smoothstep(0.0, 0.4, mod(tunnel_uv.x, 1.0));
                        float blend_v = smoothstep(0.0, 0.4, mod(tunnel_uv.y, 1.0));
                        float blend = (blend_h + blend_v) * 0.3;

                        vec4 bg_color = mix(color2, color3, clamp(blend, 0.0, 1.0));

                        gl_FragColor = bg_color * (1.0 - r); // Fade to black in center for donut hole
                    } else {
                        gl_FragColor = vec4(0.0);
                    }
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
