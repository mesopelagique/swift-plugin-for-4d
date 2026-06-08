# swift-plugin-for-4d

A minimal **template for writing a [4D](https://www.4d.com) plugin in Swift**.

4D plugins are native bundles whose entry point is C/C++. This template shows how
to write your actual logic in **Swift**, expose it to the C++ side with a C calling
convention, and ship everything as a **single binary** `.bundle` — exactly like a
pure C++ plugin. No Swift dynamic libraries are embedded: the Swift runtime ships
with macOS (Swift-in-the-OS, 10.14.4+).

The template exposes one command, `Swift_Greeting`, as a worked example. Add your
own by following the same three-layer pattern below.

## How it works

A 4D command call travels through three layers:

```
4D method  ──►  C++ bridge (selector dispatch)  ──►  Swift implementation
Swift_Greeting   PluginMain → Swift_Greeting           swift_greeting()
```

| Layer | File | Role |
|-------|------|------|
| Swift implementation | [`Swift/PluginSwift.swift`](Swift/PluginSwift.swift) | The real logic. Functions are exported with [`@_cdecl`](Swift/PluginSwift.swift#L21) so they get C linkage. |
| C bridge header | [`SwiftBridge.h`](SwiftBridge.h) | Declares the Swift functions `extern "C"` so C++ can call them. |
| C++ plugin entry | [`4DPlugin.cpp`](4DPlugin.cpp) | `PluginMain` dispatches on the 4D selector, converts 4D's UTF‑16 ⇄ UTF‑8, and calls into Swift. |
| Command manifest | [`Resources/manifest.json`](Resources/manifest.json) | Maps the command name/syntax to a selector for 4D. |

### 1. Swift — [`Swift/PluginSwift.swift`](Swift/PluginSwift.swift)

The implementation is a plain Swift function exported with `@_cdecl`:

```swift
@_cdecl("swift_greeting")
public func swift_greeting(_ cName: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    let name = cName.map { String(cString: $0) } ?? ""
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let target = trimmed.isEmpty ? "world" : trimmed
    let message = "Hello \(target), from Swift!"
    return strdup(message) // ownership transferred to the C++ caller
}
```

> ⚠️ **Memory ownership:** the string is `strdup`'d in Swift and `free`'d on the
> C++ side ([`4DPlugin.cpp#L97`](4DPlugin.cpp#L97)). Each layer owns its half.

`@_cdecl` functions are **not** emitted into Xcode's generated `<module>-Swift.h`
header (that one only lists `@objc` API), so we declare them by hand in
[`SwiftBridge.h`](SwiftBridge.h#L18).

### 2. C++ bridge — [`4DPlugin.cpp`](4DPlugin.cpp)

`PluginMain` routes the 4D selector to the matching wrapper, which marshals
parameters and calls the Swift function:

```cpp
void PluginMain( PA_long32 selector, PA_PluginParameters params )
{
    switch( selector )
    {
        case 1 : Swift_Greeting( params ); break;   // see manifest.json
    }
}

// Syntax: Swift_Greeting(&T):T
void Swift_Greeting( PA_PluginParameters params )
{
    std::string name = GetUTF8Parameter( params, 1 );
    char* greeting = swift_greeting( name.c_str() ); // implemented in Swift
    ReturnUTF8( params, greeting );
    free( greeting );                                // release Swift's strdup()
}
```

The helpers [`GetUTF8Parameter`](4DPlugin.cpp#L27) and [`ReturnUTF8`](4DPlugin.cpp#L56)
handle the UTF‑16 ⇄ UTF‑8 conversion 4D needs (via CoreFoundation).

### 3. Command manifest — [`Resources/manifest.json`](Resources/manifest.json)

```json
{
  "name": "Swift",
  "id": 15000,
  "commands": [
    { "theme": "Swift", "syntax": "Swift_Greeting(&T):T", "threadSafe": true }
  ]
}
```

The command's position in the `commands` array is its selector (the first command
is selector `1`, matching the `case 1` above).

## Calling it from 4D

Once the plugin is built and installed, call the command like any other 4D command.

```4d
var $greeting : Text
$greeting:=Swift_Greeting("Eric")  // "Hello Eric, from Swift!"
```

## Adding your own command

1. Write a Swift function with `@_cdecl("my_function")` in [`Swift/PluginSwift.swift`](Swift/PluginSwift.swift).
2. Declare it `extern "C"` in [`SwiftBridge.h`](SwiftBridge.h).
3. Add a `void My_Command(PA_PluginParameters)` wrapper and a new `case` in
   `PluginMain` in [`4DPlugin.cpp`](4DPlugin.cpp).
4. Append the command to the `commands` array in
   [`Resources/manifest.json`](Resources/manifest.json) (its array index = selector).

## Building

Open `Swifty4DPlugin.xcodeproj` in Xcode and build the **4D Plugin** target, or
build from the command line. The output is `Swifty4DPlugin.bundle`.

Key build settings (in [`project.pbxproj`](Swifty4DPlugin.xcodeproj/project.pbxproj))
that make the single-binary, Swift-in-the-OS approach work:

| Setting | Value | Why |
|---------|-------|-----|
| `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` | `NO` | Don't bundle the Swift runtime — use the one in macOS, keeping a single binary. |
| `LD_RUNPATH_SEARCH_PATHS` | `/usr/lib/swift` | Find the OS Swift runtime at load time. |
| `SWIFT_INSTALL_OBJC_HEADER` | `NO` | No generated `-Swift.h`; the C bridge is declared manually in `SwiftBridge.h`. |
| `WRAPPER_EXTENSION` / `LIBRARY_STYLE` | `bundle` / `Bundle` | Produce a loadable 4D plugin bundle. |
| `MACOSX_DEPLOYMENT_TARGET` | `11.0` | Minimum macOS (Swift-in-the-OS requires 10.14.4+). |

### Installing

Copy `Swifty4DPlugin.bundle` into your 4D project's `Plugins` folder, then restart 4D.

## Layout

```
swift-plugin-for-4d/
├── Swift/PluginSwift.swift     # Swift implementation (@_cdecl exports)
├── SwiftBridge.h               # C declarations of the Swift functions
├── 4DPlugin.cpp                # C++ entry point + selector dispatch
├── 4DPlugin.h
├── Resources/manifest.json     # 4D command definitions
├── 4D Plugin API/              # 4D plugin API headers (PA_*)
├── Info.plist                  # bundle metadata (4DCB package type)
└── Swifty4DPlugin.xcodeproj/   # Xcode project
```

## License

MIT.
