import os
import sys
import glob
import subprocess

BUILD_DIR = "build"
SRC_DIR = "rtl"
TB_DIR = "tb"

GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"

os.makedirs(BUILD_DIR, exist_ok=True)

src_files = glob.glob(f"{SRC_DIR}/*.v")
tb_files = sorted(list(set(glob.glob(f"{TB_DIR}/*.v") + glob.glob(f"{TB_DIR}/**/*.v", recursive=True))))

if not tb_files:
    print("No testbench files found in tb/")
    sys.exit(1)

print("Unit Tests")
print("=" * 60)

failed_tests = []

for tb in tb_files:
    tb_name = os.path.splitext(os.path.basename(tb))[0]
    vvp_file = os.path.join(BUILD_DIR, f"{tb_name}.vvp")

    compile_cmd = ["iverilog", "-g2012", "-I", SRC_DIR, "-o", vvp_file] + src_files + [tb]
    compile_res = subprocess.run(compile_cmd, capture_output=True, text=True)

    if compile_res.returncode != 0:
        print(f"{tb_name}: {RED}FAIL{RESET} (Compilation Error)")
        if compile_res.stderr.strip():
            print(compile_res.stderr.strip())
        failed_tests.append(tb_name)
        print("-" * 60)
        continue


    run_res = subprocess.run(["vvp", vvp_file], capture_output=True, text=True)

    if run_res.returncode != 0 or "FAIL" in run_res.stdout or "PASS" not in run_res.stdout:
        print(f"{tb_name}: {RED}FAIL{RESET}")
      
        if run_res.stdout.strip():
            print(run_res.stdout.strip())
        if run_res.stderr.strip():
            print(run_res.stderr.strip())
            
        failed_tests.append(tb_name)
    else:
        print(f"{tb_name}: {GREEN}PASS{RESET}")

    print("-" * 60)

if failed_tests:
    sys.exit(1)