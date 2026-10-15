import os
import random
import re
import subprocess
import sys

SEEDS = sorted(random.sample(range(1, 1001), 20))
failed = []
results = []

res = subprocess.run("make compile", shell=True, capture_output=True, text=True)
if res.returncode != 0:
    print("Compilation failed!\n" + res.stderr)
    sys.exit(1)

for i, seed in enumerate(SEEDS, 1):
    cmd = f"make sim TESTNAME=apb_random_test SEED={seed}"
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    cov_m = re.search(r"FUNCTIONAL COVERAGE:([0-9.]+)%", proc.stdout)
    cov = cov_m.group(1) + "%" if cov_m else "N/A"

    log_text = proc.stdout + "\n" + proc.stderr
    has_err = re.search(r"error:|fatal:|assertion.*failed|error=[1-9]", log_text, re.IGNORECASE)
    if proc.returncode != 0 or "TEST PASSED" not in proc.stdout or has_err:
        failed.append(seed)
        results.append((i, seed, "FAIL", cov))
    else:
        results.append((i, seed, "PASS", cov))

os.makedirs("reports", exist_ok=True)
with open("reports/regression_summary.rpt", "w") as f:
    f.write(f"{'Run':<6} | {'Seed':<6} | {'Status':<6} | {'Coverage':<8}\n")
    f.write("-" * 38 + "\n")
    for r in results:
        f.write(f"{r[0]:<6} | {r[1]:<6} | {r[2]:<6} | {r[3]:<8}\n")
    f.write("-" * 38 + "\n")
    f.write(f"Result: {len(results) - len(failed)}/20 Passed, {len(failed)} Failed\n")

if not failed:
    print("Regression: 20/20 Passed")
    sys.exit(0)
else:
    print(f"Regression: {20 - len(failed)}/20 Passed ({len(failed)} FAILED)")
    for seed in failed:
        print(f"  - FAIL Seed {seed}: make sim TESTNAME=apb_random_test SEED={seed}")
    sys.exit(1)
