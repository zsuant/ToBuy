//
//  Model.swift
//  ToBuy
//
//  Created by 이수겸 on 2024/06/25.
//

import Foundation
import CoreData

// Task 엔티티
public class Task: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var items: NSSet

    public var itemArray: [ToBuy] {
        let set = items as? Set<ToBuy> ?? []
        return set.sorted {
            $0.order < $1.order
        }
    }
}

extension Task {
    static func getAllTasksFetchRequest() -> NSFetchRequest<Task> {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }
}

// Item 엔티티
public class Item: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var order: Int64
    @NSManaged public var task: Task?
}

extension Item {
    static func getAllItemsFetchRequest(for task: Task) -> NSFetchRequest<Item> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "task == %@", task)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        return request
    }
}
