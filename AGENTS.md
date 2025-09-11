# Agents

This file provides critical development and deployment guidelines for AI agents working with this app project.

## Development

### Project Structure
- App-specific logic belongs in framework targets.
- **External SwiftPM dependencies** contain shared logic and helper functions.
- UI code should be separated from business logic.
- For app development focus on the **Xcode project**. Package.swift typically supports building CLI tools only.

### Code Patterns
- Use appropriate logging frameworks instead of print statements.
- Follow protocol-oriented design patterns.
- **CRITICAL: Always check FoundationKit, LoggerKit, SwiftUIKit, and other core frameworks before implementing basic functionality.** These frameworks contain extensive extensions and utilities that avoid code duplication.

#### Core Frameworks Extensions Examples
- **NSError**: `NSError(description:, recoverySuggestion:)` convenience initializer
- **NSAppleScript**: `execute()` method with proper Swift error handling  
- **ProcessInfo**: `launchExtensionsPaneInSystemSettings()`, `launchPrivacyAndSecurityPaneInSystemSettings()`
- **URL**: `open(withAppBundleIdentifier:)` for cross-platform URL opening
- **Process**: Enhanced execution utilities with output capture
- **UserDefaults**: `@UserDefaults.Wrapper` property wrapper for cleaner app preferences

### Working with External SwiftPM Dependencies
- External dependencies are separate SwiftPM repositories shared across multiple apps.
- Changes to core models, utilities, business rules must be made in their respective packages (typically you can find them in the project parent directory).
- To build or test a SwiftPM project use `DeveloperBuildTool` instead of `swift build`.
- Workflow: Edit external package → Build → Commit & Push → Return to main project → Reload package dependencies → Rebuild.

### Verification Requirements
- **Always verify changes work** by building or testing before considering task complete.
- Build or test external dependencies if changes were made to them.
- Build main project to ensure all changes integrate properly.
- Run the application when possible to ensure functionality works as expected. Make sure to terminate any running instances of the app before running again.
- Changes are not complete until successfully built and verified.

### Development Workflow
- All development work is done from the `master` branch.
- By default, feature development, bug fixes, and general improvements happen directly on `master`.
- Optionally, `feature/` or `fix/` branches can be created for parallel work.

## Deployment

### Release Process
For app releases:
1. **Version Update**: Update the Xcode project Marketing Version setting and / or the `CFBundleShortVersionString` in all relevant Info.plist files. Use the standard versioning format (eg. `1.0`, then `1.1` or `1.0.1` for minor updates). Ensure the version is consistent across all targets (app, extensions, frameworks).
2. **Commit Changes**: Add, commit, and push all pending changes to `master` branch.
3. **Merge to Release**: Switch to `release` branch, merge from `master`, and push to remote. Note: Only the `release` branch is linked to Xcode Cloud for automated builds.
4. **Tag Release**: After pushing to `release` branch, you MUST ALWAYS create and push a git tag. Use the `v1.0` or `v1.0.1` format for tags and a message like `ProjectName v1.0.1`. Create or replace the new tag and push to remote with force flag. Always use the same version number as the one in the Xcode project, if it did not change, use the same tag as the previous release.
5. **Back to Master**: Switch back to `master` branch for further development.

**CRITICAL**: Each time you push to the `release` branch make sure to **always** tag it with current project version. This is crucial for maintaining a clear version history.

---

**IMPORTANT**: This is a generic development guide for AI agents shared and available on multiple app projects, so avoid adding project-specific information here. Refer to README.md and the source code for project-specific details.