#!/usr/bin/env python3
"""
run_tests.py — unified test runner.

  python run_tests.py          # run everything (RTL unit, C programs, riscv-tests ISA)
  python run_tests.py -v       # RTL unit tests only (tb/*.v testbenches)
  python run_tests.py -c       # C program tests only (tests/programs/*.c via tb/tb_top.v)
  python run_tests.py -i       # riscv-tests rv32ui ISA tests only (via tb/tb_top.v)
  python run_tests.py -i -t add,lw   # only the named ISA tests
  Flags combine: -v -c runs those two suites, etc.
"""

import os
import re
import sys
import glob
import shutil
import argparse
import subprocess

GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"

ROOT = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(ROOT, "build")
RTL_DIR = os.path.join(ROOT, "rtl")
TB_DIR = os.path.join(ROOT, "tb")
TB_TOP = os.path.join(TB_DIR, "tb_top.v")

SW_DIR = os.path.join(ROOT, "tests")
LINK_SCRIPT = os.path.join(SW_DIR, "link.ld")
START_S = os.path.join(SW_DIR, "start.S")
PROGRAMS_DIR = os.path.join(SW_DIR, "programs")
PREBUILT_DIR = os.path.join(SW_DIR, "prebuilt")

# riscv-tests: `git submodule add https://github.com/riscv-software-src/riscv-tests tests/riscv-tests`
RISCV_TESTS = os.path.join(SW_DIR, "riscv-tests")
ISA_SRC_DIR = os.path.join(RISCV_TESTS, "isa", "rv32ui")
ISA_MACROS = os.path.join(RISCV_TESTS, "isa", "macros", "scalar")
ISA_ENV = os.path.join(SW_DIR, "isa_env")
ISA_PREBUILT_DIR = os.path.join(PREBUILT_DIR, "isa")

# rv32ui tests this core cannot run:
ISA_SKIP = {"fence_i", "ma_data"}

ISA_CFLAGS = [
    "-march=rv32i", "-mabi=ilp32", "-mno-relax",
    "-nostdlib", "-nostartfiles", "-static",
    "-Wl,--no-warn-rwx-segments", "-Wl,--no-check-sections",
]

# Word-addressed, 32-bit-wide memory: 1024 deep on each side.
DATA_WIDTH_BYTES = 4

# Bare-metal RV32I flags. -mno-relax avoids gp-relative relaxation since
# start.S never initializes gp. -nostdlib/-ffreestanding/-fno-builtin keep
# libc and unsupported instruction selection out; -lgcc is re-linked
# explicitly below since -nostdlib drops it too, and software mul/div
# (__mulsi3 etc.) still needs it on a plain rv32i target.
CFLAGS = [
    "-march=rv32i",
    "-mabi=ilp32",
    "-O1",
    "-mno-relax",
    "-nostdlib",
    "-ffreestanding",
    "-fno-builtin",
    "-static",
    "-Wl,--no-warn-rwx-segments",
    "-msmall-data-limit=0",
    "-Wl,--no-check-sections",
]

TOOLCHAIN_CANDIDATES = [
    "riscv32-unknown-elf",
    "riscv64-unknown-elf",
    "riscv-none-elf",
]

STAT_RE = re.compile(r"^(CYCLES|INSTRET|CPI|IPC|BRANCHES|MISPREDICTS|BP_ACCURACY):\s*(\S+)")

SUMMARY_COLS = [
    ("CYCLES", "Cycles"),
    ("INSTRET", "Instrs"),
    ("CPI", "CPI"),
    ("IPC", "IPC"),
    ("BRANCHES", "Branches"),
    ("MISPREDICTS", "Mispred"),
    ("BP_ACCURACY", "BP acc"),
]


# --------------------------------------------------------------------------
# RTL unit tests (-v)
# --------------------------------------------------------------------------

