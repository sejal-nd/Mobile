//
//  BillView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillView: View {
    let billState: BillState

    var body: some View {
        Text("BillView")
    }
}

struct BillView_Previews: PreviewProvider {
    static var previews: some View {
        BillView(billState: .loaded)
    }
}
