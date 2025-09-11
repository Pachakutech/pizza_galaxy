//
//  ShaderManager.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 9/9/25.
//


import SpriteKit

let metalShaderSource = """
#include <metal_stdlib>
#include <SpriteKit/SpriteKit.h>

using namespace metal;

fragment float4 galaxyBlendFragment(SKNodegraphicVertexOut in [[stage_in]],
                                    texture2d<float> u_galaxy_1 [[texture(0)]],
                                    texture2d<float> u_galaxy_2 [[texture(1)]],
                                    float u_scroll_progress_h [[buffer(0)]],
                                    float u_scroll_progress_v [[buffer(1)]]) {
    vec2 uv = in.texture_coord;
    uv.x += u_scroll_progress_h;
    uv.y += u_scroll_progress_v;

    vec2 wrapped_uv_1 = fract(uv);
    vec2 wrapped_uv_2 = fract(uv + 0.5);

    constexpr sampler s(address::repeat, filter::linear);
    vec4 color1 = u_galaxy_1.sample(s, wrapped_uv_1);
    vec4 color2 = u_galaxy_2.sample(s, wrapped_uv_2);

    float blend_h = smoothstep(0.0, 0.2, mod(uv.x, 1.0));
    blend_h = smoothstep(1.0, 0.8, mod(uv.x, 1.0)) * blend_h;

    float blend_v = smoothstep(0.0, 0.2, mod(uv.y, 1.0));
    blend_v = smoothstep(1.0, 0.8, mod(uv.y, 1.0)) * blend_v;

    return mix(color1, color2, (blend_h + blend_v) / 2.0);
}
"""


let metalShaderSourceMinimal = """
#include <metal_stdlib>
#include <SpriteKit/SpriteKit.h>

using namespace metal;

fragment float4 minimalFragment(SKNodegraphicVertexOut in [[stage_in]]) {
    return float4(1.0, 0.0, 0.0, 1.0);
}
"""
class ShaderManager {
    static let shared = ShaderManager()
    private var galaxyShader: SKShader?

    private init() {
            
      galaxyShader = SKShader(
        source: metalShaderSourceMinimal,
        //        uniforms: [
//            SKUniform(
//                name: "u_galaxy_1",
//                texture: SKTexture(imageNamed: "background_1")
//            ),
//            SKUniform(name: "u_galaxy_2", texture: SKTexture(imageNamed: "background_2")),
//            SKUniform(name: "u_scroll_progress_h", float: 0.0),
//            SKUniform(name: "u_scroll_progress_v", float: 0.0)
//        ]
)
    }

    func getGalaxyShader() -> SKShader? {
        return galaxyShader
    }
}
