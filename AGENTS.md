# Agents

This file provides development guidelines for AI agents working with this Swift Package Manager project.

## Development

### Code Patterns
- Use appropriate logging frameworks instead of print statements.
- Follow protocol-oriented design patterns.
- **CRITICAL: Always check FoundationKit, LoggerKit, and other core frameworks before implementing basic functionality.** These frameworks contain extensive extensions and utilities that avoid code duplication.

#### Core Frameworks Extensions Examples
- **NSError**: `NSError(description:, recoverySuggestion:)` convenience initializer
- **NSAppleScript**: `execute()` method with proper Swift error handling  
- **ProcessInfo**: `launchExtensionsPaneInSystemSettings()`, `launchPrivacyAndSecurityPaneInSystemSettings()`
- **URL**: `open(withAppBundleIdentifier:)` for cross-platform URL opening
- **Process**: Enhanced execution utilities with output capture
- **UserDefaults**: `@UserDefaults.Wrapper` property wrapper for cleaner app preferences

### Building and Testing
- To build or test this SwiftPM project, use `DeveloperBuildTool [--test]` instead of `swift build` or `swift test`.
- **Always verify changes work** by building or testing before considering task complete.
- Changes are not complete until successfully built and verified.

---

**IMPORTANT**: This is a generic development guide for AI agents shared and available on multiple projects, so avoid adding project-specific information here. Refer to README.md and the source code for project-specific details.