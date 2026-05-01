# XOR Encryptor (C++ & Assembly x64)

A high-performance command-line utility for XOR encryption and decryption. The project demonstrates low-level system integration by combining a modern C++ frontend with a highly optimized 64-bit Assembly backend.

### Architecture
- **Frontend (C++)**: Handles user input, memory allocation (via exception-safe `std::vector`), hex string parsing, and clipboard integration via Windows API.
- **Backend (Assembly x64)**: Implements the core XOR bitwise logic and rapid byte-to-hexadecimal conversion adhering strictly to the Microsoft x64 calling convention (ABI).
