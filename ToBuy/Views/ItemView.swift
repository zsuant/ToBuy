//
//  ItemView.swift
//  ToBuy
//
//  Created by 이수겸 on 2024/06/25.
//

import Foundation
import SwiftUI
import CoreData

struct ItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var task: Task
    
    @State private var newItemText = ""

    var body: some View {
        VStack {
            List {
                ForEach(task.itemArray, id: \.id) { item in
                    Text(item.text)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .navigationBarTitle(task.title)
            .navigationBarItems(trailing: Button(action: addItem) {
                Image(systemName: "plus")
            })
            
            TextField("항목 추가", text: $newItemText, onCommit: {
                addItem()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        }
    }

    private func addItem() {
        guard !newItemText.isEmpty else { return }
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.id = UUID()
            newItem.text = newItemText
            newItem.order = Int64(task.items.count)
            newItem.task = task
            
            do {
                try viewContext.save()
                newItemText = ""
            } catch {
                print("Error saving new item: \(error)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { task.itemArray[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting items: \(error)")
            }
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        withAnimation {
            var revisedItems = task.itemArray
            revisedItems.move(fromOffsets: source, toOffset: destination)
            for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
                revisedItems[reverseIndex].order = Int64(reverseIndex)
            }
            do {
                try viewContext.save()
            } catch {
                print("Error moving items: \(error)")
            }
        }
    }
}
