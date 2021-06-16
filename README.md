# P2P Task Manager

A privacy-aware task manager. No account needed, all your tasks get synced using the local network only. 

## Getting Started

Follow the instruction on https://flutter.dev/docs/get-started/install

Follow the instructions on https://flutter.dev/docs/get-started/editor

Run `flutter pub get` in the terminal to load all dependencies

Run `flutter pub run build_runner build` in the terminal to autogenerate some relevant files

Check with the command `flutter doctor` if everything works as expected

You should now be able to run the example in your IDE

A few resources to get you started:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)
- [Online Documentation](https://flutter.dev/docs)

# Development

Read this section, if you want to contribute to the project.

## Workflow

1. Select a JIRA issue to work on.
2. Create a feature branch for the issue, named _OPTM-XY_Meaninful-Branch-Name_)
3. Write your code and add tests for it
4. Format your files (`flutter run format <filenames>` or `dart run format <filenames>`)
5. Run all tests (`flutter test`) and make sure they complete without errors or warnings
6. Write a descriptive commit message and commit your changes (use the [JIRA Smart Commit syntax](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/) to reference the issue)
7. Push your changes and create a pull request into main when you are done.

## CI Pipeline

The Continuous Integration (CI) Pipeline runs whenever you push your changes to the repository.
Every file gets checked for proper formatting. Also, all tests get executed.

You can find all the commands run on CI in `.github/workflows/main.yaml`.

## Directory Structure
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
To automatically format your code in the current source code window, use Cmd+Alt+L (on Mac) or
Ctrl+Alt+L (on Windows and Linux). Android Studio and IntelliJ also provides a check box named Format code
on save on the Flutter page in Preferences (on Mac) or Settings (on Windows and Linux) which will format the
current file automatically when you save it.

In Visual Studio Code:

> Install the Flutter extension (see [Editor setup](https://flutter.dev/docs/get-started/editor)) to get automatic formatting of code in VS Code.
>
> To automatically format the code in the current source code window, right-click in the code window and
select Format Document. You can add a keyboard shortcut to this VS Code Preferences.
>
> To automatically format code whenever you save a file, set the _editor.formatOnSave_ setting to true.
