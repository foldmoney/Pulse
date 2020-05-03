// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import CoreData

// MARK: - Logger.Store

public extension Logger {
    var store: Store {
        Store(container: container, context: backgroundContext)
    }

    struct Store {
        public let container: NSPersistentContainer
        public let context: NSManagedObjectContext

        public init(container: NSPersistentContainer, context: NSManagedObjectContext) {
            self.container = container
            self.context = context
        }
    }
}

// MARK: - Logger.Store (NSManagedObjectModel)

public extension Logger.Store {
    /// Returns Core Data model used by the store.
    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let message = NSEntityDescription()
        message.name = "LoggerMessage"
        message.managedObjectClassName = LoggerMessage.self.description()
        message.properties = [
            NSAttributeDescription(name: "createdAt", type: .dateAttributeType),
            NSAttributeDescription(name: "level", type: .stringAttributeType),
            NSAttributeDescription(name: "system", type: .stringAttributeType),
            NSAttributeDescription(name: "category", type: .stringAttributeType),
            NSAttributeDescription(name: "session", type: .stringAttributeType),
            NSAttributeDescription(name: "text", type: .stringAttributeType)
        ]

        model.entities = [message]
        return model
    }()
}

private extension NSAttributeDescription {
    convenience init(name: String, type: NSAttributeType) {
        self.init()
        self.name = name
        self.attributeType = type
    }

    convenience init(_ closure: (NSAttributeDescription) -> Void) {
        self.init()
        closure(self)
    }
}

// MARK: - Logger.Store (Accessing Messages)

public extension Logger.Store {

    /// Returns all recorded messages, most recent messages come first.
    func allMessage() throws -> [LoggerMessage] {
        let request = NSFetchRequest<LoggerMessage>(entityName: "LoggerMessage")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LoggerMessage.createdAt, ascending: true)]
        return try context.fetch(request)
    }

    /// Removes all of the previously recorded messages.
    func removeAllMessages() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = LoggerMessage.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        let result = try context.execute(deleteRequest)

        guard let deleteResult = result as? NSBatchDeleteResult,
            let ids = deleteResult.result as? [NSManagedObjectID]
            else { return }

        let changes = [NSDeletedObjectsKey: ids]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context, container.viewContext])
    }
}

// MARK: - LoggerMessage

public final class LoggerMessage: NSManagedObject {
    @NSManaged public var createdAt: Date
    @NSManaged public var level: String
    @NSManaged public var system: String
    @NSManaged public var category: String
    @NSManaged public var session: String
    @NSManaged public var text: String
}