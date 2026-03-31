//
//  ShareViewController.swift
//  ShareExtension
//

import UIKit
import UniformTypeIdentifiers

/// Share extension: saves the shared job URL/text to App Group UserDefaults,
/// shows a brief "Job saved!" confirmation, then dismisses itself.
/// The main Hirefy app picks up the data via AppLifecycleState.resumed.
class ShareViewController: UIViewController {

    private let appGroupID = "group.careers.hirefy.app"
    private let sharedTextKey = "sharedJobText"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        processSharedItems()
    }

    private func processSharedItems() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            showResult(success: false)
            return
        }

        let group = DispatchGroup()
        var collectedText = ""

        for item in items {
            for provider in (item.attachments ?? []) {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, _ in
                        if let url = data as? URL { collectedText = url.absoluteString }
                        group.leave()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                        if let text = data as? String, collectedText.isEmpty { collectedText = text }
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            let trimmed = collectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            var saved = false
            if !trimmed.isEmpty, let defaults = UserDefaults(suiteName: self.appGroupID) {
                defaults.set(trimmed, forKey: self.sharedTextKey)
                defaults.synchronize()
                saved = true
            }
            self.showResult(success: saved)
        }
    }

    private func showResult(success: Bool) {
        let icon = UIImageView()
        icon.image = UIImage(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
        icon.tintColor = success
            ? UIColor(red: 0.22, green: 0.70, blue: 0.45, alpha: 1)
            : UIColor.systemRed
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = success ? "Job saved!\nOpen Hirefy to optimize." : "Could not save. Try again."
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
        ])

        // Dismiss after 1.2s — returns user to LinkedIn, then they switch to Hirefy
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}

