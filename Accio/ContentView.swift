//
//  ContentView.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Accio")
                .font(.largeTitle)
            Text("Hotkey App")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
