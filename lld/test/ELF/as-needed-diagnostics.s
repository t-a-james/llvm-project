# REQUIRES: x86
## Test --as-needed-diagnostics and --as-needed-diagnostics-exclude.

# RUN: rm -rf %t && split-file %s %t && cd %t
# RUN: llvm-mc -filetype=obj -triple=x86_64 a.s -o a.o
# RUN: llvm-mc -filetype=obj -triple=x86_64 b.s -o b.o
# RUN: llvm-mc -filetype=obj -triple=x86_64 c.s -o c.o
# RUN: llvm-mc -filetype=obj -triple=x86_64 main.s -o main.o
# RUN: ld.lld -shared a.o -soname=liba.so -o liba.so
# RUN: ld.lld -shared b.o liba.so -soname=libb.so -o libb.so
# RUN: ld.lld -shared c.o -soname=libc.so -o libc.so

## main.o only references libb.so, so liba.so and libc.so are dropped by
## --as-needed. liba.so is a DT_NEEDED entry of libb.so, so it is reported as a
## possible transitive dependency.
# RUN: ld.lld --as-needed --as-needed-diagnostics main.o libb.so liba.so libc.so \
# RUN:   -o main 2>&1 | FileCheck %s --check-prefix=DIAG --implicit-check-not=warning:

# DIAG:      warning: main links against liba.so (liba.so) but this link is not required.
# DIAG-NEXT: >>> This may be a transitive link from the build system, as the following files share this dependency: liba.so:
# DIAG-NEXT: libb.so
# DIAG:      warning: main links against libc.so (libc.so) but this link is not required.

## Nothing is reported without --as-needed-diagnostics.
# RUN: ld.lld --as-needed main.o libb.so liba.so libc.so -o main 2>&1 | count 0

## --as-needed-diagnostics-exclude= suppresses the report for one library.
# RUN: ld.lld --as-needed --as-needed-diagnostics --as-needed-diagnostics-exclude=liba.so \
# RUN:   main.o libb.so liba.so libc.so -o main 2>&1 | \
# RUN:   FileCheck %s --check-prefix=EXCLUDE --implicit-check-not=warning:

# EXCLUDE: warning: main links against libc.so (libc.so) but this link is not required.

## The option accepts glob patterns and may be specified multiple times.
# RUN: ld.lld --as-needed --as-needed-diagnostics '--as-needed-diagnostics-exclude=lib?.so' \
# RUN:   main.o libb.so liba.so libc.so -o main 2>&1 | count 0
# RUN: ld.lld --as-needed --as-needed-diagnostics --as-needed-diagnostics-exclude=liba.so \
# RUN:   --as-needed-diagnostics-exclude=libc.so main.o libb.so liba.so libc.so -o main 2>&1 | count 0

## Both options are no-ops without --as-needed.
# RUN: ld.lld --as-needed-diagnostics main.o libb.so liba.so libc.so -o main 2>&1 | \
# RUN:   FileCheck %s --check-prefix=REDUNDANT --implicit-check-not=warning:
# RUN: ld.lld --as-needed-diagnostics-exclude=liba.so main.o libb.so liba.so libc.so \
# RUN:   -o main 2>&1 | FileCheck %s --check-prefix=REDUNDANT --implicit-check-not=warning:

# REDUNDANT: warning: '--as-needed-diagnostics' and '--as-needed-diagnostics-exclude' are redundant unless '--as-needed' is specified.

## --as-needed-diagnostics-exclude= alone does nothing without --as-needed-diagnostics.
# RUN: ld.lld --as-needed --as-needed-diagnostics-exclude=liba.so main.o libb.so liba.so \
# RUN:   libc.so -o main 2>&1 | FileCheck %s --check-prefix=NO-DIAG --implicit-check-not=warning:

# NO-DIAG: warning: '--as-needed-diagnostics-exclude' specified but '--as-needed-diagnostics' not present. Nothing will be logged.

## An invalid glob pattern is an error.
# RUN: not ld.lld --as-needed --as-needed-diagnostics '--as-needed-diagnostics-exclude=[' \
# RUN:   main.o libb.so liba.so libc.so -o main 2>&1 | FileCheck %s --check-prefix=BAD-GLOB

# BAD-GLOB: error: --as-needed-diagnostics-exclude: invalid glob pattern, unmatched '[': [

#--- a.s
.globl foo
foo:
  ret

#--- b.s
.globl bar
bar:
  jmp foo@PLT

#--- c.s
.globl baz
baz:
  ret

#--- main.s
.globl _start
_start:
  call bar@PLT
