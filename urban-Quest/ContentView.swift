import SwiftUI
import GoogleGenerativeAI
import UIKit
import AVFoundation
import Photos
import GoogleCloudVision 

// A struct for managing the image picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPickerPresented: Bool

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPickerPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPickerPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
}

struct ContentView: View {
    let model = GenerativeModel(name: "gemini-1.5-flash-002", apiKey: APIKey.default)
    @State private var isMenuOpen = false
    @State var userPrompt = ""
    @State var isLoading = false
    @State var isFirstLoad = true
    @State var uQresponse = false
    @State var isPickerPresented = false
    @State var selectedImage: UIImage?

    // Single array to store pairs of user inputs and responses
    @State var chatHistory: [(input: String, response: String, image: UIImage?)] = []

    var body: some View {
        ZStack {
            // Main Content with Background Color
            Color.white.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    if isMenuOpen {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }
                }

            VStack {
                // Menu and Header
                HStack {
                    Button(action: {
                        withAnimation {
                            self.isMenuOpen.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .resizable()
                            .frame(width: 30, height: 20)
                            .padding()
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Text("UQ")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: {
                        // Action for new quest
                    }) {
                        Image(systemName: "pencil")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                
                Spacer()

                // Scrollable list for displaying chat history
                if isFirstLoad {
                    VStack {
                        Spacer()
                        Text("Urban Quest")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text("Explore the world")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(0..<chatHistory.count, id: \.self) { index in
                                    HStack {
                                        if !chatHistory[index].input.isEmpty {
                                            VStack(alignment: .leading) {
                                                Text("User")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                // Display user input text
                                                Text(chatHistory[index].input)
                                                    .padding()
                                                    .foregroundColor(.black)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(10)
                                                
                                                // Display the image if available
                                                if let image = chatHistory[index].image {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .frame(width: 100, height: 100)
                                                        .cornerRadius(10)
                                                        .padding(.top, 5)
                                                }
                                            }
                                            .padding(.horizontal)
                                            Spacer()
                                        }
                                    }

                                    HStack {
                                        Spacer()
                                        if !chatHistory[index].response.isEmpty {
                                            VStack(alignment: .trailing) {
                                                Text("UrbanQuest")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                Text(chatHistory[index].response)
                                                    .padding()
                                                    .foregroundColor(.black)
                                                    .background(Color.white.opacity(0.2))
                                                    .cornerRadius(10)
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            .onChange(of: chatHistory.count) { _ in
                                if let last = chatHistory.indices.last {
                                    scrollViewProxy.scrollTo(last, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Search Bar and Camera Button at the bottom
                HStack {
                    // Camera button for taking images
                    Button(action: {
                        openCamera()
                    }) {
                        Image(systemName: "camera")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.black)
                    }
                    .padding(.leading)

                    // Display the captured image as a thumbnail next to the text field if available
                    if let thumbnail = selectedImage {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                            .padding(.leading, 10)
                    }

                    // TextField for text input
                    TextField("Ask about the photo", text: $userPrompt, axis: .vertical)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(25)
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 10)

                    Spacer()

                    // Submit button for sending text input
                    Button(action: {
                        generateResponse()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.black)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }

            // Camera image picker
            if isPickerPresented {
                ImagePicker(selectedImage: $selectedImage, isPickerPresented: $isPickerPresented)
            }

            // Side Menu Overlay
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }

                HStack {
                    SideMenu()
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
    }

    // Function to check and open camera
    func openCamera() {
        if checkCameraAccess() {
            isPickerPresented.toggle()
        } else {
            print("Camera access denied or unavailable.")
        }
    }

    // Function to generate response
    func generateResponse() {
        isLoading = true
        uQresponse = false
        isFirstLoad = false

        let userInput = userPrompt
        let capturedImage = selectedImage

        Task {
            do {
                // Step 1: Analyze the image using Vertex AI Vision
                var imageAnalysis: String? = nil
                if let image = capturedImage {
                    imageAnalysis = try await analyzeImageUsingVertexAI(image: image)
                }

                // Step 2: Combine image analysis (if available) with user input
                let finalInput = imageAnalysis != nil ? "\(imageAnalysis!). \(userInput)" : userInput

                userPrompt = ""
                let result = try await model.generateContent(finalInput)
                isLoading = false

                // Append both the user input and captured image (if any) to the chat history
                chatHistory.append((input: finalInput, response: result.text ?? "No response found", image: capturedImage))
                uQresponse = true

                // Clear the selected image after sending
                selectedImage = nil

            } catch {
                isLoading = false
                chatHistory.append((input: userInput, response: "Something went wrong! \n\(error.localizedDescription)", image: capturedImage))
                uQresponse = true
            }
        }
    }

    // Function to analyze image using Vertex AI Vision API
    func analyzeImageUsingVertexAI(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data."])
        }

        // Call the Vertex AI Vision API here to analyze the image and return a description or labels
        // Simulating a response here (replace this with actual API call)
        let simulatedAnalysis = "This image contains a sunset over the ocean."
        return simulatedAnalysis
    }

    // Function to check for camera access
    func checkCameraAccess() -> Bool {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraAuthorizationStatus {
        case .notDetermined:
            // First time access request
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    print("Camera access granted.")
                } else {
                    print("Camera access denied.")
                }
            }
            return false
        case .authorized:
            return true
        case .restricted, .denied:
            print("Camera access denied.")
            return false
        @unknown default:
            return false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

