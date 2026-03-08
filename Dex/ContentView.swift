//
//  ContentView.swift
//  Dex
//
//  Created by Gustavo Loaiza Robles on 6/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Pokemon.id, animation: .default) private var pokedex: [Pokemon]
    
    @State private var searchText = ""
    @State private var filterByFavorites = false
    
    private var dynamicPredicate: NSPredicate {
        var predicates: [NSPredicate] = []
        
        // Search predicate
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@", searchText))
        }
        
        // Filter by favorite predicate
        if filterByFavorites {
            predicates.append(NSPredicate(format: "favorite == %d", true))
        }
        
        // Combine predicates
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    let fetcher = FetchService()
    
    var body: some View {
        Group {
            if pokedex.isEmpty {
                emptyStateView
            } else {
                mainListView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            // Use an explicit Image resource to avoid overload issues
            Label {
                Text("No Pokemon")
            } icon: {
                Image(.nopokemon)
            }
        } description: {
            Text("There aren't any pokemon yet.\nFetch some pokemon to get started")
        } actions: {
            Button("Fetch pokemon", systemImage: "antenna.radiowaves.left.and.right") {
                getPokemon(from: 1)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var mainListView: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(pokedex) { pokemon in
                        NavigationLink(value: pokemon) {
                            rowContent(for: pokemon)
                        }
                        .swipeActions(edge: .leading) {
                            Button(pokemon.favorite ? "Remove from favorites" : "Add to favorites", systemImage: "star") {
                                pokemon.favorite.toggle()
                                do {
                                    try modelContext.save()
                                } catch {
                                    print(error)
                                }
                            }
                            .tint(pokemon.favorite ? .gray : .yellow)
                        }
                    }
                } footer: {
                    if pokedex.count < 151 {
                        ContentUnavailableView {
                            Label {
                                Text("Missing pokemon")
                            } icon: {
                                Image(.nopokemon)
                            }
                        } description: {
                            Text("The fetch was interrupted.\nFetch the rest of the pokemon.")
                        } actions: {
                            Button("Fetch pokemon", systemImage: "antenna.radiowaves.left.and.right") {
                                getPokemon(from: pokedex.count + 1)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .navigationTitle("Pokedex")
            .searchable(text: $searchText, placement: .automatic, prompt: "Find a pokemon")
            .autocorrectionDisabled(true)
            .navigationDestination(for: Pokemon.self) { pokemon in
                PokemonDetailView(pokemon: pokemon)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        filterByFavorites.toggle()
                    } label: {
                        Label("Filter by Favorites", systemImage: filterByFavorites ? "star.fill" : "star")
                    }
                    .tint(.yellow)
                }
            }
        }
    }
    
    @ViewBuilder
    private func rowContent(for pokemon: Pokemon) -> some View {
        // Image: if sprite data exists use cached image; otherwise AsyncImage from URL
        HStack(alignment: .center, spacing: 12) {
            pokemonImageView(pokemon)
                .frame(width: 100, height: 100)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(pokemon.name.capitalized)
                        .fontWeight(.bold)
                    
                    if pokemon.favorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                HStack {
                    ForEach(pokemon.types, id: \.self) { type in
                        Text(type.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 5)
                            .background(Color(type.capitalized)) // check the typeColors in assets
                            .clipShape(.capsule)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func pokemonImageView(_ pokemon: Pokemon) -> some View {
        if let _ = pokemon.sprite {
            pokemon.spriteImage
                .resizable()
                .scaledToFit()
        } else {
            AsyncImage(url: pokemon.spriteURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
        }
    }
    
    // MARK: - Actions
    
    private func getPokemon(from id: Int) {
        Task {
            for i in id..<152 {
                do {
                    let fetchedPokemon = try await fetcher.fetchPokemon(i)
                    modelContext.insert(fetchedPokemon)
                } catch {
                    print(error)
                }
            }
            storeSprites()
        }
    }
    
    private func storeSprites() {
        Task {
            do {
                for pokemon in pokedex {
                    // it returns a tuple (data, response), so use position 0 corresponding to the data
                    pokemon.sprite = try await URLSession.shared.data(from: pokemon.spriteURL).0
                    pokemon.shiny = try await URLSession.shared.data(from: pokemon.shinyURL).0
                    try modelContext.save()
                    print("Sprites stored: \(pokemon.id): \(pokemon.name.capitalized)")
                }
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview)
}
