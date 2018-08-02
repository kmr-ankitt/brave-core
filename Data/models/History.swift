/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import CoreData
import Shared
import BraveShared

private func getDate(_ dayOffset: Int) -> Date {
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    let nowComponents = calendar.dateComponents([Calendar.Component.year, Calendar.Component.month, Calendar.Component.day], from: Date())
    let today = calendar.date(from: nowComponents)!
    return (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: dayOffset, to: today, options: [])!
}

private var ignoredSchemes = ["about"]

public func isIgnoredURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme else { return false }

    if let _ = ignoredSchemes.index(of: scheme) {
        return true
    }

    if url.host == "localhost" {
        return true
    }

    return false
}

public func isIgnoredURL(_ url: String) -> Bool {
    if let url = URL(string: url) {
        return isIgnoredURL(url)
    }

    return false
}

public final class History: NSManagedObject, WebsitePresentable, CRUD {

    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var visitedOn: Date?
    @NSManaged public var syncUUID: UUID?
    @NSManaged public var domain: Domain?
    @NSManaged public var sectionIdentifier: String?
    
    static let Today = getDate(0)
    static let Yesterday = getDate(-1)
    static let ThisWeek = getDate(-7)
    static let ThisMonth = getDate(-31)

    // Currently required, because not `syncable`
    static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "History", in: context)!
    }

    public class func add(_ title: String, url: URL) {
        let context = DataController.backgroundContext
        context.perform {
            var item = History.getExisting(url, context: context)
            if item == nil {
                item = History(entity: History.entity(context), insertInto: context)
                item!.domain = Domain.getOrCreateForUrl(url, context: context)
                item!.url = url.absoluteString
            }
            item?.title = title
            item?.domain?.visits += 1
            item?.visitedOn = Date()
            // BRAVE TODO:
//            item?.sectionIdentifier = BraveStrings.Today

            DataController.save(context)
        }
    }

    public class func frc() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let context = DataController.viewContext
        
        fetchRequest.entity = History.entity(context)
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 200
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"visitedOn", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "visitedOn >= %@", History.ThisMonth as CVarArg)

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:context, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
    }

    public override func awakeFromFetch() {
        if sectionIdentifier != nil {
            return
        }

        if visitedOn?.compare(History.Today) == ComparisonResult.orderedDescending {
            sectionIdentifier = Strings.Today
        } else if visitedOn?.compare(History.Yesterday) == ComparisonResult.orderedDescending {
            sectionIdentifier = Strings.Yesterday
        } else if visitedOn?.compare(History.ThisWeek) == ComparisonResult.orderedDescending {
            sectionIdentifier = Strings.Last_week
        } else {
            sectionIdentifier = Strings.Last_month
        }
    }

    class func getExisting(_ url: URL, context: NSManagedObjectContext) -> History? {
        let urlKeyPath = #keyPath(History.url)
        let predicate = NSPredicate(format: "\(urlKeyPath) == %@", url.absoluteString)
        
        return first(where: predicate)
    }

    class func frecencyQuery(_ context: NSManagedObjectContext, containing:String? = nil) -> [History] {
        let urlKeyPath = #keyPath(History.url)
        let visitedOnKeyPath = #keyPath(History.visitedOn) 

        var predicate = NSPredicate(format: "\(visitedOnKeyPath) > %@", History.ThisWeek as CVarArg)
        if let query = containing {
            predicate = NSPredicate(format: predicate.predicateFormat + " AND \(urlKeyPath) CONTAINS %@", query)
        }
        
        return all(where: predicate, fetchLimit: 100) ?? []
    }
    
    public class func deleteAll(_ completionOnMain: @escaping ()->()) {
        let context = DataController.backgroundContext
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = History.entity(context)
            fetchRequest.includesPropertyValues = false
            do {
                let results = try context.fetch(fetchRequest)
                for result in results {
                    context.delete(result as! NSManagedObject)
                }

            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            // No save, save in Domain

            Domain.deleteNonBookmarkedAndClearSiteVisits {
                completionOnMain()
            }
        }
    }

}
