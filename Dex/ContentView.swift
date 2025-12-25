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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Pokemnon.name, ascending: true)],
        animation: .default)
    private var pokemnon: FetchedResults<Pokemnon>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(pokemnon) { pokemon in
                    NavigationLink {
                        Text(pokemon.name ?? "Unknown")
                    } label: {
                        Text(pokemon.name ?? "Unknown")
                    }
                }
                .onDelete(perform: deletePokemnon)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addPokemnon) {
                        Label("Add Pokemon", systemImage: "plus")
                    }
                }
            }
            Text("Select a Pokemon")
        }
    }
    
    private func addPokemnon() {
        withAnimation {
            let newPokemon = Pokemnon(context: viewContext)
            newPokemon.name = "Pokemon #\(Int.random(in: 1...1000))"
            newPokemon.id = Int16.random(in: 1...1000)
            // Set other properties as needed
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deletePokemnon(offsets: IndexSet) {
        withAnimation {
            offsets.map { pokemnon[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
