import base64
import getpass
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
import sys

# Hardcoded AES parameters from game code
PASSWORD = b"k40cmgi3v*f8vm49gkp1=x9&msd#dk2!"  # 32 bytes
IV = b"leyogame68368354"  # 16 bytes, fixed
BLOCK_SIZE = 16


def encrypt(plaintext: bytes) -> str:
    cipher = AES.new(PASSWORD, AES.MODE_CBC, IV)
    padded = pad(plaintext, BLOCK_SIZE)
    encrypted = cipher.encrypt(padded)
    return base64.b64encode(encrypted).decode()


def decrypt(b64_ciphertext: str) -> str:
    try:
        ciphertext = base64.b64decode(b64_ciphertext)
        cipher = AES.new(PASSWORD, AES.MODE_CBC, IV)
        decrypted = unpad(cipher.decrypt(ciphertext), BLOCK_SIZE)
        return decrypted.decode(errors="replace")
    except Exception as e:
        return f"[Decryption failed: {e}]"


def main():
    print("=== AES Encrypt/Decrypt Utility ===")
    while True:
        mode = input("Encrypt or Decrypt? (e/d, q to quit): ").strip().lower()
        if mode == 'q':
            print("Exiting.")
            break
        if mode not in ('e', 'd'):
            print("Invalid option. Please enter 'e' or 'd'.")
            continue
        b64_input = input("Enter base64 string to {}crypt: ".format('en' if mode == 'e' else 'de')).strip()
        if not b64_input:
            print("No input provided.")
            continue
        if mode == 'd':
            result = decrypt(b64_input)
            print("\n[Decrypted Result]:\n" + result)
        else:
            # For encryption, decode input from base64 to bytes, then encrypt
            try:
                raw = base64.b64decode(b64_input)
            except Exception as e:
                print(f"[Base64 decode failed: {e}]")
                continue
            result = encrypt(raw)
            print("\n[Encrypted Result]:\n" + result)
        print("\n---\n")

if __name__ == "__main__":
    main()
