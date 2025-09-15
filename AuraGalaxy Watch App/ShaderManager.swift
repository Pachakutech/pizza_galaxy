//
//  ShaderManager.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 9/9/25.
//

import SpriteKit

class ShaderManager {
    static let shared = ShaderManager()
    private var galaxyShader: SKShader?
    private var scrollH = SKUniform(name: "u_scroll_progress_h", float: 0.0)
    private var scrollV = SKUniform(name: "u_scroll_progress_v", float: 0.0)
    private var galaxyTextureUniform: SKUniform!
    private var appearanceUniformH: SKUniform!
    private var appearanceUniformV: SKUniform!
    private(set) var appearanceThresholdH: Float = 0.0
    private(set) var appearanceThresholdV: Float = 0.0
    private(set) var centerAlignmentValue: Float = 0.0
    private let tilePeriod: Float = 1.0  // UVs at 1X scale
    private let speedMultiplier: Float = 1.0  // Standard scroll speed
    private let repetitionPeriod: Float = 8.0  // 8 screen widths/heights
    private let initialOffset: Float = 3.0  // Start 3 widths/heights right/up

    private init() {
        // Random thresholds (3 to 10 tile periods)
        let randomNumPeriodsH = Float.random(in: 3...10)
        let randomNumPeriodsV = Float.random(in: 3...10)
        appearanceThresholdH = -randomNumPeriodsH * tilePeriod
        appearanceThresholdV = -randomNumPeriodsV * tilePeriod
        appearanceUniformH = SKUniform(
            name: "u_appearance_threshold_h",
            float: appearanceThresholdH
        )
        appearanceUniformV = SKUniform(
            name: "u_appearance_threshold_v",
            float: appearanceThresholdV
        )

        // Center when u_galaxy_1 moves 3.0 UV units
        centerAlignmentValue = initialOffset / speedMultiplier  // 3.0 / 1.0 = 3.0

        galaxyTextureUniform = SKUniform(
            name: "u_galaxy_1",
            texture: SKTexture(imageNamed: "background_level_1")
        )

        galaxyShader = SKShader(
            source: """
                void main() {
                    vec2 uv = v_tex_coord;
                    uv.x += u_scroll_progress_h;
                    uv.y += u_scroll_progress_v;

                    // Compute local scroll for u_galaxy_1, with periodicity
                    float local_scroll_h = mod(u_scroll_progress_h - u_appearance_threshold_h, \(repetitionPeriod));
                    float local_scroll_v = mod(u_scroll_progress_v - u_appearance_threshold_v, \(repetitionPeriod));

                    // u_galaxy_1 UV: non-tiling, starts at -3.0, centers at 0.0
                    vec2 uv_1 = v_tex_coord;
                    uv_1.x += local_scroll_h - \(initialOffset);
                    uv_1.y += local_scroll_v - \(initialOffset);

                    vec4 color1 = vec4(0.0);
                    float alpha1 = 0.0;
                    if (local_scroll_h >= 0.0 && local_scroll_v >= 0.0 &&
                        uv_1.x >= 0.0 && uv_1.x <= 1.0 && uv_1.y >= 0.0 && uv_1.y <= 1.0) {
                        color1 = texture2D(u_galaxy_1, uv_1);
                        // Smooth edges with smoothstep
                        float edge_h = min(smoothstep(0.0, 0.2, uv_1.x), smoothstep(1.0, 0.8, uv_1.x));
                        float edge_v = min(smoothstep(0.0, 0.2, uv_1.y), smoothstep(1.0, 0.8, uv_1.y));
                        alpha1 = edge_h * edge_v * color1.a;
                    }

                    // Tiled backgrounds
                    vec2 wrapped_uv_2 = fract(uv + 0.5);
                    vec2 wrapped_uv_3 = fract(uv + 0.3);

                    vec4 color2 = texture2D(u_galaxy_2, wrapped_uv_2);
                    vec4 color3 = texture2D(u_galaxy_3, wrapped_uv_3);

                    float blend_h = smoothstep(0.0, 0.4, mod(uv.x, 1.0));
                    float blend_v = smoothstep(0.0, 0.4, mod(uv.y, 1.0));
                    float blend = (blend_h + blend_v) * 0.3;

                    vec4 bg_color = mix(color2, color3, clamp(blend, 0.0, 1.0));
                    gl_FragColor = mix(bg_color, color1, clamp(alpha1 * 0.7, 0.0, 1.0));
                }
                """,
            uniforms: [
                galaxyTextureUniform,
                SKUniform(
                    name: "u_galaxy_2",
                    texture: SKTexture(imageNamed: "background_2")
                ),
                SKUniform(
                    name: "u_galaxy_3",
                    texture: SKTexture(imageNamed: "background_3")
                ),
                scrollH,
                scrollV,
                appearanceUniformH,
                appearanceUniformV,
            ]
        )
    }

    func getGalaxyShader() -> SKShader? {
        return galaxyShader
    }

    func addScrollH(scroll: Float) {
        scrollH.floatValue += scroll
    }

    func addScrollV(scroll: Float) {
        scrollV.floatValue += scroll
    }

    func setGalaxyTexture(forLevel level: Int) {
        let textureName = "background_level_\(level)"
        galaxyTextureUniform.textureValue = SKTexture(imageNamed: textureName)
    }

    func updateAppearanceThreshold(newValueH: Float, newValueV: Float) {
        appearanceThresholdH = newValueH
        appearanceThresholdV = newValueV
        appearanceUniformH.floatValue = newValueH
        appearanceUniformV.floatValue = newValueV
    }

    func getCumulativeScrollH() -> Float {
        return scrollH.floatValue
    }

    func getCumulativeScrollV() -> Float {
        return scrollV.floatValue
    }

    func getLocalScrollH() -> Float {
        return (scrollH.floatValue - appearanceThresholdH).truncatingRemainder(
            dividingBy: repetitionPeriod
        )
    }

    func getLocalScrollV() -> Float {
        return (scrollV.floatValue - appearanceThresholdV).truncatingRemainder(
            dividingBy: repetitionPeriod
        )
    }

    func currentGalaxyOffsets() -> [(Float, Float)] {
        return [
            (
                getLocalScrollH() - initialOffset,
                getLocalScrollV() - initialOffset
            )
        ]
    }
}