def run_verilog_tests():
    os.makedirs(BUILD_DIR, exist_ok=True)

    src_files = glob.glob(f"{RTL_DIR}/*.v")
    tb_files = sorted(set(glob.glob(f"{TB_DIR}/*.v") + glob.glob(f"{TB_DIR}/**/*.v", recursive=True)))
    # tb_top.v is the harness used by -c to run C programs, not a
    # standalone unit test (it expects +IMEM_HEX/+DMEM_HEX plusargs).
    tb_files = [tb for tb in tb_files if os.path.abspath(tb) != os.path.abspath(TB_TOP)]

    if not tb_files:
        print(f"No testbench files found in {TB_DIR}/")
        return 0, []

    print("Unit Tests")
    print("=" * 60)

    failed = []

    for tb in tb_files:
        tb_name = os.path.splitext(os.path.basename(tb))[0]
        vvp_file = os.path.join(BUILD_DIR, f"{tb_name}.vvp")

        compile_cmd = ["iverilog", "-g2012", "-I", RTL_DIR, "-o", vvp_file] + src_files + [tb]
        compile_res = subprocess.run(compile_cmd, capture_output=True, text=True)

        if compile_res.returncode != 0:
            print(f"{tb_name}: {RED}FAIL{RESET} (Compilation Error)")
            if compile_res.stderr.strip():
                print(compile_res.stderr.strip())
            failed.append(tb_name)
            print("-" * 60)
            continue

        run_res = subprocess.run(["vvp", vvp_file], capture_output=True, text=True)

        if run_res.returncode != 0 or "FAIL" in run_res.stdout or "PASS" not in run_res.stdout:
            print(f"{tb_name}: {RED}FAIL{RESET}")
            if run_res.stdout.strip():
                print(run_res.stdout.strip())
            if run_res.stderr.strip():
                print(run_res.stderr.strip())
            failed.append(tb_name)
        else:
            print(f"{tb_name}: {GREEN}PASS{RESET}")

        print("-" * 60)

    return len(tb_files), failed


# --------------------------------------------------------------------------
# C program tests (-c)
# --------------------------------------------------------------------------

def find_toolchain():
    env_prefix = os.environ.get("TOOLCHAIN_PREFIX")
    candidates = [env_prefix] if env_prefix else TOOLCHAIN_CANDIDATES
    for prefix in candidates:
        if prefix and shutil.which(f"{prefix}-gcc"):
            return prefix
    print(f"{RED}FAIL{RESET}: no RISC-V toolchain found "
          f"(tried: {', '.join(c for c in candidates if c)}).")
    print("Set TOOLCHAIN_PREFIX=<prefix> if yours is named differently "
          "(e.g. TOOLCHAIN_PREFIX=riscv64-unknown-elf).")
    return None


def compile_program(prefix, c_file, elf_out):
    gcc = f"{prefix}-gcc"
    # -lgcc must come after the sources: -nostdlib drops all default libs
    # (including libgcc), but rv32i has no hardware mul/div, so compiler
    # calls like __mulsi3/__divsi3/__modsi3 still need libgcc re-linked in.
    cmd = [gcc, *CFLAGS, "-T", LINK_SCRIPT, START_S, c_file, "-lgcc", "-o", elf_out]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        return False, res.stderr
    return True, None


def split_hex(prefix, elf_file, instr_hex, data_hex):
    objcopy = f"{prefix}-objcopy"

    cmd_i = [objcopy, "-O", "verilog",
              f"--verilog-data-width={DATA_WIDTH_BYTES}",
              "--only-section=.text*",
              elf_file, instr_hex]
    res_i = subprocess.run(cmd_i, capture_output=True, text=True)
    if res_i.returncode != 0:
        return False, res_i.stderr

    cmd_d = [objcopy, "-O", "verilog",
              f"--verilog-data-width={DATA_WIDTH_BYTES}",
              "--only-section=.rodata*", "--only-section=.data*",
              elf_file, data_hex]
    res_d = subprocess.run(cmd_d, capture_output=True, text=True)
    if res_d.returncode != 0:
        if "Nothing to output" not in (res_d.stderr or "") and \
           "warning" not in (res_d.stderr or "").lower():
            return False, res_d.stderr
        open(data_hex, "w").close()

    return True, None


