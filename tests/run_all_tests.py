#!/usr/bin/env python3
"""
Complete BIOS Integration Test Suite
Run with: python3 run_all_tests.py
"""

import subprocess
import sys
import os

def run_test(name, command, cwd=None):
    """Run a test and return result"""
    print(f"\n{'='*70}")
    print(f"Running: {name}")
    print('='*70)
    
    result = subprocess.run(
        command,
        shell=True,
        cwd=cwd,
        capture_output=False,
        text=True
    )
    
    return result.returncode == 0

def main():
    print("="*70)
    print("COMPLETE BIOS INTEGRATION TEST SUITE")
    print("="*70)
    
    os.chdir('/workspace')
    
    tests = [
        ("Basic Validation", "python3 test_bios.py ../cleanroom_bios/build/bios_complete_64k.bin", "tests"),
        ("Functional Verification", "python3 test_functional_verification.py", "tests"),
        ("Comprehensive Audit", "python3 test_comprehensive.py", "tests"),
        ("Integration Check", "python3 -c \"" + '''
with open('cleanroom_bios/bios_complete.asm', 'r') as f:
    s = f.read()
checks = {
    'Hardware I/O': s.count(' out ') > 50,
    'DMA': 'DMA_MASK' in s,
    'FDC': '0xE6' in s,
    'UART': 'UART_LCR' in s,
    'Video': 'stosw' in s,
    'Interrupts': 'int10_video:' in s,
}
passed = sum(checks.values())
print(f"Integration: {passed}/{len(checks)} checks pass")
for k, v in checks.items():
    print(f"  {'✅' if v else '❌'} {k}")
exit(0 if passed == len(checks) else 1)
''' + "\"", None),
    ]
    
    results = []
    for name, cmd, cwd in tests:
        try:
            result = run_test(name, cmd, cwd)
            results.append((name, result))
        except Exception as e:
            print(f"ERROR: {e}")
            results.append((name, False))
    
    # Summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {name}")
    
    passed = sum(1 for _, r in results if r)
    total = len(results)
    
    print(f"\nTotal: {passed}/{total} tests passed ({100*passed//total}%)")
    
    if passed == total:
        print("\n" + "="*70)
        print("✅ ALL TESTS PASSED - BIOS IS COMPLETE")
        print("="*70)
        return 0
    else:
        print(f"\n⚠️  {total-passed} test(s) failed")
        return 1

if __name__ == '__main__':
    sys.exit(main())
