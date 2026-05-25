import SwiftUI
import UIKit
import Vision

/// Drop-in replacement for AsyncImage that crops to the salient region of
/// the image — face if there is one, attention-based saliency otherwise,
/// centre-crop as a final fallback.
///
/// Wikipedia portraits routinely have the subject's head in the top third
/// of the frame; aspectRatio(.fill).clipped() slices the head off. Vision
/// gives us the right crop on-device, no network cost.
///
/// Caches the computed crop rect (not the bytes) keyed by URL in
/// SmartCropCache so we don't re-run Vision per frame.
struct SmartImageView<FailureView: View>: View {
    let url: URL
    /// The aspect ratio + crop-target size. If `fillParent` is true the view
    /// expands to fill its parent's width while preserving the aspect.
    let size: CGSize
    var cornerRadius: CGFloat = 10
    var fillParent: Bool = false
    /// What to show when the image fails to load (404, decode error, etc.).
    /// Trending tiles pass a LetterTile here so a missing image still looks
    /// branded; result rows / knowledge panels pass the default grey
    /// placeholder with a photo glyph.
    let failureView: () -> FailureView

    @State private var image: UIImage? = nil
    @State private var cropRect: CGRect? = nil   // in image-space pixels
    @State private var failed = false

    var body: some View {
        Group {
            if let image, let cropRect {
                renderedImage(cropped(image, to: cropRect))
            } else if let image {
                renderedImage(image)
            } else if failed {
                failureView()
            } else {
                placeholder.overlay(ProgressView().controlSize(.small))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: url) { await load() }
    }

    @ViewBuilder
    private func renderedImage(_ image: UIImage) -> some View {
        if fillParent {
            // Color.clear is the size authority — it respects whatever
            // width the parent offers (capped at maxWidth: .infinity) and
            // takes the requested height. The Image overlays at .fill so
            // it never letterboxes; the .clipped() crops the overflow.
            //
            // This pattern avoids the SwiftUI gotcha where
            // Image.resizable().aspectRatio(_, .fill) propagates a
            // *larger-than-parent* width proposal up the tree, expanding
            // ancestors and breaking horizontal padding.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: size.height)
                .overlay(
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                )
                .clipped()
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if fillParent {
            Color.secondary.opacity(0.10)
                .aspectRatio(size.width / size.height, contentMode: .fit)
        } else {
            Color.secondary.opacity(0.10)
                .frame(width: size.width, height: size.height)
        }
    }

    private func load() async {
        // Reset for the id-keyed task variant when URL changes.
        image = nil; cropRect = nil; failed = false

        // 1. Did we already compute a crop for this URL? Apply it as soon as
        // the image bytes arrive — no Vision run needed.
        let cachedRect = await SmartCropCache.shared.get(url)

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let img = UIImage(data: data) else {
                await MainActor.run { failed = true }
                return
            }
            await MainActor.run { self.image = img }

            if let cached = cachedRect {
                await MainActor.run { self.cropRect = cached }
                return
            }
            // 2. No cache → run Vision off the main actor, then publish.
            let detected = await Self.detectSalientRect(in: img, target: size)
            await SmartCropCache.shared.put(url, rect: detected)
            await MainActor.run { self.cropRect = detected }
        } catch {
            await MainActor.run { failed = true }
        }
    }

    /// Run face detection first (precise where there is a face); fall back to
    /// attention-based saliency; final fallback is a centre crop.
    static func detectSalientRect(in image: UIImage, target: CGSize) async -> CGRect {
        guard let cg = image.cgImage else { return centreCropRect(image: image, target: target) }
        let imgW = CGFloat(cg.width)
        let imgH = CGFloat(cg.height)

        // Vision returns normalised coords with origin bottom-left. Convert
        // to top-left pixel space for UIKit/CoreGraphics cropping.
        func denorm(_ box: CGRect) -> CGRect {
            CGRect(x: box.origin.x * imgW,
                   y: (1 - box.origin.y - box.size.height) * imgH,
                   width: box.size.width * imgW,
                   height: box.size.height * imgH)
        }

        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:])

        // Faces first.
        let faceRequest = VNDetectFaceRectanglesRequest()
        try? handler.perform([faceRequest])
        if let faces = faceRequest.results, !faces.isEmpty {
            // Union of all face boxes, in case there are multiple subjects.
            let union = faces.reduce(CGRect.null) { acc, obs in
                acc.union(obs.boundingBox)
            }
            let pixelBox = denorm(union)
            return cropRect(around: pixelBox,
                             imageSize: CGSize(width: imgW, height: imgH),
                             target: target,
                             // Faces want generous head/shoulders padding.
                             paddingFactor: 2.4,
                             // Bias upward so the head sits in upper-third
                             // of the crop, not dead-centre.
                             verticalBias: -0.12)
        }

