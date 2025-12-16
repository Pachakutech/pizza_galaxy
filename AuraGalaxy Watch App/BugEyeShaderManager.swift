//
//  BugEyeShaderManager.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 12/15/25.
//

import SpriteKit

class BugEyeShaderManager {
    static let shared = BugEyeShaderManager()
    private let bugEyeShader: SKShader
    private var strength: SKUniform

    init() {
        strength = SKUniform(name: "u_strength", float: 0.0)  // Default; positive for fisheye (barrel), negative for pincushion

        let uniformList = [strength]

        bugEyeShader = SKShader(
            source: """
                void main() {
                    vec2 uv = v_tex_coord;
                    vec2 p = 2.0 * uv - 1.0;
                    float r = length(p);
                    float power = u_strength * r;
                    float distortion = 1.0 + power * (r * r);  // Or experiment with pow(r, power) for variations
                    p /= distortion;
                    uv = (p + 1.0) / 2.0;
                    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                        gl_FragColor = vec4(0.0);  // Transparent outside bounds
                    } else {
                        gl_FragColor = texture2D(u_texture, uv);
                    }
                }
                """,
            uniforms: uniformList
        )

        // Log initialization
        print("BugEye shader initialized successfully")
    }

    func getBugEyeShader() -> SKShader {
        return bugEyeShader
    }

    func setStrength(_ value: Float) {
        strength.floatValue = value
    }
}