def build_c_simulator():
    os.makedirs(BUILD_DIR, exist_ok=True)
    vvp_file = os.path.join(BUILD_DIR, "tb_top.vvp")
    src_files = glob.glob(f"{RTL_DIR}/*.v")
    cmd = ["iverilog", "-g2012", "-I", RTL_DIR, "-o", vvp_file] + src_files + [TB_TOP]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"{RED}FAIL{RESET}: could not compile {TB_TOP}")
        if res.stderr.strip():
            print(res.stderr.strip())
        return None
    return vvp_file


def run_c_program(vvp_file, instr_hex, data_hex):
    cmd = ["vvp", vvp_file, f"+IMEM_HEX={instr_hex}", f"+DMEM_HEX={data_hex}"]
    return subprocess.run(cmd, capture_output=True, text=True)


def compile_isa_test(prefix, s_file, elf_out):
    # No start.S (the test brings its own _start via RVTEST_CODE_BEGIN), no libgcc.
    cmd = [f"{prefix}-gcc", *ISA_CFLAGS, "-I", ISA_ENV, "-I", ISA_MACROS,
           "-T", LINK_SCRIPT, s_file, "-o", elf_out]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return (res.returncode == 0), (res.stderr if res.returncode else None)


def print_summary(results):
    if not results:
        return
    print()
    print("Summary")
    print("=" * 90)
    print(f"{'program':<20}" + "".join(f"{title:>10}" for _, title in SUMMARY_COLS))
    for name, stats in results:
        print(f"{name:<20}" + "".join(f"{stats.get(key, '-'):>10}" for key, _ in SUMMARY_COLS))
    print("=" * 90)


def run_c_tests():
    if not os.path.isfile(TB_TOP):
        print(f"No top-level testbench found at {TB_TOP}")
        return 0, []

    c_files = sorted(glob.glob(os.path.join(PROGRAMS_DIR, "*.c")))
    if not c_files:
        print(f"No C programs found in {PROGRAMS_DIR}/")
        return 0, []

    prefix = find_toolchain()
    if prefix is None:
        return 0, ["<toolchain missing>"]

    vvp_file = build_c_simulator()
    if vvp_file is None:
        return 0, ["<tb_top.v compile error>"]

    os.makedirs(PREBUILT_DIR, exist_ok=True)

    print("C Program Tests")
    print("=" * 60)

    failed = []
    results = []

    for c_file in c_files:
        name = os.path.splitext(os.path.basename(c_file))[0]
        elf_out = os.path.join(PREBUILT_DIR, f"{name}.elf")
        instr_hex = os.path.join(PREBUILT_DIR, f"{name}_instrmem.hex")
        data_hex = os.path.join(PREBUILT_DIR, f"{name}_datamem.hex")

        ok, err = compile_program(prefix, c_file, elf_out)
        if not ok:
            print(f"{name}: {RED}FAIL{RESET} (compile error)")
            if err and err.strip():
                print(err.strip())
            failed.append(name)
            print("-" * 60)
            continue

        ok, err = split_hex(prefix, elf_out, instr_hex, data_hex)
        if not ok:
            print(f"{name}: {RED}FAIL{RESET} (objcopy error)")
            if err and err.strip():
                print(err.strip())
            failed.append(name)
            print("-" * 60)
            continue

        res = run_c_program(vvp_file, instr_hex, data_hex)
        stdout = res.stdout or ""

        if res.returncode != 0 or "FAIL" in stdout or "PASS" not in stdout:
            print(f"{name}: {RED}FAIL{RESET}")
            if stdout.strip():
                print(stdout.strip())
            if res.stderr and res.stderr.strip():
                print(res.stderr.strip())
            failed.append(name)
        else:
            print(f"{name}: {GREEN}PASS{RESET}")
            stats = {}
            for line in stdout.splitlines():
                m = STAT_RE.match(line.strip())
                if m:
                    stats[m.group(1)] = m.group(2)
                    print(f"  -> {line.strip()}")
            results.append((name, stats))

        print("-" * 60)

    print_summary(results)

    return len(c_files), failed


