//
//  DistortionCircle.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 12/20/25.
//

import SpriteKit

@MainActor
class DistortionCircle: SKEffectNode {
    static let backgroundTexture = SKTexture(imageNamed: "square_galaxy")
//    static let backgroundTexture = SKTexture(imageNamed: "deep_field")
    override init() {
        super.init()
        addChild(
            SKSpriteNode(
                texture: SKTexture(imageNamed: "black_circle"),
                color: .clear,
                size: CGSize(width: 40, height: 40)
            )
        )
        shader = DistortionCircle.sharedShader
        setValue(SKAttributeValue(float: 23.5), forAttribute: "a_strength")

        setValue(
            SKAttributeValue(
                vectorFloat2: vector_float2(Float(1 / 2), Float(1 / 2))
            ),
            forAttribute: "a_offset"
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static let sharedShader: SKShader = {
        let strength = SKAttribute(name: "a_strength", type: .float)  // Default; positive for fisheye (barrel), negative for pincushion
        let offset = SKAttribute(
            name: "a_offset",
            type: .vectorFloat2,
        )  // positive for fisheye (barrel), negative for pincushion
        let backgroundUniforms = [SKUniform(name: "u_background", texture: backgroundTexture)]
        
        let bugEyeShader = SKShader(
            source: """
                void main() {
                    float strength = a_strength; 
                    vec2 offset = a_offset;

                    // 1. Bug eye distortion
                    vec2 local_uv = v_tex_coord;
                    vec2 p = 2.0 * local_uv - 1.0;
                    float r = length(p);
                    float power = strength * r;
                    float distortion = 1.0 + power * (r * r);
                    p /= distortion;
                    
                    // Convert distorted p back to local 0.0-1.0 range
                    vec2 distorted_local_uv = (p + 1.0) / 2.0;

                    // 2. Map Local to Large Background
                    vec2 bg_uv = offset + (distorted_local_uv - 0.5) * 0.66;

                    // 3. Sampling
                    if (distorted_local_uv.x < 0.0 || distorted_local_uv.x > 1.0 || 
                        distorted_local_uv.y < 0.0 || distorted_local_uv.y > 1.0 ||
                        r > 1.0) {
                        gl_FragColor = vec4(0.0);
                    } else {
                        gl_FragColor = texture2D(u_background, bg_uv);
                    }
                }
                """,
        )
        bugEyeShader.attributes = [strength, offset]
        bugEyeShader.uniforms = backgroundUniforms
        return bugEyeShader
    }()
}
