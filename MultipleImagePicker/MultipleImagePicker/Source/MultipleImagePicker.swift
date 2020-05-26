//
//  MultipleImagePicker.swift
//  MultipleImagePicker
//
//  Created by ibrahimyilmaz on 26.05.2020.
//  Copyright © 2020 ibrahimyilmaz. All rights reserved.
//

import SwiftUI
import Photos
import Combine

// MARK: Constants
// TODO: Make a parametric config object from this constant for better customizability
fileprivate enum Constants {
    static let checkmarkIcon = "checkmark.circle.fill"
    static let gridColumns = Int(3)
    static let cellSpacing = CGFloat(5.0)
    static let cellRadius = CGFloat(5)
    static let checkmarkMinFontSize = CGFloat(20)
    static let checkmarkMaxFontSize = CGFloat(35)
}

struct MultipleImagePicker : View {
    @ObservedObject var photoLibrary = PhotoLibraryContainer()
    
    @State var assets: [PHAsset] = [PHAsset]()
    
    var body: some View {
        VStack {
            AssetGrid(data: self.$assets, columns: Constants.gridColumns, selectable: true)
        }
        .padding(5)
        .onAppear(perform: {
            self.reload()
        })
            .onReceive(photoLibrary.objectWillChange, perform: { data in
                self.assets = data
            })
    }
    
    private func reload() {
        photoLibrary.requestAuthorization()
    }
}

struct AssetGrid: View {
    
    @Binding var data: [PHAsset]
    @State var columns: Int = Constants.gridColumns
    
    @State var selectable: Bool = false
    @State var selectedIds = [String]()
    
    private var rowTotalSpace: CGFloat {
        Constants.cellSpacing * CGFloat(columns + 1)
    }
    
    var body: some View {
        var imageDictionary = [[PHAsset]]()
        
        _ = data.publisher
            .collect(columns)
            .collect()
            .sink(receiveValue: { imageDictionary = $0 })
        
        return GeometryReader { geometryReader in
            List {
                ForEach(0..<imageDictionary.count, id: \.self) { array in
                    HStack(spacing: 0) {
                        ForEach(imageDictionary[array], id: \.self) { asset in
                            VStack {
                                if self.selectable {
                                    AssetImageSelectableView(
                                        asset: asset,
                                        size: self.getImageSize(width: geometryReader.size.width),
                                        selectedIds: self.$selectedIds
                                    )
                                        .padding(.top, Constants.cellSpacing)
                                        .padding(.leading, Constants.cellSpacing)
                                }
                                else {
                                    AssetImageView(
                                        asset: asset,
                                        size: self.getImageSize(width: geometryReader.size.width)
                                    )
                                        .padding(.top, Constants.cellSpacing)
                                        .padding(.leading, Constants.cellSpacing)
                                }
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
            }.onAppear {
                UITableView.appearance().separatorStyle = .none
            }.onDisappear {
                UITableView.appearance().separatorStyle = .singleLine
            }
        }
    }
    
    func getImageSize(width: CGFloat) -> CGSize {
        let size = (width - rowTotalSpace) / CGFloat(columns)
        return CGSize(width: size, height: size)
    }
}

struct AssetImageSelectablePreferenceKey: PreferenceKey {
    static var defaultValue: [String]?
    
    static func reduce(value: inout [String]?, nextValue: () -> [String]?) {
        value = nextValue()
    }
}

struct AssetImageSelectableView: View {
    @Binding var selectedIds: [String]
    
    var asset: PHAsset
    var size: CGSize
    
    // Width related font size between 20 and 35
    private var fontSize: CGFloat {
        min(max(CGFloat(size.width / 8), Constants.checkmarkMinFontSize), Constants.checkmarkMaxFontSize)
    }
    
    private var offset: CGFloat {
        fontSize / 3
    }
    
    init (asset: PHAsset, size: CGSize, selectedIds: Binding<[String]>) {
        self.size = size
        self.asset = asset
        self._selectedIds = selectedIds
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            AssetImageView(asset: asset, size: size)
            if self.selectedIds.contains(self.asset.localIdentifier) {
                Image(systemName: Constants.checkmarkIcon)
                    .font(.system(size: fontSize))
                    .frame(height: fontSize)
                    .foregroundColor(.blue)
                    .background(Color.white.mask(Circle()))
                    .offset(x: offset, y: offset)
            }
        }.onTapGesture {
            if let firstIndex = self.selectedIds.firstIndex(of: self.asset.localIdentifier) {
                self.selectedIds.remove(at: firstIndex)
            }
            else {
                self.selectedIds.append(self.asset.localIdentifier)
            }
        }
        .preference(key: AssetImageSelectablePreferenceKey.self, value: selectedIds)
        .frame(width: size.width, height: size.height)
    }
}

struct AssetImageView: View {
    @ObservedObject var assetLoader: AssetLoader
    
    var size: CGSize
    
    init (asset: PHAsset, size: CGSize) {
        self.assetLoader = AssetLoader(asset: asset, size: size)
        self.size = size
    }
    
    var body: some View {
        VStack {
            Image(uiImage: assetLoader.image)
                .resizable()
                .cornerRadius(Constants.cellRadius)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: AssetLoader
class AssetLoader: ObservableObject {
    var objectWillChange = PassthroughSubject<UIImage, Never>()
    
    // FIXME: Find better solution for placeholder
    var image: UIImage = UIImage(named: "placeholder")! {
        didSet {
            objectWillChange.send(image)
        }
    }
    
    init(asset: PHAsset, size: CGSize) {
        PHImageManager.default()
            .requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: nil) { [weak self] (image, _) in
                    // FIXME: Handle error case for better experience
                    guard let image = image else { return }
                    
                    // Assign observable value from main thread
                    DispatchQueue.main.async { [weak self] in
                        self?.image = image
                    }
        }
    }
}

// MARK: PhotoLibraryContainer
class PhotoLibraryContainer: ObservableObject {
    let objectWillChange = PassthroughSubject<[PHAsset], Never>()
    
    var assets = [PHAsset]() {
        didSet {
            objectWillChange.send(assets)
        }
    }
    
    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            guard let self = self else { return }
            
            switch status {
            case .authorized:
                self.getAllPhotos()
            case .denied:
                print("PHPhotoLibrary.requestAuthorization: denied.")
                break
            case .notDetermined:
                print("PHPhotoLibrary.requestAuthorization: notDetermined.")
                break
            case .restricted:
                print("PHPhotoLibrary.requestAuthorization: restricted.")
                break
            @unknown default:
                print("PHPhotoLibrary.requestAuthorization: unknown default.")
                break
            }
        }
    }
    
    /// Fetchs all photos from gallery as `PHAsset` object
    private func getAllPhotos() {
        let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        var assetList = [PHAsset]()
        assets.enumerateObjects { (asset, index, stop) in
            assetList.append(asset)
        }
        DispatchQueue.main.async { [weak self] in
            self?.assets = assetList
        }
    }
}
