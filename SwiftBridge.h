//  SwiftBridge.h
//  Declarations for the Swift functions exposed to C/C++ via @_cdecl.
//  Implemented in Swift/PluginSwift.swift.
//
//  Note: @_cdecl functions are NOT emitted into the Xcode-generated
//  "<module>-Swift.h" header (that one only lists @objc API), so we declare
//  them here ourselves with C linkage.

#ifndef SWIFT_BRIDGE_H
#define SWIFT_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

/* Returns a malloc'd UTF-8 C string; the caller must release it with free().
   Implemented in Swift as @_cdecl("swift_greeting"). */
char *swift_greeting(const char *name);

#ifdef __cplusplus
}
#endif

#endif /* SWIFT_BRIDGE_H */
