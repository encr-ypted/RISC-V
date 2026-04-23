1. ADDI x1, x0, 5    // Load 5 into register 1
2. ADDI x2, x0, 7    // Load 7 into register 2
3. ADD  x3, x1, x2   // Add x1 + x2, store result (12) in register 3
4. JAL  x0, 0        // Infinite loop (Jumps to itself to "stop" the CPU)