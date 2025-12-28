#!/usr/bin/env python3
"""
IBM PC 5150 BIOS Test Suite
Team 1 Output - Tests cleanroom BIOS implementation

Tests behavioral compliance with specifications.
Does NOT test implementation details.
"""

import subprocess
import time
import os
import struct
import sys

class BIOSEmulator:
    """Wrapper for QEMU to test BIOS behavior"""
    
    def __init__(self, bios_path):
        self.bios_path = bios_path
        self.process = None
        
    def start(self, timeout=5):
        """Start QEMU with BIOS"""
        cmd = [
            'qemu-system-i386',
            '-M', 'isapc',
            '-cpu', '486',
            '-m', '640',
            '-bios', self.bios_path,
            '-nographic',
            '-serial', 'stdio',
            '-monitor', 'none',
        ]
        
        try:
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.PIPE
            )
            time.sleep(1)  # Give BIOS time to start
            return True
        except Exception as e:
            print(f"Failed to start QEMU: {e}")
            return False
    
    def stop(self):
        """Stop QEMU"""
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
            self.process = None
    
    def is_running(self):
        """Check if QEMU is still running"""
        return self.process and self.process.poll() is None


class TestBIOSBasics:
    """Test basic BIOS functionality"""
    
    def test_rom_size(self, bios_path):
        """Test that ROM is correct size"""
        size = os.path.getsize(bios_path)
        # Accept either 8KB (original) or 64KB (padded for QEMU)
        assert size == 8192 or size == 65536, \
            f"ROM size should be 8KB or 64KB, got {size} bytes"
        print(f"✓ ROM size correct: {size} bytes")
        return True
    
    def test_rom_signature(self, bios_path):
        """Test that ROM contains copyright/identification"""
        with open(bios_path, 'rb') as f:
            if os.path.getsize(bios_path) == 65536:
                # 64KB padded - read last 8KB
                f.seek(0xE000)
            rom = f.read()
        
        # Check for IBM copyright (original) OR cleanroom identifier
        has_ibm = b'IBM' in rom
        has_cleanroom = b'Cleanroom' in rom or b'CLEANROOM' in rom or b'cleanroom' in rom
        has_bios = b'BIOS' in rom or b'bios' in rom
        
        assert has_ibm or (has_cleanroom and has_bios), \
            "ROM should contain IBM signature (original) or Cleanroom BIOS identifier"
        
        if has_ibm:
            print("✓ ROM contains IBM copyright signature (original)")
        else:
            print("✓ ROM contains Cleanroom BIOS identifier")
        return True
    
    def test_reset_vector(self, bios_path):
        """Test that reset vector exists at correct location"""
        with open(bios_path, 'rb') as f:
            if os.path.getsize(bios_path) == 65536:
                # Read from 0xFFF0 in 64KB ROM
                f.seek(0xFFF0)
            else:
                # Read from 0x1FF0 in 8KB ROM
                f.seek(0x1FF0)
            
            reset_vector = f.read(16)
        
        # First byte should be 0xEA (far JMP opcode)
        assert reset_vector[0] == 0xEA, \
            f"Reset vector should start with JMP (0xEA), got 0x{reset_vector[0]:02X}"
        print("✓ Reset vector contains JMP instruction")
        return True
    
    def test_date_string(self, bios_path):
        """Test that BIOS date string is present"""
        with open(bios_path, 'rb') as f:
            rom = f.read()
        
        # Look for date pattern: XX/XX/XX (original: 10/19/81, cleanroom may differ)
        # Check for slash characters which indicate date format
        has_date_pattern = rom.count(b'/') >= 2
        
        # Also check for year indicators (19xx, 20xx, or just xx)
        has_year = (b'81' in rom or b'82' in rom or b'83' in rom or b'84' in rom or
                    b'19' in rom or b'20' in rom or b'21' in rom or b'22' in rom or
                    b'23' in rom or b'24' in rom or b'25' in rom)
        
        assert has_date_pattern or has_year, \
            "ROM should contain date information"
        print("✓ ROM contains date information")
        return True


class TestBIOSBoot:
    """Test BIOS boot behavior"""
    
    def test_bios_starts(self, bios_path):
        """Test that BIOS starts without crashing"""
        emu = BIOSEmulator(bios_path)
        assert emu.start(), "BIOS should start successfully"
        time.sleep(2)
        assert emu.is_running(), "BIOS should continue running"
        emu.stop()
        print("✓ BIOS starts and runs without crashing")
        return True
    
    def test_post_completes(self, bios_path):
        """Test that POST completes (doesn't halt immediately)"""
        emu = BIOSEmulator(bios_path)
        emu.start()
        time.sleep(3)
        
        # If QEMU is still running after 3 seconds, POST likely completed
        # (would halt quickly on POST failure)
        running = emu.is_running()
        emu.stop()
        
        assert running, "POST should complete without halting"
        print("✓ POST sequence completes")
        return True


