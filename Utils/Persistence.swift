//  Persistence.swift
//  PicturesEverywere
//  Created by Jael Fautino Ruvalcaba Tabares on 26/01/23.


import CoreData

class PersistenceController: ObservableObject {
    
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PicturesEverywere")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
//    // Create
//    func createTask(title: String) {
//        let newTask = Task(context: managedObjectContext)
//        newTask.title = title
//        saveContext()
//    }
//    // Read
//    func fetchTasks() -> [Task] {
//        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
//        do {
//            let tasks = try managedObjectContext.fetch(fetchRequest)
//            return tasks
//        } catch {
//            print(error.localizedDescription)
//            return []
//        }
//    }
//    // Update
//    func updateTask(task: Task, newTitle: String) {
//        task.title = newTitle
//        saveContext()
//    }
//    // Delete
//    func deleteTask(task: Task) {
//        managedObjectContext.delete(task)
//        saveContext()
//    }
//    // Save
//    func saveContext() {
//        do {
//            try managedObjectContext.save()
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
    
    
}


//struct CoreDataStack: ObservableObject {
//    @Environment(\.managedObjectContext) var managedObjectContext
//
//}
