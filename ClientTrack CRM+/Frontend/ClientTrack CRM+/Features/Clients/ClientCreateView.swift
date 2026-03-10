//
//  ClientCreateView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct ClientCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ClientCreateViewModel()
    let onCreated: (ClientDTO) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    TextField("Name", text: $vm.name)
                    TextField("Surname", text: $vm.surname)
                    TextField("Email", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $vm.phone)
                        .keyboardType(.phonePad)
                }
                Section("Company") {
                    TextField("Company", text: $vm.company)
                    Picker("Industry", selection: $vm.industry) {
                        Text("").tag("")
                        Text("Technology").tag("Technology")
                        Text("Finance").tag("Finance")
                        Text("Healthcare").tag("Healthcare")
                        Text("Education").tag("Education")
                        Text("Real Estate").tag("Real Estate")
                        Text("Retail").tag("Retail")
                        Text("Manufacturing").tag("Manufacturing")
                        Text("Other").tag("Other")
                    }
                    Picker("Category", selection: $vm.category) {
                        Text("").tag("")
                        Text("Small Business").tag("Small Business")
                        Text("Enterprise").tag("Enterprise")
                        Text("Individual").tag("Individual")
                        Text("Non-Profit").tag("Non-Profit")
                        Text("Startup").tag("Startup")
                    }
                }
                Section("Status") {
                    Picker("Status", selection: $vm.status) {
                        Text("").tag("")
                        Text("Active").tag("Active")
                        Text("Lead").tag("Lead")
                        Text("Inactive").tag("Inactive")
                        Text("Lost").tag("Lost")
                        Text("Onboarding").tag("Onboarding")
                    }
                    Picker("Source", selection: $vm.source) {
                        Text("").tag("")
                        Text("Referral").tag("Referral")
                        Text("Website").tag("Website")
                        Text("Social Media").tag("Social Media")
                        Text("Cold Call").tag("Cold Call")
                        Text("Advertisement").tag("Advertisement")
                        Text("Other").tag("Other")
                    }
                }
                Section("Location") {
                    LocationPickerView(
                        latitudeString: $vm.latitude,
                        longitudeString: $vm.longitude
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                }
                Section("Notes") {
                    TextEditor(text: $vm.notes)
                        .frame(minHeight: 100)
                }
                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if let client = await vm.create() {
                                onCreated(client)
                                dismiss()
                            }
                        }
                    } label: {
                        if vm.isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(vm.name.isEmpty || vm.isLoading)
                }
            }
        }
    }
}