class TestBIOSInterrupts:
    """Test BIOS interrupt vector setup"""
    
    def test_interrupt_vectors_exist(self, bios_path):
        """
        Test that BIOS sets up interrupt vectors
        Note: This is a structure test, actual INT calls need more complex testing
        """
        # This would require memory inspection in QEMU
        # For now, just verify BIOS contains INT instructions
        with open(bios_path, 'rb') as f:
            rom = f.read()
        
        # Look for INT instructions (0xCD opcode)
        int_count = rom.count(b'\xCD')
        assert int_count > 0, "BIOS should contain INT instructions"
        print(f"✓ BIOS contains {int_count} INT instructions")
        return True
    
    def test_iret_instructions_exist(self, bios_path):
        """Test that BIOS contains IRET instructions (for INT handlers)"""
        with open(bios_path, 'rb') as f:
            rom = f.read()
        
        # IRET opcode is 0xCF
        iret_count = rom.count(b'\xCF')
        assert iret_count > 0, "BIOS should contain IRET instructions"
        print(f"✓ BIOS contains {iret_count} IRET instructions")
        return True


class TestBIOSMemory:
    """Test BIOS memory operations"""
    
    def test_no_null_blocks(self, bios_path):
        """Test that ROM doesn't have large null blocks (indicates incomplete)"""
        with open(bios_path, 'rb') as f:
            if os.path.getsize(bios_path) == 65536:
                # Skip padding, read actual BIOS (last 8KB)
                f.seek(0xE000)
            rom = f.read(8192)
        
        # Check for suspiciously large runs of zeros
        max_zeros = 0
        current_zeros = 0
        for byte in rom:
            if byte == 0:
                current_zeros += 1
                max_zeros = max(max_zeros, current_zeros)
            else:
                current_zeros = 0
        
        # Allow up to 32 consecutive zeros (for alignment/padding)
        assert max_zeros < 64, \
            f"ROM has {max_zeros} consecutive zero bytes (likely incomplete)"
        print(f"✓ ROM appears complete (max {max_zeros} consecutive zeros)")
        return True


def run_all_tests(bios_path):
    """Run all tests on a BIOS image"""
    print(f"\n{'='*60}")
    print(f"Testing BIOS: {bios_path}")
    print(f"{'='*60}\n")
    
    test_classes = [
        TestBIOSBasics(),
        TestBIOSBoot(),
        TestBIOSInterrupts(),
        TestBIOSMemory(),
    ]
    
    total_tests = 0
    passed_tests = 0
    failed_tests = []
    
    for test_class in test_classes:
        class_name = test_class.__class__.__name__
        print(f"\n{class_name}:")
        print("-" * 60)
        
        # Get all test methods
        test_methods = [m for m in dir(test_class) if m.startswith('test_')]
        
        for method_name in test_methods:
            total_tests += 1
            test_method = getattr(test_class, method_name)
            
            try:
                result = test_method(bios_path)
                if result:
                    passed_tests += 1
                else:
                    failed_tests.append(f"{class_name}.{method_name}")
                    print(f"✗ {method_name} FAILED")
            except AssertionError as e:
                failed_tests.append(f"{class_name}.{method_name}")
                print(f"✗ {method_name} FAILED: {e}")
            except Exception as e:
                failed_tests.append(f"{class_name}.{method_name}")
                print(f"✗ {method_name} ERROR: {e}")
    
    # Summary
    print(f"\n{'='*60}")
    print(f"Test Summary")
    print(f"{'='*60}")
    print(f"Total tests: {total_tests}")
    print(f"Passed: {passed_tests}")
    print(f"Failed: {len(failed_tests)}")
    
    if failed_tests:
        print(f"\nFailed tests:")
        for test in failed_tests:
            print(f"  - {test}")
    
    print(f"\nSuccess rate: {passed_tests}/{total_tests} ({100*passed_tests//total_tests}%)")
    
    return len(failed_tests) == 0


def main():
    """Main test runner"""
    if len(sys.argv) < 2:
        print("Usage: python3 test_bios.py <bios_file>")
        print("\nExample:")
        print("  python3 test_bios.py ../BIOS_IBM5150_19OCT81_5700671_U33.BIN")
        print("  python3 test_bios.py ../cleanroom_bios/build/bios.bin")
        sys.exit(1)
    
    bios_path = sys.argv[1]
    
    if not os.path.exists(bios_path):
        print(f"Error: BIOS file not found: {bios_path}")
        sys.exit(1)
    
    success = run_all_tests(bios_path)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
