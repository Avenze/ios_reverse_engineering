# DataAnalysis

This folder contains Python scripts and utilities for:
- Decrypting and encrypting Unity game data (AES, base64, etc.)
- Batch processing and renaming of files
- Data extraction, anonymization, and analysis
- Automation of common reverse engineering tasks

## Setup
1. Install Python 3.8+.
2. Install dependencies:
   ```sh
   pip install pycryptodome
   ```
3. See individual script headers for usage instructions.

## Key Scripts
- `aes_encrypt_decrypt.py`: Interactive AES encryption/decryption tool.
- `analyze_data.py`: Main data analysis and decryption workflow.
- `rename_bytes_to_lua.py`: Recursively renames `.bytes` files to `.lua`.
- `reencrypt_pwd_fields.py`: Re-encrypts all PWD_ fields in a JSON file.
- `encrypt_gamedata.py`: Re-encrypts PWD_ fields and encrypts the entire JSON file.
- `anonymize_json.py`: Anonymizes all values in a JSON file for privacy.

## Example Usage
To decrypt a base64-encoded AES string:
```sh
python aes_encrypt_decrypt.py
```

To re-encrypt and fully encrypt a game data file:
```sh
python encrypt_gamedata.py
```

---
See the main [README.md](../README.md) for project overview.
