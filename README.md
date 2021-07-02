# P2P Task Manager

A privacy-aware task manager. No account needed, all your tasks get synced using the local network only.
Because your data belongs to you!

## Setup

Follow the instruction on <https://flutter.dev/docs/get-started/install> to install flutter.

Clone this repository and open a terminal window in the root directory:

- Run `git submodule init && git submodule update` (this project uses the lww_crdt library as a submodule)
- Run `flutter pub get` in the terminal to load all dependencies
- Run `flutter pub run build_runner build` in the terminal to autogenerate some relevant files
- Run `flutter doctor` to check if everything works as expected

You should now be able to run the example in your IDE (refer to <https://flutter.dev/docs/get-started/editor> for
instructions on code editor setup).

A few resources to get you started:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)
- [Online Documentation](https://flutter.dev/docs)

## Development

Read this section, if you want to contribute to the project.

### Workflow

1. Select a JIRA issue to work on.
2. Create a feature branch for the issue, named _OPTM-XY_Meaningful-Branch-Name_
3. Write your code and add tests for it
4. Format your files (`flutter run format <filenames>` or `dart run format <filenames>`)
5. Run all tests (`flutter test`) and make sure they complete without errors or warnings
6. [Run code metrics](#run-code-metrics-locally) (`flutter pub run dart_code_metrics:metrics lib`) and fix warnings related to your changes
7. Write a descriptive commit message and commit your changes (use the
   [JIRA Smart Commit syntax](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/)
   to reference the issue)
8. Push your changes and create a pull request into main when you are done.

### CI Pipeline

The Continuous Integration (CI) Pipeline runs whenever you push your changes to the repository.
With each Pull Request the following happens:

- Files are checked to be formatted as `flutter format` would do
- Tests are executed and checked for errors
- Metrics are created (warnings added to the respective lines)
- Codecov report is created (used as an indicator on code quality)

Find all the commands run on CI in `.github/workflows/main.yaml`.

### Directory Structure
```
root
// Contains the application code
|-lib
// Data classes
|--models
// A screen contains the whole window or can be viewed at different routes
// Ususally, the top level widget of every screen is the Scaffold
|--screens
// Classes responsible for state management and business logic
|--services
// Utility classes and functions belong here (similar to other programming languages)
|--utils
// Widgets are UI components, all shared widgets belong here
|--widgets
// Unit- and Integration-Tests
|--test
```

## Tips & Tricks

### Flutter format as a file watcher

You can create a file watcher to automatically format your files on save.

In Android Studio / IntelliJ:

> Install the Dart plugin (see Editor setup) to get automatic formatting of code in Android Studio and IntelliJ.
> To automatically format your code in the current source code window, use Cmd+Alt+L (on Mac) or
> Ctrl+Alt+L (on Windows and Linux). Android Studio and IntelliJ also provides a check box named Format code
> on save on the Flutter page in Preferences (on Mac) or Settings (on Windows and Linux) which will format the
> current file automatically when you save it.

In Visual Studio Code:

> Install the Flutter extension (see [Editor setup](https://flutter.dev/docs/get-started/editor)) to get automatic formatting of code in VS Code.
>
> To automatically format the code in the current source code window, right-click in the code window and
> select Format Document. You can add a keyboard shortcut to this VS Code Preferences.
>
> To automatically format code whenever you save a file, set the _editor.formatOnSave_ setting to true.

## Run code metrics locally

Run the following command to create code metrics for the `lib` directory (or the `lib` and the `test` directory, respectively):

```sh
flutter pub run dart_code_metrics:metrics lib
flutter pub run dart_code_metrics:metrics lib test
```
    

Add `-r console-verbose` for more information e.g. on the cyclomatic complexity (lower is better) and maintainability
(higher is better).

Add `-r html` to create an HTML report.

