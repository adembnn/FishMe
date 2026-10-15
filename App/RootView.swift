//
//  RootView.swift
//  BuildChallenge
//

import Spark
import SwiftUI

struct RootView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Send event", action: {
                Spark.shared.analytics.logEvent(
                    type: "example_btn_clicked",
                    properties: [
                        "sdk_version": SparkFlavor.version,
                        "sdk_flavor": SparkFlavor.name
                    ]
                )
            })
        }
        .padding()
    }
}

#Preview {
    RootView()
}
