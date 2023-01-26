//  TakePictureView.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.

import SwiftUI

struct TakePictureView: View {
    
    @StateObject var viewModel = TakePictureViewModel()
    @State var currentZoomFactor: CGFloat = 1.0
    @Binding var currenLocation: String
    
    var captureButton: some View {
        Button(action: {
            viewModel.capturePhoto(currenLocation)
        }, label: {
            Circle()
                .foregroundColor(.black)
                .frame(width: 80, height: 80, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                )
        })
    }
    
    var capturedPhotoThumbnail: some View {
        Group {
            if viewModel.model != nil {
               
                NavigationLink(destination: DetailPhotoView(instantPhotoModel: self.viewModel.instantPhoto)) {
                    Image(uiImage: viewModel.model.image!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .animation(.spring())
                }
                
            } else {
                Image("placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .animation(.spring())
                
            }
        }
    }
    
    var flipCameraButton: some View {
        Button(action: {
            viewModel.flipCamera()
        }, label: {
            Circle()
                .foregroundColor(Color.gray.opacity(0.2))
                .frame(width: 45, height: 45, alignment: .center)
                .overlay(
                    Image(systemName: "camera.rotate.fill")
                        .foregroundColor(.tealColor))
        })
    }
    
    var body: some View {
        
        GeometryReader { reader in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Button(action: {
                        viewModel.switchFlash()
                    }, label: {
                        Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .medium, design: .default))
                    })
                    .accentColor(viewModel.isFlashOn ? .yellow : .teal)
                    .foregroundColor(viewModel.isFlashOn ? .yellow : .teal)
                    
                    CameraPreview(session: viewModel.session)
                        .gesture(
                            DragGesture().onChanged({ (val) in
                                //  Only accept vertical drag
                                if abs(val.translation.height) > abs(val.translation.width) {
                                    //  Get the percentage of vertical screen space covered by drag
                                    let percentage: CGFloat = -(val.translation.height / reader.size.height)
                                    //  Calculate new zoom factor
                                    let calc = currentZoomFactor + percentage
                                    //  Limit zoom factor to a maximum of 5x and a minimum of 1x
                                    let zoomFactor: CGFloat = min(max(calc, 1), 5)
                                    //  Store the newly calculated zoom factor
                                    currentZoomFactor = zoomFactor
                                    //  Sets the zoom factor to the capture device session
                                    viewModel.zoom(with: zoomFactor)
                                }
                            })
                        )
                        .onAppear {
                            viewModel.configure()
                        }
                        .alert(isPresented: $viewModel.shouldShowAlertView, content: {
                            Alert(title: Text("Camera Access"), message: Text(viewModel.errorDescription), dismissButton: .default(Text("Go to settings"), action: {
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                          options: [:], completionHandler: nil)
                            }))
                            
                        })
                        .overlay(
                            Group {
                                if viewModel.willCapturePhoto {
                                    Color.black
                                }
                            }
                        )
                        .animation(.easeInOut)
                    
                    HStack {
                        
                        capturedPhotoThumbnail
                        
                        Spacer()
                        
                        captureButton
                        
                        Spacer()
                        
                        flipCameraButton
                        
                    }
                    .padding(.horizontal, 20)
                }
               
            }
        }
    }
    
}

struct TakePictureView_Previews: PreviewProvider {
    static var previews: some View {
        TakePictureView( currenLocation: .constant(""))
    }
}


