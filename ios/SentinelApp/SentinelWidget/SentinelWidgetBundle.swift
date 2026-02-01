//
//  SentinelWidgetBundle.swift
//  SentinelWidget
//
//  Created by Jayam Verma on 23/01/26.
//

import WidgetKit
import SwiftUI

@main
struct SentinelWidgetBundle: WidgetBundle {
    var body: some Widget {
        SentinelWidget()
        SentinelWidgetControl()
        SentinelWidgetLiveActivity()
    }
}
