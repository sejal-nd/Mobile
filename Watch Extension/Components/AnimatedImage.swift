//
//  AnimatedImage.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/15/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI
import WatchKit

//struct Test: WKInterfaceObjectRepresentable {
//
//}
//
//struct AnimatedImage: WKInterfaceObjectRepresentable {
//    let imageName: String
//
//    func makeUIView(context: WKInterfaceObjectRepresentableContext<WKInterfaceImage>) -> WKInterfaceImage {
//        WKInterfaceImage()
//    }
//
//    func updateUIView(_ uiView: WKInterfaceImage, context: WKInterfaceObjectRepresentableContext<WKInterfaceImage>) {
//        uiView.setImage(UIImage(named: imageName)!)
//    }
//}
//
//extension WKInterfaceImage {
//    override convenience init() {
//
//    }
//}
//
//struct AnimatedImage: WKInterfaceObjectRepresentable {
//    var imageName: String
//
//    func makeWKInterfaceObject(context: WKInterfaceObjectRepresentableContext<AnimatedImage>) -> WKInterfaceImage {
//        // Return the interface object that the view displays.
//        return WKInterfaceImage()
//    }
//
//    func updateWKInterfaceObject(_ interfaceImage: WKInterfaceImage, context: WKInterfaceObjectRepresentableContext<AnimatedImage>) {
//        // Update the interface object.
////        let span = MKCoordinateSpan(latitudeDelta: 0.02,
////                                    longitudeDelta: 0.02)
////
////        let region = MKCoordinateRegion(
////            center: landmark.locationCoordinate,
////            span: span)
////
////        map.setRegion(region)
//    }
//}
