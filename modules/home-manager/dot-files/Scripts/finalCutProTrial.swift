#!/usr/bin/swift

import Foundation

let path = URL(fileURLWithPath: NSString(string: "~/Library/Application Support/.ffuserdata").expandingTildeInPath)
let data = try! NSData(contentsOf: path) as Data
let dictionary = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! NSDictionary
let mutableDictionary = dictionary.mutableCopy() as! NSMutableDictionary

for (key, value) in mutableDictionary {
  if value is NSDate {
    mutableDictionary[key] = Date()
  }
}

try! NSKeyedArchiver.archivedData(withRootObject: mutableDictionary, requiringSecureCoding: false).write(to: path)

print("You'd better buy it")
