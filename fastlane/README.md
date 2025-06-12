fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### test

```sh
[bundle exec] fastlane test
```

Executes SDK Unit Tests

### contract_test

```sh
[bundle exec] fastlane contract_test
```

Executes Acceptance Tests

### integration_test

```sh
[bundle exec] fastlane integration_test
```

Executes Integration Tests

### lint_cocoapods

```sh
[bundle exec] fastlane lint_cocoapods
```

Lints a release using Cocoapods

### lint_swift_package_manager

```sh
[bundle exec] fastlane lint_swift_package_manager
```

Lints a release using Swift Package Manager

### build_example

```sh
[bundle exec] fastlane build_example
```

Builds SDK example applications

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
