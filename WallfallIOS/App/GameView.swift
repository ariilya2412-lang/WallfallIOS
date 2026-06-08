import SpriteKit
import SwiftUI

struct GameView: View {
    @State private var scene = SkylineRushScene(size: CGSize(width: 390, height: 844))

    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .onAppear {
                    scene.scaleMode = .resizeFill
                    scene.size = proxy.size
                }
                .onChange(of: proxy.size) { _, newSize in
                    scene.size = newSize
                    scene.relayout()
                }
        }
    }
}
