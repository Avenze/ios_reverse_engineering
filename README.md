# Idle Office Tyccon Reverse Engineering Project

This repository contains tools, scripts, and analysis resources for reverse engineering, data extraction, and cryptographic analysis of Unity-based games. The project is organized to support workflows such as decryption/encryption of game data, Lua/C# code analysis, and automation of data processing tasks.

## Main Features
- **AES Encryption/Decryption**: Scripts for handling game data encryption and decryption using discovered keys and IVs.
- **Data Analysis**: Utilities for analyzing, renaming, and processing binary and Lua files.
- **Reverse Engineering**: Disassembled pseudocode and scripts for tracing data flow in Unity games.
- **Automation**: Batch processing, anonymization, and conversion tools for game data.

## Tools Used
- **AssetRipper**: For extracting Lua scripts and assets from Unity asset bundles.
- **IL2CPP Dumper GUI**: For extracting and dumping IL2CPP headers and function names from the UnityFramework binary.
- **Ghidra**: For disassembly and binary decompiling of native code and Unity binaries.
- **IDA Pro**: For advanced disassembly, analysis, and pseudocode generation of binaries.
- **Mitmproxy**: For capturing and analyzing live network traffic between the game and backend servers.
- **Python**: For scripting, automation, and cryptographic operations.

## Repository Structure
- `DataAnalysis/` — Python scripts and tools for data extraction, decryption, and analysis.
- `ExtractedLuaScripts/` — Decompiled Lua scripts and related Unity assets.
- `DisassembledPseudocode/` — Decompiled and reverse-engineered pseudocode from native modules.
- `GhidraDisassembledPseudocode/` — Ghidra output for further static analysis.
- `BackendRequestFlow/` — Example backend request/response flows and network captures.

## Getting Started
1. Install Python 3.8+ and required dependencies (see `DataAnalysis/README.md`).
2. Review the scripts in `DataAnalysis/` for decryption, encryption, and data processing.
3. See subcategory READMEs for details on each folder and workflow.

## Subcategory READMEs
- [DataAnalysis/README.md](DataAnalysis/README.md): Data analysis, encryption, and automation scripts.
- [ExtractedLuaScripts/README.md](ExtractedLuaScripts/README.md): Lua script structure and usage.
- [DisassembledPseudocode/README.md](DisassembledPseudocode/README.md): Native code and pseudocode analysis.
- [BackendRequestFlow/README.md](BackendRequestFlow/README.md): Backend request/response flow documentation.

---

**Disclaimer:** This repository is for educational and research purposes only. Use responsibly and respect all applicable laws and software licenses.
