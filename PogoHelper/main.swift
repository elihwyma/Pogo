//
//  main.swift
//  PogoHelper
//
//  Created by Amy While on 12/09/2022.
//

import Foundation
import ArgumentParser
import SWCompression

struct Strap: ParsableCommand {
    
    @Option(name: .shortAndLong, help: "The path to the .tar file you want to strap with")
    var input: String?
    
    @Flag(name: .shortAndLong, help: "Remove the bootstrap")
    var remove: Bool = false
    
    mutating func run() throws {
        NSLog("[POGO] Spawned!")
        guard getuid() == 0 else { fatalError() }

        if let input = input {
            NSLog("[POGO] Attempting to install \(input)")
            
            let active = "/private/preboot/active"
            let uuid: String
            do {
                uuid = try String(contentsOf: URL(fileURLWithPath: active), encoding: .utf8)
            } catch {
                NSLog("[POGO] Could not find active directory")
                fatalError()
            }
            let dest = "/private/preboot/\(uuid)/procursus"
            do {
                try autoreleasepool {
                    let data = try Data(contentsOf: URL(fileURLWithPath: input))
                    let container = try TarContainer.open(container: data)
                    NSLog("[POGO] Opened Container")
                    for entry in container {
                        do {
                            var path = entry.info.name
                            if path.first == "." {
                                path.removeFirst()
                            }
                            if path == "/" || path == "/var" {
                                continue
                            }
                            path = path.replacingOccurrences(of: "/var/jb", with: dest)
                            switch entry.info.type {
                            case .symbolicLink:
                                var linkName = entry.info.linkName
                                if !linkName.contains("/") || linkName.contains("..") {
                                    var tmp = path.split(separator: "/").map { String($0) }
                                    tmp.removeLast()
                                    tmp.append(linkName)
                                    linkName = tmp.joined(separator: "/")
                                    if linkName.first != "/" {
                                        linkName = "/" + linkName
                                    }
                                    linkName = linkName.replacingOccurrences(of: "/var/jb", with: dest)
                                } else {
                                    linkName = linkName.replacingOccurrences(of: "/var/jb", with: dest)
                                }
                                NSLog("[POGO] \(entry.info.linkName) at \(linkName) to \(path)")
                                try FileManager.default.createSymbolicLink(atPath: path, withDestinationPath: linkName)
                            case .directory:
                                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                            case .regular:
                                guard let data = entry.data else { continue }
                                try data.write(to: URL(fileURLWithPath: path))
                            default:
                                NSLog("[POGO] Unknown Action for \(entry.info.type)")
                            }
                            var attributes = [FileAttributeKey: Any]()
                            attributes[.posixPermissions] = entry.info.permissions?.rawValue
                            attributes[.ownerAccountName] = entry.info.ownerUserName
                            var ownerGroupName = entry.info.ownerGroupName
                            if ownerGroupName == "staff" && entry.info.ownerUserName == "root" {
                                ownerGroupName = "wheel"
                            }
                            attributes[.groupOwnerAccountName] = ownerGroupName
                            do {
                                try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
                            } catch {
                                continue
                            }
                        } catch {
                            NSLog("[POGO] error \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                NSLog("[POGO] Failed with error \(error.localizedDescription)")
                return
            }
            NSLog("[POGO] Strapped to \(dest)")
            do {
                if !FileManager.default.fileExists(atPath: "/var/jb") {
                    try FileManager.default.createSymbolicLink(atPath: "/var/jb", withDestinationPath: dest)
                }
            } catch {
                NSLog("[POGO] Failed to make link")
                fatalError()
            }
            NSLog("[POGO] Linked to /var/jb")
            var attributes = [FileAttributeKey: Any]()
            attributes[.posixPermissions] = 0o755
            attributes[.ownerAccountName] = "mobile"
            attributes[.groupOwnerAccountName] = "mobile"
            do {
                try FileManager.default.setAttributes(attributes, ofItemAtPath: "/var/jb/var/mobile")
            } catch {
                NSLog("[POGO] thats wild")
            }
        } else if remove {
            let active = "/private/preboot/active"
            let uuid: String
            do {
                uuid = try String(contentsOf: URL(fileURLWithPath: active), encoding: .utf8)
            } catch {
                NSLog("[POGO] Could not find active directory")
                fatalError()
            }
            let dest = "/private/preboot/\(uuid)/procursus"
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: dest))
                try FileManager.default.removeItem(at: URL(fileURLWithPath: "/var/jb"))
            } catch {
                NSLog("[POGO] Failed with error \(error.localizedDescription)")
            }
            
        }
    }
    
}

Strap.main()
