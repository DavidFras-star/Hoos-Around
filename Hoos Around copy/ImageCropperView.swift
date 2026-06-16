import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let aspectRatio: CGFloat      // e.g. 1.0 for square
    let cornerRadius: CGFloat     // e.g. 24
    let onCancel: () -> Void
    let onCrop: (UIImage) -> Void

    @State private var scale: CGFloat = 1.1
    @State private var lastScale: CGFloat = 1.1

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let container = geo.size
                let minSide = min(container.width, container.height)
                if !container.width.isFinite || !container.height.isFinite || minSide <= 1 {
                    Color.black.ignoresSafeArea()
                    ProgressView().tint(.white)
                } else {
                    let ar = max(aspectRatio, 0.0001)
                    let cropW = minSide * 0.86
                    let cropH = cropW / ar

                    if cropW.isFinite, cropH.isFinite, cropW > 0, cropH > 0 {
                        ZStack {
                            Rectangle()
                                .fill(Color.black.opacity(0.55))
                                .ignoresSafeArea()

                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
                                .frame(width: cropW, height: cropH)
                                .blendMode(.normal)
                                .overlay {
                                    CroppingCanvas(
                                        image: image,
                                        cropSize: CGSize(width: cropW, height: cropH),
                                        cornerRadius: cornerRadius,
                                        scale: scale,
                                        offset: clampedOffset(
                                            for: CGSize(width: offset.width, height: offset.height),
                                            cropSize: CGSize(width: cropW, height: cropH)
                                        )
                                    )
                                    .allowsHitTesting(false)
                                }
                                .overlay {
                                    GridOverlay()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                                        .frame(width: cropW, height: cropH)
                                }
                                .mask(
                                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                        .frame(width: cropW, height: cropH)
                                )
                                .contentShape(Rectangle())
                                .gesture(dragGesture(cropSize: CGSize(width: cropW, height: cropH)))
                                .simultaneousGesture(magnificationGesture())
                        }
                        .frame(width: container.width, height: container.height, alignment: .center)
                    } else {
                        Color.black.ignoresSafeArea()
                        ProgressView().tint(.white)
                    }
                }
            }

            VStack {
                HStack {
                    Button("Cancel") { onCancel() }
                        .font(.headline)
                        .padding(12)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                    Button("Use Photo") {
                        exportCroppedImage { output in
                            onCrop(output)
                        }
                    }
                    .font(.headline)
                    .padding(12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.top, 14)

                Spacer()
            }
        }
        .statusBar(hidden: true)
    }

    // MARK: - Gestures

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let new = (lastScale * value).clamped(to: 0.8...6.0)
                scale = new
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private func dragGesture(cropSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(width: lastOffset.width + value.translation.width,
                                      height: lastOffset.height + value.translation.height)
                offset = clampedOffset(for: proposed, cropSize: cropSize)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    // MARK: - Clamp math

    private func clampedOffset(for proposed: CGSize, cropSize: CGSize) -> CGSize {
        guard cropSize.width.isFinite, cropSize.height.isFinite, cropSize.width > 0, cropSize.height > 0 else {
            return .zero
        }

        let imgW = image.size.width
        let imgH = image.size.height
        guard imgW > 0, imgH > 0 else {
            return .zero
        }

        let baseScale = max(cropSize.width / imgW, cropSize.height / imgH)
        let totalScale = baseScale * scale

        guard totalScale.isFinite else {
            return .zero
        }

        let contentW = imgW * totalScale
        let contentH = imgH * totalScale

        let maxX = max((contentW - cropSize.width) / 2, 0)
        let maxY = max((contentH - cropSize.height) / 2, 0)

        let clampedX = proposed.width.clamped(to: -maxX...maxX)
        let clampedY = proposed.height.clamped(to: -maxY...maxY)
        return CGSize(width: clampedX, height: clampedY)
    }

    // MARK: - Export

    private func exportCroppedImage(completion: (UIImage) -> Void) {
        let exportSide: CGFloat = 1024
        let ar = max(aspectRatio, 0.0001)
        let exportSize = CGSize(width: exportSide, height: exportSide / ar)

        guard exportSize.width.isFinite, exportSize.height.isFinite, exportSize.width > 0, exportSize.height > 0 else {
            completion(image)
            return
        }

        let imgW = image.size.width
        let imgH = image.size.height
        guard imgW > 0, imgH > 0 else {
            completion(image)
            return
        }

        let renderer = UIGraphicsImageRenderer(size: exportSize)
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: exportSize))

            let clipPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: exportSize),
                                        cornerRadius: cornerRadius)
            clipPath.addClip()

            let baseScale = max(exportSize.width / imgW, exportSize.height / imgH)
            let totalScale = baseScale * scale

            guard totalScale.isFinite else {
                completion(image)
                return
            }

            let contentW = imgW * totalScale
            let contentH = imgH * totalScale

            let originX = (exportSize.width - contentW) / 2 + offset.width
            let originY = (exportSize.height - contentH) / 2 + offset.height

            image.draw(in: CGRect(x: originX, y: originY, width: contentW, height: contentH))
        }
        completion(img)
    }
}

// MARK: - Helpers

private struct CroppingCanvas: View {
    let image: UIImage
    let cropSize: CGSize
    let cornerRadius: CGFloat
    let scale: CGFloat
    let offset: CGSize

    var body: some View {
        GeometryReader { _ in
            let img = Image(uiImage: image)
            img
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: fittedSize.width * scale, height: fittedSize.height * scale)
                .offset(offset)
                .frame(width: cropSize.width, height: cropSize.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .frame(width: cropSize.width, height: cropSize.height)
    }

    private var fittedSize: CGSize {
        let iw = image.size.width
        let ih = image.size.height
        let s = max(cropSize.width / iw, cropSize.height / ih)
        return CGSize(width: iw * s, height: ih * s)
    }
}

// MARK: - Grid Overlay
private struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let thirdW = rect.width / 3
        p.move(to: CGPoint(x: thirdW, y: 0))
        p.addLine(to: CGPoint(x: thirdW, y: rect.height))
        p.move(to: CGPoint(x: 2 * thirdW, y: 0))
        p.addLine(to: CGPoint(x: 2 * thirdW, y: rect.height))
        let thirdH = rect.height / 3
        p.move(to: CGPoint(x: 0, y: thirdH))
        p.addLine(to: CGPoint(x: rect.width, y: thirdH))
        p.move(to: CGPoint(x: 0, y: 2 * thirdH))
        p.addLine(to: CGPoint(x: rect.width, y: 2 * thirdH))
        return p
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

