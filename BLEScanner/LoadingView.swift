//
//  LoadingView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 1/9/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Image("LaunchImage")
            
            Text("Loading...")
                .padding()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView().preferredColorScheme(.dark)
}
