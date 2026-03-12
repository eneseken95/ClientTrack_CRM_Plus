//
//  EditClientView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct EditClientView: View {
    @ObservedObject var vm: ClientDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var company = ""
    @State private var notes = ""
    @State private var source = ""
    @State private var status = ""
    @State private var category = ""
    @State private var industry = ""
    @State private var latitude = ""
    @State private var longitude = ""
    private var isDirty: Bool {
        let c = vm.client
        return name != c.name ||
            surname != (c.surname ?? "") ||
            email != (c.email ?? "") ||
            phone != (c.phone ?? "") ||
            company != (c.company ?? "") ||
            notes != (c.notes ?? "") ||
            source != (c.source ?? "") ||
            status != (c.status ?? "") ||
            category != (c.category ?? "") ||
            industry != (c.industry ?? "") ||
            latitude != (c.latitude ?? "") ||
            longitude != (c.longitude ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    TextField("Name", text: $name)
                    TextField("Surname", text: $surname)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .onChange(of: email) { _, newValue in
                            let lowered = newValue.lowercased()
                            if lowered != newValue { email = lowered }
                        }
                    TextField("Phone", text: $phone)
                }
                Section("Company") {
                    TextField("Company", text: $company)
                    Picker("Industry", selection: $industry) {
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
                    Picker("Category", selection: $category) {
                        Text("").tag("")
                        Text("Small Business").tag("Small Business")
                        Text("Enterprise").tag("Enterprise")
                        Text("Individual").tag("Individual")
                        Text("Non-Profit").tag("Non-Profit")
                        Text("Startup").tag("Startup")
                    }
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text("").tag("")
                        Text("Active").tag("Active")
                        Text("Lead").tag("Lead")
                        Text("Inactive").tag("Inactive")
                        Text("Lost").tag("Lost")
                        Text("Onboarding").tag("Onboarding")
                    }
                    Picker("Source", selection: $source) {
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
                        latitudeString: $latitude,
                        longitudeString: $longitude
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(
                AppTheme.authBackgroundGradient
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await vm.updateClient(
                                name: name,
                                surname: surname,
                                email: email,
                                phone: phone,
                                company: company,
                                notes: notes,
                                source: source,
                                status: status,
                                category: category,
                                industry: industry,
                                latitude: latitude.isEmpty ? nil : latitude,
                                longitude: longitude.isEmpty ? nil : longitude
                            )
                            if vm.errorMessage == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        if vm.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(vm.isSaving || name.isEmpty || !isDirty)
                }
            }
            .onAppear {
                let c = vm.client
                name = c.name
                surname = c.surname ?? ""
                email = c.email ?? ""
                phone = c.phone ?? ""
                company = c.company ?? ""
                notes = c.notes ?? ""
                source = c.source ?? ""
                status = c.status ?? ""
                category = c.category ?? ""
                industry = c.industry ?? ""
                latitude = c.latitude ?? ""
                longitude = c.longitude ?? ""
            }
        }
    }
}
