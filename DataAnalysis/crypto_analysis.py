import base64
import json
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import hashlib

def try_common_game_decryption():
    """Try common encryption methods used in mobile games"""
    
    # Load the data
    with open('netResponse/2-requestDataFlow.json', 'r') as f:
        data = json.load(f)
    
    encoded_data = data['data']
    
    # First, assume it's base64 encoded
    try:
        encrypted_data = base64.b64decode(encoded_data)
        print(f"Successfully decoded base64: {len(encrypted_data)} bytes")
    except:
        print("Not valid base64")
        return
    
    # Common game encryption keys/methods to try
    common_keys = [
        "officebuilding_warrior",  # From the app name
        "loveballs.club",          # From the domain
        "IdleOfficeTycoon",        # From user agent
        "gameapi",                 # From API path
        "2B10C097-6CB2-4C49-8EE1-AA47EBFC4EFE",  # Device ID
        "1234567890123456",        # Common default
        "abcdef1234567890",        # Common default
    ]
    
    # Try AES decryption with common modes
    for key_str in common_keys:
        # Try different key lengths
        for key_len in [16, 24, 32]:
            try:
                # Prepare key
                key = key_str.encode()[:key_len].ljust(key_len, b'0')
                
                # Try different AES modes
                for mode_name, mode in [("ECB", AES.MODE_ECB), ("CBC", AES.MODE_CBC)]:
                    try:
                        if mode == AES.MODE_CBC:
                            # Assume IV is first 16 bytes
                            if len(encrypted_data) < 16:
                                continue
                            iv = encrypted_data[:16]
                            ciphertext = encrypted_data[16:]
                            cipher = AES.new(key, mode, iv)
                        else:
                            cipher = AES.new(key, mode)
                            ciphertext = encrypted_data
                        
                        decrypted = cipher.decrypt(ciphertext)
                        
                        # Try to remove padding
                        try:
                            unpadded = unpad(decrypted, AES.block_size)
                            print(f"SUCCESS with key '{key_str}' ({key_len} bytes), mode {mode_name}")
                            print(f"Decrypted data preview: {unpadded[:200]}")
                            
                            # Try to parse as JSON
                            try:
                                json_data = json.loads(unpadded.decode('utf-8'))
                                print(f"Valid JSON found!")
                                print(json.dumps(json_data, indent=2)[:500])
                            except:
                                print("Not valid JSON")
                            
                            return unpadded
                            
                        except:
                            # Maybe no padding
                            try:
                                decoded_str = decrypted.decode('utf-8', errors='ignore')
                                if any(c in decoded_str for c in '{}[]"'):  # Looks like JSON
                                    print(f"POSSIBLE SUCCESS with key '{key_str}' ({key_len} bytes), mode {mode_name}")
                                    print(f"Decrypted data preview: {decoded_str[:200]}")
                            except:
                                pass
                    
                    except Exception as e:
                        continue
                        
            except Exception as e:
                continue
    
    print("No successful decryption found with common methods")

def analyze_encryption_hints():
    """Look for hints about the encryption method in the response"""
    
    with open('netResponse/2-requestDataFlow.json', 'r') as f:
        data = json.load(f)
    
    print("=== Response Analysis ===")
    print(f"Status: {data.get('status')}")
    print(f"Message: {data.get('message')}")
    print(f"Error Code: {data.get('errorCode')}")
    
    # The fact that there's a 'data' field with encrypted content suggests
    # the server is returning encrypted game data
    print("\nThis appears to be encrypted game response data.")
    print("Common possibilities:")
    print("1. AES encryption with game-specific key")
    print("2. Custom XOR encryption")
    print("3. Compressed then encrypted data")
    print("4. Multiple layers of encoding/encryption")

def try_xor_decryption():
    """Try XOR decryption with various keys"""
    
    with open('netResponse/2-requestDataFlow.json', 'r') as f:
        data = json.load(f)
    
    encoded_data = data['data']
    encrypted_data = base64.b64decode(encoded_data)
    
    print("=== XOR Decryption Analysis ===")
    
    # Try single-byte XOR
    for key in range(1, 256):
        result = bytes([b ^ key for b in encrypted_data])
        decoded_str = result.decode('utf-8', errors='ignore')
        
        # Check if result looks like JSON or readable text
        if any(marker in decoded_str for marker in ['{"', '[{', '"data"', '"status"']):
            print(f"Potential XOR key found: {key} (0x{key:02x})")
            print(f"Preview: {decoded_str[:200]}")
            
            # Try to parse as JSON
            try:
                json_data = json.loads(decoded_str)
                print(f"VALID JSON with XOR key {key}!")
                print(json.dumps(json_data, indent=2)[:500])
                return result
            except:
                print("Contains JSON markers but not valid JSON")
    
    # Try multi-byte XOR with common patterns
    common_patterns = [
        b"key",
        b"game",
        b"data",
        b"auth",
        b"user",
        b"pass",
        bytes([0x42, 0x69, 0x6E, 0x61]),  # "Bina"
        bytes(range(8)),  # Sequential pattern
    ]
    
    for pattern in common_patterns:
        result = bytes([encrypted_data[i] ^ pattern[i % len(pattern)] for i in range(len(encrypted_data))])
        decoded_str = result.decode('utf-8', errors='ignore')
        
        if any(marker in decoded_str for marker in ['{"', '[{', '"data"', '"status"']):
            print(f"Potential multi-byte XOR pattern found: {pattern}")
            print(f"Preview: {decoded_str[:200]}")

