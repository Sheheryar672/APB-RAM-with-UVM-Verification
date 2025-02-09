# APB RAM (UVM Verified)

## Overview  
The **Advanced Peripheral Bus (APB)** is a low-power, low-bandwidth bus protocol used for interfacing peripherals in SoC designs. This project implements an **APB-based RAM**, verified using **UVM**, ensuring protocol compliance and efficient memory operation.

## Features  
- **Implements all APB general signals:** PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY  
- **SLV error detection** for enhanced reliability  
- **32-word memory depth** for efficient data storage  
- **FSM-based operation** with **Idle, Setup, Access, and Complete** states  

## Makefile Instructions  

This project includes a **Makefile** for compiling, simulating, and displaying the waveform of the APB RAM.  

### **Prerequisites**  
Ensure that **QuestaSim** with **UVM 1.2** is installed and accessible in your system's **PATH**.  
