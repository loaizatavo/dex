//
//  ContentView.swift
//  Dex
//
//  Created by Gustavo Loaiza Robles on 6/12/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest<Pokemon>(sortDescriptors: []) private var all
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Pokemon.id, ascending: true)],
        animation: .default)
    
    private var pokedex: FetchedResults<Pokemon>
    
//    @FetchRequest<Pokemon>(
//        sortDescriptors: [SortDescriptor(\.id)],
//        animation: .default
//    ) private var pokedex
    
    @State private var searchText = ""
    @State private var filterByFavorites = false
    
    private var dynamicPredicate : NSPredicate {
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
        if all.isEmpty {
            ContentUnavailableView {
                Label("No Pokemon", image: .nopokemon)
            } description: {
                Text("There aren't any pokemon yet.\nFetch some pokemon to get started")
            } actions: {
                Button("Fetch pokemon", systemImage: "antena.radiowaves.leftandright") {
                    getPokemon(from: 1)
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            NavigationStack {
                List {
                    Section {
                        ForEach(pokedex) { pokemon in
                            NavigationLink(value: pokemon) {
                                // here is the label of the list item
                                AsyncImage(url: pokemon.sprite) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 100, height: 100)
                                
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(pokemon.name!.capitalized)
                                            .fontWeight(.bold)
                                        
                                        if pokemon.favorite {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                            
                                        }
                                    }
                                    
                                    
                                    HStack {
                                        ForEach(pokemon.types!, id: \.self) { type in
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
                                // Text(pokemon.name ?? "no name")
                            }
                            .swipeActions(edge: .leading) {
                                Button(pokemon.favorite ? "Remove from favorites" : "Add to favorites", systemImage: "star") {
                                    
                                    pokemon.favorite.toggle()
                                    do {
                                        try viewContext.save()
                                    } catch {
                                        print(error)
                                    }
                                }
                                .tint(pokemon.favorite ? .gray : .yellow)
                            }
                        }
                    } footer: {
                        if (all.count < 151) {
                            ContentUnavailableView {
                                Label("Missing pokemon", image: .nopokemon)
                            } description: {
                                Text("The fetch was interrupted.\nFetch the rest of the pokemon.")
                            } actions: {
                                Button("Fetch pokemon", systemImage: "antena.radiowaves.leftandright") {
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
                .onChange(of: searchText) {
                    pokedex.nsPredicate = dynamicPredicate
                }
                .onChange(of: filterByFavorites) {
                    pokedex.nsPredicate = dynamicPredicate
                }
                .navigationDestination(for: Pokemon.self) { pokemon in
                    // Pass the pokemon from core data in an environment object
                    PokemonDetailView()
                        .environmentObject(pokemon)
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
            //        .task {
            //            getPokemon()
            //        }
        }
    }
    
    private func getPokemon(from id: Int) {
        Task {
            for i in id..<152 {
                do {
                    let fetchedPokemon = try await fetcher.fetchPokemon(i)
                    
                    // Core data model
                    let pokemon = Pokemon(context: viewContext)
                    pokemon.id = fetchedPokemon.id
                    pokemon.name = fetchedPokemon.name
                    pokemon.types = fetchedPokemon.types
                    pokemon.hp = fetchedPokemon.hp
                    pokemon.attack = fetchedPokemon.attack
                    pokemon.defense = fetchedPokemon.defense
                    pokemon.specialAttack = fetchedPokemon.specialAttack
                    pokemon.specialDefense = fetchedPokemon.specialDefense
                    pokemon.speed = fetchedPokemon.speed
                    pokemon.sprite = fetchedPokemon.sprite
                    pokemon.shiny = fetchedPokemon.shiny
                    
//                    if pokemon.id % 2 == 0 {
//                        pokemon.favorite = true
//                    }
                    
                    try viewContext.save()
                    
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

