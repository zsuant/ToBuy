//
//  TaskView.swift
//  ToBuy
//
//  Created by 이수겸 on 2024/06/25.
//

import Foundation
import SwiftUI
import CoreData

struct TaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(fetchRequest: Task.getAllTasksFetchRequest()) private var tasks: FetchedResults<Task>
    
    @State private var newTaskTitle = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(tasks, id: \.id) { task in
                    NavigationLink(destination: ItemView(task: task)) {
                        Text(task.title)
                    }
                }
                .onDelete(perform: deleteTasks)
                .onMove(perform: moveTasks)
            }
            .navigationTitle("할 일 목록")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addTask) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addTask() {
        withAnimation {
            let newTask = Task(context: viewContext)
            newTask.id = UUID()
            newTask.title = "할 일 \(tasks.count + 1)"
            newTask.items = []
            do {
                try viewContext.save()
            } catch {
                print("Error saving new task: \(error)")
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting tasks: \(error)")
            }
        }
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        withAnimation {
            var revisedTasks = tasks.map { $0 }
            revisedTasks.move(fromOffsets: source, toOffset: destination)
            for reverseIndex in stride(from: revisedTasks.count - 1, through: 0, by: -1) {
                revisedTasks[reverseIndex].objectWillChange.send()
            }
            do {
                try viewContext.save()
            } catch {
                print("Error moving tasks: \(error)")
            }
        }
    }
}

