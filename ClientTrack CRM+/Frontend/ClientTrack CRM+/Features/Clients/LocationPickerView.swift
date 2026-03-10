//
//  LocationPickerView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import MapKit
import SwiftUI

struct LocationPickerView: View {
    @Binding var latitudeString: String
    @Binding var longitudeString: String
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchQuery = ""
    @State private var isSearching = false
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                ZStack(alignment: .leading) {
                    if searchQuery.isEmpty {
                        Text("Search address...")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    TextField("", text: $searchQuery)
                        .submitLabel(.search)
                        .onSubmit { performSearch() }
                        .foregroundColor(.white)
                }
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            MapReader { proxy in
                Map(position: $position) {
                    if let coordinate = selectedCoordinate {
                        Annotation("Selected Location", coordinate: coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                                .background(Color.white.clipShape(Circle()))
                        }
                    }
                }
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        selectedCoordinate = coordinate
                        latitudeString = String(coordinate.latitude)
                        longitudeString = String(coordinate.longitude)
                    }
                }
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .onAppear {
            if let lat = Double(latitudeString), let lon = Double(longitudeString) {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                selectedCoordinate = coord
                position = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
        }
    }

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                if error != nil {
                    return
                }
                guard let item = response?.mapItems.first else {
                    return
                }
                let coordinate = item.placemark.coordinate
                self.selectedCoordinate = coordinate
                self.latitudeString = String(coordinate.latitude)
                self.longitudeString = String(coordinate.longitude)
                withAnimation {
                    self.position = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
    }
}
