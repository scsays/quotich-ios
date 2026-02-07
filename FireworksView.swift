import SwiftUI
import UIKit

struct FireworksView: UIViewRepresentable {
    var duration: TimeInterval = 0.9

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            emit(in: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func emit(in view: UIView) {
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .point
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        emitter.emitterSize = CGSize(width: 1, height: 1)
        emitter.beginTime = CACurrentMediaTime()

        // Spark cell (radial burst)
        let spark = CAEmitterCell()
        spark.birthRate = 0
        spark.lifetime = 0.9
        spark.velocity = 160
        spark.velocityRange = 80
        spark.scale = 0.035
        spark.scaleRange = 0.02
        spark.emissionRange = .pi * 2
        spark.alphaSpeed = -1.2
        spark.spin = 1.2
        spark.spinRange = 2.0
        spark.contents = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal).cgImage

        // Colors (purples + white)
        let colors: [UIColor] = [
            UIColor(red: 170/255, green: 120/255, blue: 255/255, alpha: 1),
            UIColor(red: 140/255, green: 90/255,  blue: 230/255, alpha: 1),
            UIColor(white: 1.0, alpha: 1.0)
        ]

        let cells: [CAEmitterCell] = colors.map { color in
            let c = spark.copy() as! CAEmitterCell
            c.color = color.cgColor
            c.birthRate = 220
            return c
        }

        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)

        // Stop emission quickly and remove layer after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            emitter.removeFromSuperlayer()
        }
    }
}

// Convenience preview (optional)
#if DEBUG
struct FireworksView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.1)
            FireworksView()
                .frame(width: 140, height: 140)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
