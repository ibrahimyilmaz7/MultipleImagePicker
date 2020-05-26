//
//  MultipleImagePickerSheet.swift
//  MultipleImagePicker
//
//  Created by ibrahimyilmaz on 26.05.2020.
//  Copyright © 2020 ibrahimyilmaz. All rights reserved.
//

import SwiftUI

struct MultipleImagePickerSheet: View {
    
    @Binding var isPresented: Bool
    @State var doneAction: ([String]) -> ()
    
    @State var selectedIds = [String]()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                MultipleImagePicker()
                    .onPreferenceChange(AssetImageSelectablePreferenceKey.self) { imageIds in
                        self.selectedIds = imageIds ?? []
                }
            }
            .navigationBarTitle("Photos", displayMode: .inline)
            .navigationBarItems(
                leading:
                Button(action: {
                    print("Close clicked!")
                    self.isPresented = false
                }, label: {
                    Text("Close")
                }),
                trailing:
                Button(action: {
                    print("Done clicked!")
                    
                    self.isPresented = false
                    
                    self.doneAction(self.selectedIds)
                }, label: {
                    Text("Done (\(selectedIds.count))").bold()
                }).disabled(selectedIds.count == 0)
            )
        }
    }
}
