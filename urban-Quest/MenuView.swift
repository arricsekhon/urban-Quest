//
//  MenuView.swift
//  urban-Quest
//
//  Created by Arric Sekhon on 19/10/24.
//


import SwiftUI

struct SideMenu: View {
    var body: some View {
        VStack(alignment: .leading) {
            // Add items in your side menu
            Text("Menu Item 1")
                .padding(.top, 20)
                .font(.headline)
            Text("Menu Item 2")
                .padding(.top, 20)
            Text("Menu Item 3")
                .padding(.top, 20)
            Spacer()
        }
        .frame(width: 250) // Adjust the width of the side menu
        .padding(.leading, 30)
        .background(Color.white)
        .cornerRadius(20) // Optional: To round the corners of the menu
        .shadow(radius: 5) // Optional: Add shadow for a nice effect
    }
}

struct SideMenu_Previews: PreviewProvider {
    static var previews: some View {
        SideMenu()
    }
}

