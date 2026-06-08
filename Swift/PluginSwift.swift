//  PluginSwift.swift
//  new Project — Swift code for a 4D plugin
//
//  Swift functions are exposed to the C/C++ side of the plugin with a C calling
//  convention using @_cdecl. The C++ code (see SwiftBridge.h and 4DPlugin.cpp)
//  declares them `extern "C"` and calls them directly. Everything is compiled and
//  linked into the single plugin binary, so 4D still loads one .bundle / one
//  executable, exactly like a pure C++ plugin.
//
//  No Swift dynamic libraries are embedded in the .bundle: the Swift runtime ships
//  with macOS (Swift-in-the-OS, 10.14.4+). The Xcode setting
//  ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = NO keeps the bundle at a single binary.

import Foundation

/// Build a greeting for `name`, computed in Swift.
///
/// - Parameter cName: a UTF-8, NUL-terminated C string coming from 4D (may be NULL).
/// - Returns: a freshly `malloc`'d UTF-8 C string. **The C++ caller owns the result
///   and must release it with `free()`** (see `Swift_Greeting` in 4DPlugin.cpp).
@_cdecl("swift_greeting")
public func swift_greeting(_ cName: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    let name = cName.map { String(cString: $0) } ?? ""
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let target = trimmed.isEmpty ? "world" : trimmed
    let message = "Hello \(target), from Swift!"
    return strdup(message) // ownership transferred to the C++ caller
}
