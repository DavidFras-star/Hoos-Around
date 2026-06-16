import SwiftUI
import UIKit

// MARK: - Media Result Type
enum PickedMedia {
    case photo(UIImage)
}

struct ImagePicker: UIViewControllerRepresentable {
    var completion: (PickedMedia?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("🎬 [ImagePicker] makeUIViewController at", Date())

        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        picker.isModalInPresentation = false
        picker.mediaTypes = ["public.image"]   // ✅ photo only

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            print("📥 [ImagePicker] didFinishPickingMediaWithInfo at", Date())

            // ✔️ Ensure it's an image
            if let image = info[.originalImage] as? UIImage {
                parent.completion(.photo(image))
            } else {
                parent.completion(nil)
            }

            print("🔻 [ImagePicker] will dismiss at", Date())
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("❌ [ImagePicker] didCancel at", Date())
            parent.completion(nil)
            print("🔻 [ImagePicker] will dismiss at", Date())
        }
    }
}

