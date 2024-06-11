//
//  LoadingView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 1/9/24.
//

import SwiftUI

struct StartUpLoadingView: View {
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

struct DetailsLoadingView: View {
    var body: some View {
        VStack {
            Text("Loading lights...")
                .padding()
            ActivityBlurView(isAnimating: .constant(true), style: .large)
                .padding()
        }
    }
}

struct ActivityBlurView: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityBlurView>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityBlurView>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct ActivityIndicatorModifier: AnimatableModifier {
    var isLoading: Bool
    
    init(isLoading: Bool, color: Color = .primary, lineWidth: CGFloat = 3) {
        self.isLoading = isLoading
    }
    
    var animatableData: Bool {
        get { isLoading }
        set { isLoading = newValue }
    }
    
    func body(content: Content) -> some View {
        ZStack{
            if isLoading {
                ZStack(alignment: .center) {
                    content
                        .disabled(self.isLoading)
                        .blur(radius: self.isLoading ? 3 : 0)
                    
                    DetailsLoadingView()
                        .background(Color.secondary.colorInvert())
                        .foregroundColor(Color.primary)
                        .cornerRadius(20)
                        .opacity(self.isLoading ? 1 : 0)
                }
            } else {
                content
            }
        }
    }
}

#Preview {
    DetailsLoadingView().preferredColorScheme(.dark)
}
