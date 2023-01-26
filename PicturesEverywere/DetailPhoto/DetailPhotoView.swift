//  DetailPhotoView.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 27/01/23.


import SwiftUI

struct DetailPhotoView: View {
    
    var instantPhoto:DetailPhotoModel
    @State var isLoading = true
        
    private func isLoadingToggle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.isLoading = false
        }
    }
    
    
    init(instantPhotoModel:DetailPhotoModel) {
        self.instantPhoto = instantPhotoModel
    }
    
    var body: some View {
        
        GeometryReader{ geometry in
    
            ZStack {
                Color.black.opacity(0.3)
                              .blur(radius: isLoading ? 30 : 0)
                              .edgesIgnoringSafeArea(.all)
                LoadingView(isShowing: $isLoading) {
                    Group {
                        if !isLoading {
                            VStack{
                                Image(uiImage:self.instantPhoto.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width,height: geometry.size.height * 0.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .animation(.spring())
                                    .accessibility(label: Text("Picture"))
                                Text("Picture Location: [\(self.instantPhoto.location)]")
                                    .foregroundColor(.white)
                                    .accessibility(label: Text("Location: \(self.instantPhoto.location)"))
                            }
                            
                        } else {
                            VStack{
                                Image("placeholder")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width,height: geometry.size.height * 0.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .animation(.spring())
                                    .accessibility(label: Text("Picture"))
                                Text("Picture Location: [uknown)]")
                                    .foregroundColor(.white)
                                    .accessibility(label: Text("Location: unknown"))
                                
                            }
                            
                        }
                    }

                }
            }.onAppear {
                isLoadingToggle()
            }

        }
            
    }
}

struct DetailPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        DetailPhotoView(instantPhotoModel: DetailPhotoModel(image:  UIImage(named: "placeholder")!, location: ""))
  
    }
}

