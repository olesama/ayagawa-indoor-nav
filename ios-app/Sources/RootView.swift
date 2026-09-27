import SwiftUI

struct RootView: View {
    @StateObject private var store = FacilityStore()

    var body: some View {
        TabView {
            NavigationStack { FacilityListView(store: store) }
                .tabItem { Label("施設", systemImage: "building.2") }
            NavigationStack { FavoritesView(store: store) }
                .tabItem { Label("お気に入り", systemImage: "star.fill") }
            NavigationStack { SensorStatusView() }
                .tabItem { Label("センサー", systemImage: "location.north.circle") }
            NavigationStack { AppInformationView() }
                .tabItem { Label("情報", systemImage: "info.circle") }
        }
        .tint(Color(red: 0.05, green: 0.43, blue: 1.0))
    }
}

struct FacilityListView: View {
    @ObservedObject var store: FacilityStore

    var body: some View {
        List(store.filteredFacilities) { facility in
            NavigationLink {
                FacilityDetailView(facility: facility, store: store)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(facility.name).font(.headline)
                    Text(facility.area).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $store.searchText, prompt: "施設名・都道府県で検索")
        .navigationTitle("館内ナビ")
        .overlay {
            if store.filteredFacilities.isEmpty { ContentUnavailableView.search(text: store.searchText) }
        }
    }
}

struct FavoritesView: View {
    @ObservedObject var store: FacilityStore
    var body: some View {
        Group {
            if store.favorites.isEmpty {
                ContentUnavailableView("お気に入りはありません", systemImage: "star", description: Text("施設画面の星を押すと追加できます。"))
            } else {
                List(store.favorites) { facility in
                    NavigationLink(facility.name) { FacilityDetailView(facility: facility, store: store) }
                }
            }
        }.navigationTitle("お気に入り")
    }
}

struct FacilityDetailView: View {
    let facility: Facility
    @ObservedObject var store: FacilityStore

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill").font(.system(size: 56)).foregroundStyle(.blue)
            Text(facility.name).font(.title2.bold()).multilineTextAlignment(.center)
            Text(facility.area).foregroundStyle(.secondary)
            NavigationLink {
                WebNavigationView(facility: facility)
            } label: {
                Label("この施設を案内する", systemImage: "location.fill")
                    .frame(maxWidth: .infinity).padding().background(.blue).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button {
                store.toggleFavorite(facility)
            } label: {
                Label(store.isFavorite(facility) ? "お気に入りから外す" : "お気に入りに追加", systemImage: store.isFavorite(facility) ? "star.fill" : "star")
                    .frame(maxWidth: .infinity).padding().background(Color(.secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Text("表示される距離・方向は概算です。現地表示と公式マップを優先してください。")
                .font(.footnote).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("施設")
        .navigationBarTitleDisplayMode(.inline)
    }
}

