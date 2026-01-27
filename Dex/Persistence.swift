//
//  Persistence.swift
//  Dex
//
//  Created by Gustavo Loaiza Robles on 6/12/25.
//

import SwiftData
import Foundation

@MainActor
struct PersistenceController {
    
    static var previewPokemon: Pokemon {
        let decoder = JSONDecoder()
        
        decoder .keyDecodingStrategy = .convertFromSnakeCase
        
        let pokemonData = try! Data(contentsOf: Bundle.main.url(forResource: "samplepokemon", withExtension: "json")!)
        
        let pokemon = try! decoder.decode(Pokemon.self, from: pokemonData)
        
        return pokemon
    }
    
    // Our sample preview database
    static let preview: ModelContainer = {
        let container = try! ModelContainer(for: Pokemon.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        container.mainContext.insert(previewPokemon)
        
        return container
    }()
}
