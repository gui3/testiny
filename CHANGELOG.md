# Testiny changelog


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [0.2.0] - 2026-09-08

### Fixed

- fixed non blocking error messages
  (duplicate calls to add_child)

## [0.2.0] - 2026-09-08

### Added

- filtering the test cases executed
- excluding paths from the test suite discovery
- running a single test case or suite from the tree

### Fixed

- fixed OS crash (on linux KDE Neon) when closing:
  sub_process now quits gracefully before the plugin closes.
  (was due to a duplicate kill call on the sub process)
- fixed wrong icons for CANCELLED and IGNORED statuses

### Changed

- app version displayed on the ui is now injected from app_info.gd

## [0.1.11] - 2023-09-07

### Added

- the whole plugin almost functionnal

## ... More

[@gui3]: https://github.com/gui3

