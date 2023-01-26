//  OnBoardingView.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.

import SwiftUI

struct OnBoardingView: View {
    
    let buttonWidth: CGFloat = 0.87
    @State var isActive = false
    
    var body: some View {
    
        GeometryReader { geometry in
            
            ZStack {
                if self.isActive {
                   PicturesMainView()
                }else{
                    VStack(spacing:20) {
                        
                        Spacer()
                        Image("scenery")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .shadow(radius: 10)
                            .overlay(Circle()
                                .stroke(Color.backGroundColor, lineWidth: 5)
                            )
                            .shadow(color: .backGroundColor, radius: 10)
     
                        Text("Welcome Pictures Everywere")
                            .font(.title).bold()
                            .foregroundColor(Color.white)
                       
                        Spacer()
                    }
                    .frame(maxWidth:.infinity,maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.backGroundColor, .black])
                            ,startPoint: .topLeading,
                            endPoint: .bottom)
                    )
                }
            }.onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        self.isActive = true 
                    }
                
                }
            }

            }
    }
    
}

struct OnBoardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnBoardingView()
            .previewInterfaceOrientation(.portrait)
        
    }
}
