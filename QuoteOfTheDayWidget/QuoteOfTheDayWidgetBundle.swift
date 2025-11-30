//
//  QuoteOfTheDayWidgetBundle.swift
//  QuoteOfTheDayWidget
//
//  Created by Andre Bradford on 12/7/25.
//

import WidgetKit
import SwiftUI

@main
struct QuoteOfTheDayWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuoteOfTheDayWidget()
        QuoteOfTheDayWidgetControl()
    }
}
