//
//  JoinGroupView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/19/25.
//

import SwiftUI

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var code = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    
    let onJoin: (String) async -> Bool // Returns true if successful
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // Icon
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)
                
                // Title
                Text("Join a Group")
                    .font(.title2.bold())
                
                Text("Enter the 6-character group code shared by the DJ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Code Input
                TextField("Group Code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3.monospaced())
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: code) { newValue in
                        // Limit to 6 characters and uppercase
                        let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                        if filtered.count > 6 {
                            code = String(filtered.prefix(6))
                        } else {
                            code = filtered
                        }
                    }
                    .padding(.horizontal, 40)
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Join Button
                Button {
                    Task {
                        await joinGroup()
                    }
                } label: {
                    if isJoining {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Join Group")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.count != 6 || isJoining)
                .padding(.horizontal, 40)
                .padding(.top, 8)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isJoining)
                }
            }
            .interactiveDismissDisabled(isJoining)
        }
    }
    
    private func joinGroup() async {
        errorMessage = nil
        isJoining = true
        defer { isJoining = false }
        
        let success = await onJoin(code)
        if success {
            dismiss()
        }
    }
}

#Preview {
    JoinGroupView { code in
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return true
    }
}

