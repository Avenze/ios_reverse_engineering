import json
import base64
import os
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

# AES parameters
PASSWORD = b"k40cmgi3v*f8vm49gkp1=x9&msd#dk2!"  # 32 bytes
IV = b"leyogame68368354"  # 16 bytes
BLOCK_SIZE = 16

def aes_encrypt(plaintext: str) -> str:
    cipher = AES.new(PASSWORD, AES.MODE_CBC, IV)
    padded = pad(plaintext.encode('utf-8'), BLOCK_SIZE)
    encrypted = cipher.encrypt(padded)
    return base64.b64encode(encrypted).decode('utf-8')

def process_pwd_fields(obj, parent=None):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k.startswith('PWD_') and parent is not None:
                field = k[4:]
                if field in parent:
                    # Encrypt the value of the non-PWD_ field
                    parent[k] = aes_encrypt(str(parent[field]))
            else:
                process_pwd_fields(v, obj)
    elif isinstance(obj, list):
        for item in obj:
            process_pwd_fields(item)

def main():
    input_path = input("Enter the path to the input JSON file: ").strip()
    if not os.path.isfile(input_path):
        print(f"File not found: {input_path}")
        return
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    # Step 1: Re-encrypt all PWD_ fields
    process_pwd_fields(data)
    # Step 2: Encrypt the entire JSON and base64 encode
    json_str = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    encrypted_b64 = aes_encrypt(json_str)
    # Write output
    output_enc = os.path.splitext(input_path)[0] + '_fully_encrypted.b64'
    with open(output_enc, 'w', encoding='utf-8') as f:
        f.write(encrypted_b64)
    print(f"Fully encrypted & base64-encoded file written to: {output_enc}")

if __name__ == "__main__":
    main()
