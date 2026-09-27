import Foundation

struct Facility: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let area: String
    let mapURL: String
}

@MainActor
final class FacilityStore: ObservableObject {
    @Published private(set) var facilities: [Facility] = []
    @Published var searchText = ""
    @Published private(set) var favoriteIDs: Set<String>

    private let favoritesKey = "favoriteFacilityIDs"

    init() {
        favoriteIDs = Set(UserDefaults.standard.stringArray(forKey: favoritesKey) ?? [])
        loadFacilities()
    }

    var filteredFacilities: [Facility] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return facilities }
        return facilities.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.area.localizedCaseInsensitiveContains(query) }
    }

    var favorites: [Facility] {
        facilities.filter { favoriteIDs.contains($0.id) }
    }

    func isFavorite(_ facility: Facility) -> Bool { favoriteIDs.contains(facility.id) }

    func toggleFavorite(_ facility: Facility) {
        if favoriteIDs.contains(facility.id) { favoriteIDs.remove(facility.id) }
        else { favoriteIDs.insert(facility.id) }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }

    private func loadFacilities() {
        guard let url = Bundle.main.url(forResource: "facilities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Facility].self, from: data) else { return }
        facilities = decoded
    }
}

