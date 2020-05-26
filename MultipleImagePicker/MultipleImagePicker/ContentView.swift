//
//  ContentView.swift
//  MultipleImagePicker
//
//  Created by ibrahimyilmaz on 26.05.2020.
//  Copyright © 2020 ibrahimyilmaz. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State var sheetPickerShown = false
    
    var body: some View {
        VStack {
            MultipleImagePicker()
                .onPreferenceChange(AssetImageSelectablePreferenceKey.self) { imageIds in
                    print("imageIds: \(String(describing: imageIds))")
            }
            Button(action: {
                self.sheetPickerShown = true
            }) {
                Text("Show Sheet Image Picker")
            }
            .padding()
            .sheet(isPresented: self.$sheetPickerShown, content: {
                MultipleImagePickerSheet(isPresented: self.$sheetPickerShown, doneAction: { _ in
                    
                })
            })
        }
    }
}
