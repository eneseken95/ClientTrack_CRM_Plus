//
//  EditProfileView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ProfileViewModel
    @State private var name = ""
    @State private var surname = ""
    @State private var phone = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)
                    TextField("Surname", text: $surname)
                    TextField("Phone", text: $phone)
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await vm.updateMe(authState: authState, name: name, surname: surname, phone: phone)
                            if vm.errorMessage == nil { dismiss() }
                        }
                    } label: {
                        if vm.isBusy { ProgressView() } else { Text("Save") }
                    }
                    .disabled(isSaveDisabled)
                    .opacity(isSaveDisabled ? 0.4 : 1.0)
                }
            }
            .onAppear {
                let u = authState.currentUser
                name = u?.name ?? ""
                surname = u?.surname ?? ""
                phone = u?.phone ?? ""
            }
        }
    }

    private var isSaveDisabled: Bool {
        let u = authState.currentUser
        let origName = u?.name ?? ""
        let origSurname = u?.surname ?? ""
        let origPhone = u?.phone ?? ""
        let hasChanges = name != origName || surname != origSurname || phone != origPhone
        let hasEmptyFields = name.isEmpty || surname.isEmpty || phone.isEmpty
        return vm.isBusy || hasEmptyFields || !hasChanges
    }
}
