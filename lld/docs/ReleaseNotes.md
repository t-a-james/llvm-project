<!-- If you want to modify sections/contents permanently, you should modify both
ReleaseNotes.md and ReleaseNotesTemplate.txt. -->

(lld-release-release-notes)=

# lld {{ release | default("") }} Release Notes

```{contents}
:local: true
```

::::{only} PreRelease

:::{warning}
These are in-progress notes for the upcoming LLVM {{ release | default("") }} release.
Release notes for previous releases can be found on
[the Download Page](https://releases.llvm.org/download.html).
:::
::::

## Introduction

This document contains the release notes for the lld linker, release {{ release | default("") }}.
Here we describe the status of lld, including major improvements
from the previous release. All lld releases may be downloaded
from the [LLVM releases web site](https://llvm.org/releases/).

## Non-comprehensive list of changes in this release

### ELF Improvements

* `--as-needed-diagnostics` has been added. When used with `--as-needed`, it
  warns about each shared library that was linked against but whose `DT_NEEDED`
  entry was dropped because no symbol from it was used. If the library is a
  `DT_NEEDED` dependency of another library that is needed, the report also
  lists those libraries, since the link is likely a transitive one introduced by
  the build system.
* `--as-needed-diagnostics-exclude=<glob>` has been added to suppress
  `--as-needed-diagnostics` reports for libraries whose soname or file name
  matches `<glob>`. It may be specified multiple times.

### Breaking changes

### COFF Improvements

### MinGW Improvements

### MachO Improvements

* `__objc_stubs` entries are now ordered by the priority of the sections that
  call them, so that stubs reached from prioritized code are laid out together.
  This applies whenever section priorities exist, such as with `-order_file`.

* Added `--warn-missing-subsections-via-symbols` and
  `--no-warn-missing-subsections-via-symbols` to lld to warn when input object
  files lack the `MH_SUBSECTIONS_VIA_SYMBOLS` flag, which prevents
  dead-stripping and subsection splitting.

### WebAssembly Improvements

* Added support for resolving and merging common data symbols (allocating them
  into .bss.common in executable/shared module links, or merging them with max
  size/alignment in relocatable -r links). See
  https://github.com/WebAssembly/tool-conventions/pull/267

#### Fixes
