# MultipleImagePicker
MultipleImagePicker for **SwiftUI**


## Example Output

<code>Can be used both inline or sheet style</code>

<img src="./MultipleImagePicker.gif" width="350"></img>


**************


Since **SwiftUI 2.0**, for **iOS 14+** we have native picker support 🚀
You just need the code below 😊

```swift
import SwiftUI
import PhotosUI

struct ContentView: View {
    
    @State var isPresented = false
    @State var selectedPhotos: [PHPickerResult] = []
    
    var body: some View {
        VStack {
            PhotoPicker(isPresented: $isPresented, selectedPhotos: $selectedPhotos)
            Button(action: {
                self.isPresented = true
            }) {
                Text("Show Sheet Image Picker")
            }
            .padding()
            .sheet(isPresented: self.$isPresented, content: {
                PhotoPicker(isPresented: $isPresented, selectedPhotos: $selectedPhotos)
            })
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    @Binding var selectedPhotos: [PHPickerResult]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.filter = .images
        configuration.selectionLimit = 0
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: PHPickerViewControllerDelegate {
        private let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.selectedPhotos = results
            parent.isPresented = false
        }
    }
}
```
