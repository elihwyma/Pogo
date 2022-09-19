//
//  ViewController.swift
//  Pogo
//
//  Created by Amy While on 12/09/2022.
//

import UIKit
import Darwin.POSIX

class ViewController: BaseViewController {
    
    private var isWorking = false
    private var statusLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = "Pogo"
        
        let install = UIButton(frame: .zero)
        install.translatesAutoresizingMaskIntoConstraints = false
        install.setTitle("Install", for: .normal)
        install.addTarget(self, action: #selector(startInstall), for: .touchUpInside)
        install.setTitleColor(.label, for: .normal)
        
        let remove = UIButton(frame: .zero)
        remove.translatesAutoresizingMaskIntoConstraints = false
        remove.setTitle("Remove", for: .normal)
        remove.addTarget(self, action: #selector(startRemove), for: .touchUpInside)
        remove.setTitleColor(.label, for: .normal)

        let tools = UIButton(frame: .zero)
        tools.translatesAutoresizingMaskIntoConstraints = false
        tools.setTitle("Tools", for: .normal)
        tools.addTarget(self, action: #selector(showTools), for: .touchUpInside)
        tools.setTitleColor(.label, for: .normal)
        
        statusLabel = UILabel(frame: .zero)
        statusLabel!.translatesAutoresizingMaskIntoConstraints = false
        statusLabel?.textColor = .label

        let version = UILabel(frame: .zero)
        version.translatesAutoresizingMaskIntoConstraints = false
        version.textColor = .label
        
        view.addSubview(install)
        view.addSubview(remove)
        view.addSubview(tools)
        view.addSubview(statusLabel!)
        view.addSubview(version)
        
        NSLayoutConstraint.activate([
            install.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            install.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            install.heightAnchor.constraint(equalToConstant: 30),
            install.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            
            remove.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            remove.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            remove.heightAnchor.constraint(equalToConstant: 30),
            remove.topAnchor.constraint(equalTo: install.bottomAnchor, constant: 30),

            tools.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tools.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tools.heightAnchor.constraint(equalToConstant: 30),
            tools.topAnchor.constraint(equalTo: remove.bottomAnchor, constant: 30),
            
            statusLabel!.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            statusLabel!.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            statusLabel!.heightAnchor.constraint(equalToConstant: 30),
            statusLabel!.topAnchor.constraint(equalTo: tools.bottomAnchor, constant: 30),

            version.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            version.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            version.heightAnchor.constraint(equalToConstant: 30),
            version.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])

        let gitCommit = Bundle.main.infoDictionary?["REVISION"] as? String ?? "unknown"
        version.text = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown") (\(gitCommit))"
    }
    
    @objc private func startInstall() {
        guard !isWorking else { return }
        isWorking = true
        guard let tar = Bundle.main.path(forResource: "bootstrap", ofType: "tar") else {
            NSLog("[POGO] Failed to find bootstrap")
            return
        }
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "PogoHelper") else {
            NSLog("[POGO] Could not find helper?")
            return
        }
         
        guard let deb = Bundle.main.path(forResource: "org.coolstar.sileo_2.4_iphoneos-arm64", ofType: ".deb") else {
            NSLog("[POGO] Could not find deb")
            return
        }
        statusLabel?.text = "Installing Bootstrap"
        DispatchQueue.global(qos: .utility).async { [self] in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            let ret = spawn(command: helper, args: ["-i", tar], root: true)
            spawn(command: "/var/jb/usr/bin/chmod", args: ["4755", "/var/jb/usr/bin/sudo"], root: true)
            spawn(command: "/var/jb/usr/bin/chown", args: ["root:wheel", "/var/jb/usr/bin/sudo"], root: true)
            DispatchQueue.main.async {
                if ret != 0 {
                    self.statusLabel?.text = "Error Installing Bootstrap \(ret)"
                    return
                }
                self.statusLabel?.text = "Preparing Bootstrap"
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: "/var/jb/usr/bin/sh", args: ["/var/jb/prep_bootstrap.sh"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            self.statusLabel?.text = "Failed to prepare bootstrap \(ret)"
                            // if ret is -1, it probably means that amfi is not patched, show a alert
                            if ret == -1 {
                                let alert = UIAlertController(title: "Error", message: "Failed with -1, are you sure you have amfi patched?", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "NO", style: .default, handler: nil))
                                // show the alert
                                self.present(alert, animated: true)
                            }
                            return
                        }
                        self.statusLabel?.text = "Installing Sileo"
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", deb], root: true)
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    self.statusLabel?.text = "Failed to install Sileo \(ret)"
                                    return
                                }
                                self.statusLabel?.text = "UICache Sileo"
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/Sileo-Nightly.app"], root: true)
                                    DispatchQueue.main.async {
                                        if ret != 0 {
                                            self.statusLabel?.text = "failed to uicache \(ret)"
                                            return
                                        }
                                        self.statusLabel?.text = "uicache succesful, have fun!"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
  
    @objc private func startRemove() {
        guard !isWorking else { return }
        isWorking = true
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "PogoHelper") else {
            NSLog("[POGO] Could not find helper?")
            return
        }
        statusLabel?.text = "Unregistering apps"
        DispatchQueue.global(qos: .utility).async {
            // for every .app file in /var/jb/Applications, run uicache -u
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            self.statusLabel?.text = "failed to unregister \(ret)"
                            return
                        }
                    }                
                }
            }

        }
        statusLabel?.text = "Removing Strap"
        DispatchQueue.global(qos: .utility).async { [self] in
            let ret = spawn(command: helper, args: ["-r"], root: true)
            DispatchQueue.main.async {
                if ret != 0 {
                    self.statusLabel?.text = "Failed to remove :( \(ret)"
                }
                self.statusLabel?.text = "omg its gone!"
            }
        }
    }
    @objc private func runUiCache() {
        DispatchQueue.global(qos: .utility).async {
            // for every .app file in /var/jb/Applications, run uicache -p
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/\(app)"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            self.statusLabel?.text = "failed to uicache \(ret)"
                            return
                        }
                        self.statusLabel?.text = "uicache succesful, have fun!"
                    }                
                }
            }

        }
    }

    // tools popup
    @objc private func showTools() {
        let alert = UIAlertController(title: "Tools", message: "Select", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "uicache", style: .default, handler: { _ in
            self.runUiCache()
        }))
        alert.addAction(UIAlertAction(title: "Remount Preboot", style: .default, handler: { _ in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            self.statusLabel?.text = "Remounted Preboot R/W"
        }))
        alert.addAction(UIAlertAction(title: "Launch Daemons", style: .default, handler: { _ in
            spawn(command: "/var/jb/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
            self.statusLabel?.text = "done"
        }))
        alert.addAction(UIAlertAction(title: "Respring", style: .default, handler: { _ in
            spawn(command: "/var/jb/usr/bin/sbreload", args: [], root: true)
        }))
        alert.addAction(UIAlertAction(title: "Do All", style: .default, handler: { _ in
            self.runUiCache()
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/var/jb/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
            spawn(command: "/var/jb/usr/bin/sbreload", args: [], root: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
 
