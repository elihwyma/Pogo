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
        view.addSubview(tools)
        view.addSubview(statusLabel!)
        view.addSubview(version)
        
        NSLayoutConstraint.activate([
            install.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            install.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            install.heightAnchor.constraint(equalToConstant: 30),
            install.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),

            tools.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tools.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tools.heightAnchor.constraint(equalToConstant: 30),
            tools.topAnchor.constraint(equalTo: install.bottomAnchor, constant: 30),
            
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
         
        guard let deb = Bundle.main.path(forResource: "org.coolstar.sileo_2.3_iphoneos-arm", ofType: "deb") else {
            NSLog("[POGO] Could not find deb")
            return
        }

        guard let libswift = Bundle.main.path(forResource: "libswift", ofType: "deb") else {
            NSLog("[POGO] Could not find libswift")
            return
        }

        guard let safemode = Bundle.main.path(forResource: "safemode", ofType: "deb") else {
            NSLog("[POGO] Could not find safemode")
            return
        }

        guard let preferenceloader = Bundle.main.path(forResource: "preferenceloader", ofType: "deb") else {
            NSLog("[POGO] Could not find preferenceloader")
            return
        }

        guard let substitute = Bundle.main.path(forResource: "substitute", ofType: "deb") else {
            NSLog("[POGO] Could not find substitute")
            return
        }
        statusLabel?.text = "Installing Bootstrap"
        DispatchQueue.global(qos: .utility).async { [self] in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
            let ret = spawn(command: helper, args: ["-i", tar], root: true)
            spawn(command: "/usr/bin/chmod", args: ["4755", "/usr/bin/sudo"], root: true)
            spawn(command: "/usr/bin/chown", args: ["root:wheel", "/usr/bin/sudo"], root: true)
            DispatchQueue.main.async {
                if ret != 0 {
                    self.statusLabel?.text = "Error Installing Bootstrap \(ret)"
                    return
                }
                self.statusLabel?.text = "Preparing Bootstrap"
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: "/usr/bin/sh", args: ["/prep_bootstrap.sh"], root: true)
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
                        self.statusLabel?.text = "Installing Packages"
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/usr/bin/dpkg", args: ["-i", deb, libswift, safemode, preferenceloader, substitute], root: true)
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    self.statusLabel?.text = "Failed to install packages \(ret)"
                                    return
                                }
                                self.statusLabel?.text = "UICache Sileo"
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/usr/bin/uicache", args: ["-p", "/Applications/Sileo.app"], root: true)
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
  
    @objc private func runUiCache() {
        DispatchQueue.global(qos: .utility).async {
            // for every .app file in /Applications, run uicache -p
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/usr/bin/uicache", args: ["-p", "/Applications/\(app)"], root: true)
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
        alert.addAction(UIAlertAction(title: "Remount R/W", style: .default, handler: { _ in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/" ], root: true)
            self.statusLabel?.text = "Remounted Preboot R/W"
        }))
        alert.addAction(UIAlertAction(title: "Launch Daemons", style: .default, handler: { _ in
            spawn(command: "/bin/launchctl", args: ["bootstrap", "system", "/Library/LaunchDaemons"], root: true)
            self.statusLabel?.text = "done"
        }))
        alert.addAction(UIAlertAction(title: "Respring", style: .default, handler: { _ in
            spawn(command: "/usr/bin/sbreload", args: [], root: true)
        }))
        alert.addAction(UIAlertAction(title: "Do All", style: .default, handler: { _ in
            self.runUiCache()
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/" ], root: true)
            spawn(command: "/bin/launchctl", args: ["bootstrap", "system", "/Library/LaunchDaemons"], root: true)
            spawn(command: "/usr/bin/sbreload", args: [], root: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
 
