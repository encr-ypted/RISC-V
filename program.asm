1. ADDI x1, x0, 5    // Load 5 into register 1
2. ADDI x2, x0, 7    // Load 7 into register 2
3. ADD  x3, x1, x2   // Add x1 + x2, store result (12) in x3. (TESTS EX-TO-EX FORWARDING)
4. SW   x3, 0(x0)    // Store the value of x3 (12) into memory at address 0
5. LW   x4, 0(x0)    // Load the value from memory address 0 into x4
6. ADD  x5, x4, x1   // Add x4 + x1, store result (17) in x5. (TESTS LOAD-USE STALL & FORWARDING)
7. JAL  x0, 0        // Infinite loop (Jumps to itself to "stop" the CPU)