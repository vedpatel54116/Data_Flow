import SwiftUI

/// Design constants for the app's layout and HID configuration.
public enum DesignTokens: Sendable {
    /// Layout dimensions and spacing constants.
    public enum Layout {
        /// Default window width in points.
        public static let windowWidth: CGFloat = 700
        /// Default window height in points.
        public static let windowHeight: CGFloat = 720
        /// Side panel width in points.
        public static let sidebarWidth: CGFloat = 200
        /// Corner radius for card views.
        public static let cardCornerRadius: CGFloat = 14
        /// Corner radius for buttons.
        public static let buttonCornerRadius: CGFloat = 12
        /// Standard padding between elements.
        public static let standardPadding: CGFloat = 16
        /// Tight padding for compact layouts.
        public static let tightPadding: CGFloat = 8
        /// Spacing between sections.
        public static let sectionSpacing: CGFloat = 20
    }
    
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.8
    }
    
    enum Timing {
        static let hidTimeoutMs: UInt32 = 5000
        static let debounceIntervalMs: UInt32 = 50
        static let retryDelayMs: UInt32 = 1000
    }
    
    /// HID report constants for keyboard communication.
    enum HID {
        /// Report ID for HID packets.
        static let reportID: UInt8 = 0x01
        /// Maximum report payload size in bytes.
        static let maxReportSize: Int = 64
        /// Vendor ID for the keyboard device.
        static let vendorID: UInt16 = 0x1234  // Replace with actual
        /// Product ID for the keyboard device.
        static let productID: UInt16 = 0x5678   // Replace with actual
    }
}