def analyze_encryption_type():
    """Analyze the encrypted data to determine possible encryption type"""
    
    with open('netResponse/2-requestDataFlow.json', 'r') as f:
        data = json.load(f)
    
    encoded_data = data['data']
    encrypted_data = base64.b64decode(encoded_data)
    
    print("=== Encryption Type Analysis ===")
    print(f"Data length: {len(encrypted_data)} bytes")
    print(f"First 32 bytes (hex): {encrypted_data[:32].hex()}")
    print(f"Last 32 bytes (hex): {encrypted_data[-32:].hex()}")
    
    # Check if length is multiple of common block sizes
    if len(encrypted_data) % 16 == 0:
        print("Length is multiple of 16 - possible AES")
    if len(encrypted_data) % 8 == 0:
        print("Length is multiple of 8 - possible DES/3DES")
    
    # Statistical analysis
    byte_counts = [0] * 256
    for byte in encrypted_data:
        byte_counts[byte] += 1
    
    # Calculate entropy (randomness)
    import math
    entropy = 0
    for count in byte_counts:
        if count > 0:
            p = count / len(encrypted_data)
            entropy -= p * math.log2(p)
    
    print(f"Entropy: {entropy:.2f} bits (max 8.0 for perfect randomness)")
    
    if entropy > 7.5:
        print("High entropy - likely encrypted or compressed")
    elif entropy < 6.0:
        print("Lower entropy - might be encoded or weakly encrypted")
    
    # Check for common headers
    headers = {
        b'\x78\x9c': 'zlib compression',
        b'\x1f\x8b': 'gzip compression',
        b'PK': 'ZIP file',
        b'BZ': 'bzip2 compression',
    }
    
    for header, desc in headers.items():
        if encrypted_data.startswith(header):
            print(f"Detected: {desc}")

def try_compression_then_decrypt():
    """Try decompressing the data first, then decrypt"""
    import zlib
    import gzip
    
    with open('netResponse/2-requestDataFlow.json', 'r') as f:
        data = json.load(f)
    
    encoded_data = data['data']
    encrypted_data = base64.b64decode(encoded_data)
    
    print("=== Compression + Encryption Analysis ===")
    
    # Try zlib decompression first
    try:
        decompressed = zlib.decompress(encrypted_data)
        print(f"Successfully decompressed with zlib: {len(decompressed)} bytes")
        print(f"Decompressed preview: {decompressed[:200]}")
        
        # Try to parse as JSON
        try:
            json_data = json.loads(decompressed.decode('utf-8'))
            print("FOUND VALID JSON after zlib decompression!")
            print(json.dumps(json_data, indent=2))
            return decompressed
        except:
            print("Decompressed but not valid JSON")
    except:
        pass
    
    # Try gzip decompression
    try:
        decompressed = gzip.decompress(encrypted_data)
        print(f"Successfully decompressed with gzip: {len(decompressed)} bytes")
        print(f"Decompressed preview: {decompressed[:200]}")
    except:
        pass

def try_game_specific_methods():
    """Try game-specific decryption methods"""
    
    with open('netResponse/2-requestDataFlow.json', 'r') as f:
        data = json.load(f)
    
    encoded_data = data['data']
    encrypted_data = base64.b64decode(encoded_data)
    
    print("=== Game-Specific Methods ===")
    
    # Method 1: Unity's simple encryption (XOR with repeating key)
    unity_key = "UnityEngine"
    result = bytes([encrypted_data[i] ^ ord(unity_key[i % len(unity_key)]) for i in range(len(encrypted_data))])
    if b'{' in result[:100] or b'"' in result[:100]:
        print("Potential Unity encryption found")
        print(f"Preview: {result[:200]}")
    
    # Method 2: Try RC4 (stream cipher)
    try:
        from Crypto.Cipher import ARC4
        rc4_keys = ["gamekey", "datakey", "loveballs", "officebuilding"]
        
        for key in rc4_keys:
            cipher = ARC4.new(key.encode())
            decrypted = cipher.decrypt(encrypted_data)
            decoded_str = decrypted.decode('utf-8', errors='ignore')
            
            if any(marker in decoded_str for marker in ['{"', '"data"', '"status"']):
                print(f"Potential RC4 key found: {key}")
                print(f"Preview: {decoded_str[:200]}")
    except ImportError:
        print("RC4 cipher not available")

if __name__ == "__main__":
    try_common_game_decryption()
    print("\n" + "="*50)
    try_xor_decryption()
    print("\n" + "="*50)
    analyze_encryption_type()
    print("\n" + "="*50)
    try_compression_then_decrypt()
    print("\n" + "="*50)
    try_game_specific_methods()
    print("\n" + "="*50)
    analyze_encryption_hints()
