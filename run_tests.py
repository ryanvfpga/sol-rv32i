import os
import sys
import glob
import subprocess

BUILD_DIR = "build"
SRC_DIR = "rtl"
TB_DIR = "tb"

os.makedirs(BUILD_DIR, exist_ok=True)

src_files = glob.glob(f"{SRC_DIR}/*.v")

# Deduplicate testbench files in case of overlapping glob matches
tb_files = list(set(glob.glob(f"{TB_DIR}/*.v") + glob.glob(f"{TB_DIR}/**/*.v", recursive=True)))

if not tb_files:
    print("No testbench files found in tb/")
    sys.exit(1)

print("==========================================")
print(" Running all testbenches with iverilog... ")
print("==========================================")

failed_tests = []

for tb in tb_files:
    tb_name = os.path.splitext(os.path.basename(tb))[0]
    vvp_file = os.path.join(BUILD_DIR, f"{tb_name}.vvp")
    
    print("\n------------------------------------------")
    print(f"Testing: {tb_name}")
    print("------------------------------------------")

    # 1. Compile
    compile_cmd = ["iverilog", "-g2012", "-I", SRC_DIR, "-o", vvp_file] + src_files + [tb]
    compile_res = subprocess.run(compile_cmd, capture_output=True, text=True)
    
    if compile_res.returncode != 0:
        print(compile_res.stderr)
        print(f"Compilation failed for {tb_name}")
        failed_tests.append(tb_name)
        continue

    # 2. Run simulation and capture output
    run_res = subprocess.run(["vvp", vvp_file], capture_output=True, text=True)
    
    # Print the simulation output to console
    print(run_res.stdout, end="")

    # Check for execution failure or 'FAIL' in the output string
    if run_res.returncode != 0 or "FAIL" in run_res.stdout:
        failed_tests.append(tb_name)

print("\n==========================================")
if failed_tests:
    print(f"   TEST SUITE FAILED! Failed testbenches: {', '.join(failed_tests)}")
    print("==========================================")
    sys.exit(1)
else:
    print("   All Testbenches Passed Successfully!   ")
    print("==========================================")