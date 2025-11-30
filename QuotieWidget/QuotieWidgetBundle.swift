//
//  QuotieWidgetBundle.swift
//  QuotieWidget
//
//  Created by Andre Bradford on 11/19/25.
//

import WidgetKit
import SwiftUI

@main
struct QuotieWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuotieWidget()
        QuotieWidgetControl()
        QuotieWidgetLiveActivity()
    }
}