def run_isa_tests(only=None):
    if not os.path.isfile(TB_TOP):
        print(f"No top-level testbench found at {TB_TOP}")
        return 0, []
    if not os.path.isdir(ISA_SRC_DIR):
        print(f"{RED}FAIL{RESET}: riscv-tests not found at {RISCV_TESTS} "
              f"(git submodule add https://github.com/riscv-software-src/riscv-tests {os.path.relpath(RISCV_TESTS, ROOT)})")
        return 0, ["<riscv-tests missing>"]

    s_files = sorted(glob.glob(os.path.join(ISA_SRC_DIR, "*.S")))
    s_files = [f for f in s_files if os.path.splitext(os.path.basename(f))[0] not in ISA_SKIP]
    if only:
        s_files = [f for f in s_files if os.path.splitext(os.path.basename(f))[0] in only]
    if not s_files:
        print("No matching ISA tests.")
        return 0, []

    prefix = find_toolchain()
    if prefix is None:
        return 0, ["<toolchain missing>"]
    vvp_file = build_c_simulator()
    if vvp_file is None:
        return 0, ["<tb_top.v compile error>"]

    os.makedirs(ISA_PREBUILT_DIR, exist_ok=True)

    print("riscv-tests (rv32ui)")
    print("=" * 60)

    failed = []
    for s_file in s_files:
        name = os.path.splitext(os.path.basename(s_file))[0]
        elf_out = os.path.join(ISA_PREBUILT_DIR, f"{name}.elf")
        instr_hex = os.path.join(ISA_PREBUILT_DIR, f"{name}_instrmem.hex")
        data_hex = os.path.join(ISA_PREBUILT_DIR, f"{name}_datamem.hex")

        ok, err = compile_isa_test(prefix, s_file, elf_out)
        if ok:
            ok, err = split_hex(prefix, elf_out, instr_hex, data_hex)
        if not ok:
            print(f"rv32ui-{name}: {RED}FAIL{RESET} (build error)")
            if err and err.strip():
                print(err.strip())
            failed.append(f"rv32ui-{name}")
            continue

        res = run_c_program(vvp_file, instr_hex, data_hex)
        stdout = res.stdout or ""
        if res.returncode != 0 or "FAIL" in stdout or "PASS" not in stdout:
            print(f"rv32ui-{name}: {RED}FAIL{RESET}")
            for line in stdout.splitlines():
                if line.startswith("FAIL"):
                    print(f"  {line}")
            if res.stderr and res.stderr.strip():
                print(res.stderr.strip())
            failed.append(f"rv32ui-{name}")
        else:
            print(f"rv32ui-{name}: {GREEN}PASS{RESET}")

    print("-" * 60)
    return len(s_files), failed


# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Run RTL unit tests and/or C program tests.")
    parser.add_argument("-v", "--verilog", action="store_true", help="run RTL unit tests only")
    parser.add_argument("-c", "--c", action="store_true", help="run C program tests only")
    parser.add_argument("-i", "--isa", action="store_true", help="run riscv-tests rv32ui ISA tests only")
    parser.add_argument("-t", "--tests", default="", help="comma-separated ISA test names (with -i), e.g. add,lw")
    args = parser.parse_args()

    # No flags => run every suite. Otherwise run exactly the suites selected.
    any_flag = args.verilog or args.c or args.isa
    run_v = args.verilog or not any_flag
    run_c_flag = args.c or not any_flag
    run_i = args.isa or not any_flag

    all_failed = []
    total_run = 0

    if run_v:
        total, failed = run_verilog_tests()
        total_run += total
        all_failed += failed

    if run_v and run_c_flag:
        print()  # separate the suites' output

    if run_c_flag:
        total, failed = run_c_tests()
        total_run += total
        all_failed += failed

    if run_i:
        if run_v or run_c_flag:
            print()
        only = {t.strip() for t in args.tests.split(",") if t.strip()} or None
        total, failed = run_isa_tests(only)
        total_run += total
        all_failed += failed

    print()
    print("=" * 60)
    passed_count = total_run - len(all_failed)
    if all_failed:
        print(f"{RED}{len(all_failed)}/{total_run} failed{RESET}: {', '.join(all_failed)}")
    else:
        print(f"{GREEN}All {total_run} test(s) passed{RESET}")

    if all_failed:
        sys.exit(1)


if __name__ == "__main__":
    main()