        // No faces → attention-based saliency.
        let attnRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        try? handler.perform([attnRequest])
        if let obs = attnRequest.results?.first,
           let salient = obs.salientObjects?.first {
            let pixelBox = denorm(salient.boundingBox)
            return cropRect(around: pixelBox,
                             imageSize: CGSize(width: imgW, height: imgH),
                             target: target,
                             paddingFactor: 1.2,
                             verticalBias: 0)
        }

        return centreCropRect(image: image, target: target)
    }

    /// Build a crop rect of the right aspect ratio that contains `box`,
    /// expanded by `paddingFactor`, biased vertically (negative = up),
    /// clamped to image bounds.
    static func cropRect(around box: CGRect,
                          imageSize: CGSize,
                          target: CGSize,
                          paddingFactor: CGFloat,
                          verticalBias: CGFloat) -> CGRect {
        let aspect = target.width / target.height

        // Start from the centre of the salient box, with padding around it.
        let cx = box.midX
        let cy = box.midY + box.height * verticalBias

        // Desired crop is the box scaled by paddingFactor, then aspect-fit.
        let baseW = box.width  * paddingFactor
        let baseH = box.height * paddingFactor
        var w = max(baseW, baseH * aspect)
        var h = max(baseH, baseW / aspect)
        // Make sure we don't crop a region larger than the image.
        w = min(w, imageSize.width)
        h = min(h, imageSize.height)
        // Re-establish aspect after clamping.
        if w / h > aspect { w = h * aspect } else { h = w / aspect }

        var x = cx - w / 2
        var y = cy - h / 2
        // Clamp.
        x = max(0, min(x, imageSize.width  - w))
        y = max(0, min(y, imageSize.height - h))
        return CGRect(x: x, y: y, width: w, height: h)
    }

    static func centreCropRect(image: UIImage, target: CGSize) -> CGRect {
        guard let cg = image.cgImage else { return .zero }
        let imgW = CGFloat(cg.width), imgH = CGFloat(cg.height)
        let aspect = target.width / target.height
        var w = imgW, h = imgW / aspect
        if h > imgH { h = imgH; w = imgH * aspect }
        return CGRect(x: (imgW - w)/2, y: (imgH - h)/2, width: w, height: h)
    }

    private func cropped(_ image: UIImage, to rect: CGRect) -> UIImage {
        guard let cg = image.cgImage?.cropping(to: rect) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Convenience inits

extension SmartImageView where FailureView == DefaultSmartImageFailureView {
    /// Default failure view: grey rectangle with a tertiary photo glyph.
    /// Used by result rows, knowledge panels, and the daily brief hero.
    init(url: URL, size: CGSize, cornerRadius: CGFloat = 10, fillParent: Bool = false) {
        self.init(url: url, size: size, cornerRadius: cornerRadius,
                   fillParent: fillParent,
                   failureView: { DefaultSmartImageFailureView(size: size, fillParent: fillParent) })
    }
}

struct DefaultSmartImageFailureView: View {
    let size: CGSize
    let fillParent: Bool
    var body: some View {
        Group {
            if fillParent {
                Color.secondary.opacity(0.10)
                    .aspectRatio(size.width / size.height, contentMode: .fit)
            } else {
                Color.secondary.opacity(0.10)
                    .frame(width: size.width, height: size.height)
            }
        }
        .overlay(Image(systemName: "photo").foregroundStyle(.tertiary))
    }
}

// MARK: - Disk-persisted crop cache

actor SmartCropCacheActor {
    private struct Entry: Codable { let x: CGFloat; let y: CGFloat; let w: CGFloat; let h: CGFloat }

    private let fileURL: URL
    private var entries: [String: Entry] = [:]
    private var loaded = false

    init(filename: String = "smart_crop.json") {
        let dir = (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true))
                  ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = dir.appendingPathComponent(filename)
    }

    func get(_ url: URL) -> CGRect? {
        ensureLoaded()
        guard let e = entries[url.absoluteString] else { return nil }
        return CGRect(x: e.x, y: e.y, width: e.w, height: e.h)
    }

    func put(_ url: URL, rect: CGRect) {
        ensureLoaded()
        entries[url.absoluteString] = Entry(x: rect.origin.x,
                                             y: rect.origin.y,
                                             w: rect.size.width,
                                             h: rect.size.height)
        persist()
    }

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) else { return }
        entries = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

enum SmartCropCache {
    static let shared = SmartCropCacheActor()
}
