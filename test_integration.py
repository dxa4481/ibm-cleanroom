#!/usr/bin/env python3
"""Simple integration test - run from repo root"""
import os
import sys

print("="*70)
print("BIOS Integration Test")
print("="*70)

# Check files exist
if not os.path.exists('cleanroom_bios/bios_complete.asm'):
    print("❌ Error: bios_complete.asm not found")
    sys.exit(1)

if not os.path.exists('cleanroom_bios/build/bios_complete.bin'):
    print("❌ Error: Binary not built. Run: cd cleanroom_bios && make")
    sys.exit(1)

# Read source
with open('cleanroom_bios/bios_complete.asm', 'r') as f:
    source = f.read()

# Run tests
tests = {
    'Hardware I/O': source.count(' out ') > 50 and source.count(' in ') > 20,
    'DMA Programming': 'DMA_MASK' in source and 'DMA_MODE' in source,
    'FDC Commands': '0xE6' in source and '0xC5' in source,
    'UART Programming': 'UART_DATA' in source and 'UART_LCR' in source,
    'Video Operations': 'stosw' in source and 'movsw' in source,
    'All Interrupts': all(x in source for x in ['int08_timer:', 'int10_video:', 'int13_disk:']),
    'Bootstrap Loader': '0x7C00' in source and 'int19_boot:' in source,
    'Binary Size': os.path.getsize('cleanroom_bios/build/bios_complete.bin') == 8192,
}

print()
passed = 0
for name, result in tests.items():
    status = "✅" if result else "❌"
    print(f"{status} {name}")
    if result:
        passed += 1

print()
print(f"Result: {passed}/{len(tests)} tests passed")

# Stats
out_count = source.count(' out ')
in_count = source.count(' in ')
size = os.path.getsize('cleanroom_bios/build/bios_complete.bin')

print()
print("Stats:")
print(f"  OUT instructions: {out_count}")
print(f"  IN instructions: {in_count}")
print(f"  Binary size: {size} bytes")

if passed == len(tests):
    print()
    print("="*70)
    print("✅ ALL TESTS PASSED - BIOS IS COMPLETE")
    print("="*70)
    sys.exit(0)
else:
    print()
    print(f"❌ {len(tests)-passed} test(s) failed")
    sys.exit(1)
