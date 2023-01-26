//
//  NeubuttonStyle.swift
//  PicturesEverywere
//
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.
//

import SwiftUI

struct NeuButtonStyle: ButtonStyle {
  let width: CGFloat
  let height: CGFloat

  func makeBody(configuration: Self.Configuration)
  -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.2 : 1)
      .frame(width: width, height: height)
      .background(
        Group {
          if configuration.isPressed {
            Capsule()
               .strokeBorder(Color.white,lineWidth: 1)
               .background(Circle().foregroundColor(Color.element))
              .southEastShadow()
          } else {
            Capsule()
               .strokeBorder(Color.white,lineWidth: 1)
               .background(Circle().foregroundColor(Color.element))
              .northWestShadow()
          }
        }
      )
  }
}
