//  PicturesMainView.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.

import SwiftUI

struct PicturesMainView: View {
    @State var dataStorage = ImageStorage()
    @ObservedObject var viewModel = PictureViewModel()
    private var gridItemLayout = [GridItem(.adaptive(minimum: 150))]
    let buttonWidth: CGFloat = 0.87
    
    //    MARK: - Place holder image
    var placeHolderImage:some View{
        
        ScrollView(.horizontal) {
            LazyHGrid(rows:gridItemLayout,spacing:5) {
                ForEach(0..<5, id: \.self) { item in
                    
                    Button(action: {
                        viewModel.toggleAlert()
                    }) {
                        Image("placeholder")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .accessibility(label: Text("Placeholder Image"))
                    }.alert("You haven't taken any photos yet", isPresented: $viewModel.showingAlert) {
                        Button("OK", role: .cancel) {
                            print(dataStorage.imagesArray.count)
                        }
                    }.padding([.leading,.trailing],20)
                    
                }
            }
        }
        .background(.white)
    }
    
    
    var body: some View {
        
        GeometryReader { geometry in
            
            NavigationView {
                
                VStack {
                    placeHolderImage
                    Spacer()
                    Button(action: {   }) {
                        NavigationLink(destination: TakePictureView(currenLocation: self.$viewModel.address)) {
                            Text("Take Picture")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 18))
                                .padding()
                                .foregroundColor(.black)
                        }
                        
                    }
                    .buttonStyle(
                        NeuButtonStyle(width: geometry.size.width * buttonWidth, height: 48))
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.lightPurple,.lightedPurple])
                            ,startPoint: .topLeading,
                            endPoint: .bottom)
                    )
                    .cornerRadius(25)
                }
                .navigationTitle("Pictures everywhere!")
                .background(.white)
                .alert(isPresented: $viewModel.shouldShowAlertView, content: {
                    Alert(title: Text("Camera Access"), message: Text(viewModel.errorDescription), dismissButton: .default(Text("Go to settings"), action: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                  options: [:], completionHandler: nil)
           
                    }))
                    
                })
            }
            .navigationViewStyle(.stack)
            .padding(20)
            .background(.white)
            .onAppear {
                self.viewModel.requestLocation()
                self.viewModel.checkCameraPermission()
                self.viewModel.stopLocationManager()
                
                
            }
            
        }
    }
    
    struct PicturesMainView_Previews: PreviewProvider {
        static var previews: some View {
            PicturesMainView()
        }
    }
}
