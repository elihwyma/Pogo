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
        
        statusLabel = UILabel(frame: .zero)
        statusLabel!.translatesAutoresizingMaskIntoConstraints = false
        statusLabel?.textColor = .label
        
        view.addSubview(install)
        view.addSubview(remove)
        view.addSubview(statusLabel!)
        
        NSLayoutConstraint.activate([
            install.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            install.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            install.heightAnchor.constraint(equalToConstant: 30),
            install.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            
            remove.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            remove.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            remove.heightAnchor.constraint(equalToConstant: 30),
            remove.topAnchor.constraint(equalTo: install.bottomAnchor, constant: 30),
            
            statusLabel!.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            statusLabel!.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            statusLabel!.heightAnchor.constraint(equalToConstant: 30),
            statusLabel!.topAnchor.constraint(equalTo: remove.bottomAnchor, constant: 30)
        ])
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
    
}
 
