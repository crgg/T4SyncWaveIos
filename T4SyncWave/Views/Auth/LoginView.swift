//
//  LoginView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
import SwiftUI
 

struct LoginView: View {

    @State private var name = ""
    @EnvironmentObject var session: SessionManager

    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            Text("SyncWave")
                .font(.largeTitle)
                .bold()

            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button("Continue") {
                Task {
                    await session.login(name: name)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty)

            Spacer()
        }
        .padding()
    }
}
