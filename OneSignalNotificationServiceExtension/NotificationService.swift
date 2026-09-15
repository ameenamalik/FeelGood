//
//  NotificationService.swift
//  OneSignalNotificationServiceExtension
//
//  Forwards incoming pushes to OneSignal so it can attach rich media, report
//  Confirmed Delivery, and handle notification action buttons. Required
//  infrastructure for the OneSignal integration — see FeelGood/Services/OneSignalManager.swift.
//

import OneSignalExtension
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent {
            OneSignalExtension.didReceiveNotificationExtensionRequest(
                self.receivedRequest,
                with: bestAttemptContent,
                withContentHandler: self.contentHandler
            )
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(
                self.receivedRequest,
                with: self.bestAttemptContent
            )
            contentHandler(bestAttemptContent)
        }
    }
}
