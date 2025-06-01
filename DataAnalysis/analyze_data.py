import base64
import json
import binascii
import zlib
import gzip
from urllib.parse import unquote
import string
import struct
import math

def analyze_data_format():
    # Load the data from the JSON file
    with open('../BaiduRequestFlow/netResponse/2-requestDataFlow.json', 'r') as f:
        data = json.load(f)
    
    encoded_data = data['data']
    print(f"Data length: {len(encoded_data)}")
    print(f"First 100 chars: {encoded_data[:100]}")
    print(f"Last 100 chars: {encoded_data[-100:]}")
    
    # Check character distribution
    char_counts = {}
    for char in encoded_data:
        char_counts[char] = char_counts.get(char, 0) + 1
    
    print(f"\nUnique characters: {len(char_counts)}")
    print(f"Character set: {''.join(sorted(char_counts.keys()))}")
    
    # Check if it's base64
    base64_chars = set(string.ascii_letters + string.digits + '+/=')
    is_base64_like = all(c in base64_chars for c in encoded_data)
    print(f"Contains only base64 characters: {is_base64_like}")
    
    # Try different decoding methods
    print("\n=== Attempting different decoding methods ===")
    
    # 1. Base64 decode
    try:
        decoded_b64 = base64.b64decode(encoded_data)
        print(f"Base64 decode successful: {len(decoded_b64)} bytes")
        print(f"First 50 bytes (hex): {decoded_b64[:50].hex()}")
        
        # Analyze the binary data more thoroughly
        analyze_binary_data(decoded_b64)
        
        # Try to decompress the base64 decoded data
        try:
            decompressed_zlib = zlib.decompress(decoded_b64)
            print(f"ZLIB decompression successful: {len(decompressed_zlib)} bytes")
            print(f"Decompressed data preview: {decompressed_zlib[:200]}")
        except:
            print("ZLIB decompression failed")
        
        try:
            decompressed_gzip = gzip.decompress(decoded_b64)
            print(f"GZIP decompression successful: {len(decompressed_gzip)} bytes")
            print(f"Decompressed data preview: {decompressed_gzip[:200]}")
        except:
            print("GZIP decompression failed")
        
        # Try XOR decryption with common patterns
        try_xor_decryption(decoded_b64)
        
        # Try AES decryption
        try_aes_decryption(decoded_b64)
          # Try custom game-specific decryption
        try_custom_decryption(decoded_b64)
        
        # Try advanced AES methods
        try_advanced_aes_methods(decoded_b64)
        
        # Try RC4 decryption
        try_rc4_decryption(decoded_b64)
        
        # Try multi-layer decryption
        try_multi_layer_decryption(decoded_b64)
            
    except Exception as e:
        print(f"Base64 decode failed: {e}")
    
    # 2. URL decode
    try:
        url_decoded = unquote(encoded_data)
        print(f"URL decode result length: {len(url_decoded)}")
        if url_decoded != encoded_data:
            print(f"URL decode changed data: {url_decoded[:100]}")
        else:
            print("URL decode: no change")
    except Exception as e:
        print(f"URL decode failed: {e}")
    
    # 3. Hex decode
    try:
        hex_decoded = binascii.unhexlify(encoded_data)
        print(f"Hex decode successful: {len(hex_decoded)} bytes")
        print(f"Hex decoded preview: {hex_decoded[:50]}")
    except Exception as e:
        print(f"Hex decode failed: {e}")
    
    # 4. Check for patterns
    print(f"\n=== Pattern Analysis ===")
    print(f"Starts with: {encoded_data[:10]}")
    print(f"Ends with: {encoded_data[-10:]}")
    
    # Look for common encryption/encoding signatures
    if encoded_data.startswith('U2FsdGVkX1'):
        print("Possibly AES encrypted with CryptoJS (OpenSSL format)")
    elif encoded_data.startswith('eyJ'):
        print("Possibly base64 encoded JSON")
    elif all(c in '0123456789ABCDEFabcdef' for c in encoded_data):
        print("Possibly hexadecimal encoded")
    
    return encoded_data

def analyze_binary_data(data):
    """Analyze binary data for patterns and structure"""
    print(f"\n=== Binary Data Analysis ===")
    print(f"Total length: {len(data)} bytes")
    
    # Check for common file signatures
    if data.startswith(b'\x78\x9c') or data.startswith(b'\x78\x01'):
        print("Possible ZLIB compressed data")
    elif data.startswith(b'\x1f\x8b'):
        print("Possible GZIP compressed data")
    elif data.startswith(b'PK'):
        print("Possible ZIP archive")
    elif data.startswith(b'\x00\x00\x00'):
        print("Possible encrypted data with null header")
    
    # Fixed entropy calculation
    byte_counts = [0] * 256
    for byte in data:
        byte_counts[byte] += 1
    
    entropy = 0
    for count in byte_counts:
        if count > 0:
            p = count / len(data)
            entropy -= p * math.log2(p)
    
    print(f"Data entropy: {entropy:.2f} (7.5+ suggests encryption, <6 suggests compression)")
    
    # Look for repeating patterns
    print(f"First 16 bytes: {data[:16].hex()}")
    print(f"Bytes 16-32: {data[16:32].hex()}")
    print(f"Last 16 bytes: {data[-16:].hex()}")
    
    # Check if data has block structure (common in AES)
    if len(data) % 16 == 0:
        print("Data length is multiple of 16 (possible AES encryption)")
    if len(data) % 8 == 0:
        print("Data length is multiple of 8 (possible DES/3DES encryption)")
    
    # Analyze byte distribution
    unique_bytes = len([c for c in byte_counts if c > 0])
    print(f"Unique byte values: {unique_bytes}/256")
    
    # Look for null bytes
    null_count = byte_counts[0]
    print(f"Null bytes: {null_count} ({null_count/len(data)*100:.2f}%)")

def try_xor_decryption(data):
    """Try XOR decryption with common keys"""
    print(f"\n=== XOR Decryption Attempts ===")
    
    common_xor_keys = [
        b'gamekey',
        b'1234567890',
        b'password',
        b'secret',
        b'IdleOfficeTycoon',
        b'loveballs',
        b'warrior',
        b'\x42',  # Single byte XOR
        b'\xAA',  # Single byte XOR
        b'\xFF',  # Single byte XOR
        b'\x00',  # Single byte XOR
    ]
    
    # Also try single-byte XOR for all possible values
    for xor_byte in range(256):
        try:
            decrypted = bytearray()
            for byte in data[:100]:  # Test only first 100 bytes for speed
                decrypted.append(byte ^ xor_byte)
            
            # Check if result looks like text or JSON
            try:
                text = decrypted.decode('utf-8', errors='ignore')
                if any(indicator in text.lower() for indicator in ['{', '"', 'data', 'status', 'user', 'game', 'level']):
                    print(f"Possible single-byte XOR success with key 0x{xor_byte:02x}: {text[:50]}")
                    # Try full decryption
                    full_decrypted = bytearray()
                    for byte in data:
                        full_decrypted.append(byte ^ xor_byte)
                    return full_decrypted
            except:
                pass
        except:
            continue
    
    for key in common_xor_keys:
        try:
            decrypted = bytearray()
            for i, byte in enumerate(data):
                decrypted.append(byte ^ key[i % len(key)])
            
            # Check if result looks like text or JSON
            try:
                text = decrypted.decode('utf-8', errors='ignore')
                if any(indicator in text for indicator in ['{', '"', 'data', 'status', 'user']):
                    print(f"Possible XOR success with key {key}: {text[:100]}")
                    return decrypted
            except:
                pass
                
        except Exception as e:
            continue
    
    print("No successful XOR decryption found")

def try_aes_decryption(data):
    """Try AES decryption with common keys"""
    print(f"\n=== AES Decryption Attempts ===")
    
    try:
        from Crypto.Cipher import AES
        from Crypto.Util.Padding import unpad
    except ImportError:
        print("PyCryptodome not installed. Install with: pip install pycryptodome")
        return
    
    # Common keys derived from the game
    common_keys = [
        "officebuilding_warrior",
        "IdleOfficeTycoon",
        "loveballs.club",
        "gameapi",
        "2B10C097-6CB2-4C49-8EE1-AA47EBFC4EFE",
        "1234567890abcdef",
        "abcdef1234567890",
        "guigu1.loveballs.club",
        "x-wre-app-name",
        "officebuilding",
    ]
    
    for key_str in common_keys:
        for key_len in [16, 24, 32]:
            try:
                # Prepare key
                key = key_str.encode()[:key_len].ljust(key_len, b'0')
                
                # Try ECB mode first
                try:
                    cipher = AES.new(key, AES.MODE_ECB)
                    decrypted = cipher.decrypt(data)
                    
                    # Try to remove PKCS7 padding
                    try:
                        unpadded = unpad(decrypted, AES.block_size)
                        text = unpadded.decode('utf-8', errors='ignore')
                        if any(indicator in text for indicator in ['{', '"', 'data', 'status']):
                            print(f"AES ECB success with key '{key_str}' ({key_len} bytes)")
                            print(f"Decrypted preview: {text[:200]}")
                            return unpadded
                    except:
                        # Try without padding removal
                        text = decrypted.decode('utf-8', errors='ignore')
                        if any(indicator in text for indicator in ['{', '"', 'data', 'status']):
                            print(f"AES ECB success (no padding) with key '{key_str}' ({key_len} bytes)")
                            print(f"Decrypted preview: {text[:200]}")
                            return decrypted
                        
                except Exception as e:
                    continue
                
                # Try CBC mode (assume IV is first 16 bytes)
                if len(data) >= 16:
                    try:
                        iv = data[:16]
                        ciphertext = data[16:]
                        cipher = AES.new(key, AES.MODE_CBC, iv)
                        decrypted = cipher.decrypt(ciphertext)
                        
                        try:
                            unpadded = unpad(decrypted, AES.block_size)
                            text = unpadded.decode('utf-8', errors='ignore')
                            if any(indicator in text for indicator in ['{', '"', 'data', 'status']):
                                print(f"AES CBC success with key '{key_str}' ({key_len} bytes)")
                                print(f"Decrypted preview: {text[:200]}")
                                return unpadded
                        except:
                            pass
                            
                    except Exception as e:
                        continue
                        
            except Exception as e:
                continue
    
    print("No successful AES decryption found")

def try_custom_decryption(data):
    """Try custom game-specific decryption methods"""
    print(f"\n=== Custom Decryption Attempts ===")
    
    # Try simple arithmetic operations
    operations = [
        lambda x: (x + 1) & 0xFF,
        lambda x: (x - 1) & 0xFF,
        lambda x: (x + 0x42) & 0xFF,
        lambda x: (x - 0x42) & 0xFF,
        lambda x: (~x) & 0xFF,
        lambda x: ((x << 1) | (x >> 7)) & 0xFF,  # Rotate left
        lambda x: ((x >> 1) | (x << 7)) & 0xFF,  # Rotate right
    ]
    
    for i, op in enumerate(operations):
        try:
            decrypted = bytearray()
            for byte in data[:100]:  # Test first 100 bytes
                decrypted.append(op(byte))
            
            text = decrypted.decode('utf-8', errors='ignore')
            if any(indicator in text.lower() for indicator in ['{', '"', 'data', 'status', 'user', 'game']):
                print(f"Possible success with arithmetic operation {i}: {text[:50]}")
                # Apply to full data
                full_decrypted = bytearray()
                for byte in data:
                    full_decrypted.append(op(byte))
                return full_decrypted
        except:
            continue
    
    print("No successful custom decryption found")

def validate_json_result(data_bytes):
    """Validate if decrypted data is actually valid JSON"""
    try:
        text = data_bytes.decode('utf-8')
        # Remove any null bytes or control characters
        text = ''.join(char for char in text if ord(char) >= 32 or char in '\n\r\t')
        
        # Try to parse as JSON
        json.loads(text)
        return True, text
    except:
        return False, None

def try_advanced_aes_methods(data):
    """Try more AES variations including different modes and key derivations"""
    print(f"\n=== Advanced AES Decryption Attempts ===")
    
    try:
        from Crypto.Cipher import AES
        from Crypto.Util.Padding import unpad
        from Crypto.Protocol.KDF import PBKDF2
        from Crypto.Hash import SHA256
        import hashlib
    except ImportError:
        print("PyCryptodome not installed. Install with: pip install pycryptodome")
        return
    
    # More comprehensive key list
    base_keys = [
        "officebuilding_warrior",
        "IdleOfficeTycoon", 
        "loveballs.club",
        "guigu1.loveballs.club",
        "gameapi",
        "2B10C097-6CB2-4C49-8EE1-AA47EBFC4EFE",
        "officebuilding",
        "warrior",
        "loveballs",
        "office",
        "building",
        "game",
        "api",
        "secret",
        "key",
        "password",
        "1234567890abcdef",
        "abcdef1234567890",
    ]
    
    # Try different key derivation methods
    for base_key in base_keys:
        base_key_bytes = base_key.encode('utf-8')
        
        # Method 1: Direct key (truncate/pad)
        for key_len in [16, 24, 32]:
            key = base_key_bytes[:key_len].ljust(key_len, b'\x00')
            test_aes_with_key(data, key, f"{base_key} (direct, {key_len}B)")
            
        # Method 2: MD5 hash of key
        try:
            md5_key = hashlib.md5(base_key_bytes).digest()
            test_aes_with_key(data, md5_key, f"{base_key} (MD5)")
            
            # Double MD5
            double_md5 = hashlib.md5(md5_key).digest()
            test_aes_with_key(data, double_md5, f"{base_key} (double MD5)")
        except:
            pass
            
        # Method 3: SHA256 hash (truncated to AES key sizes)
        try:
            sha256_key = hashlib.sha256(base_key_bytes).digest()
            test_aes_with_key(data, sha256_key[:16], f"{base_key} (SHA256-16)")
            test_aes_with_key(data, sha256_key[:24], f"{base_key} (SHA256-24)")
            test_aes_with_key(data, sha256_key, f"{base_key} (SHA256-32)")
        except:
            pass
            
        # Method 4: PBKDF2 with common salts
        salts = [b"salt", b"", b"loveballs", b"officebuilding", b"game"]
        for salt in salts:
            try:
                pbkdf2_key = PBKDF2(base_key, salt, 16, count=1000)
                test_aes_with_key(data, pbkdf2_key, f"{base_key} (PBKDF2-{salt})")
            except:
                pass

def test_aes_with_key(data, key, key_desc):
    """Test AES decryption with a specific key"""
    try:
        from Crypto.Cipher import AES
        from Crypto.Util.Padding import unpad
    except ImportError:
        return
        
    modes = [
        (AES.MODE_ECB, "ECB"),
        (AES.MODE_CBC, "CBC"),
        (AES.MODE_CFB, "CFB"),
        (AES.MODE_OFB, "OFB")
    ]
    
    for mode, mode_name in modes:
        try:
            if mode == AES.MODE_ECB:
                cipher = AES.new(key, mode)
                decrypted = cipher.decrypt(data)
            else:
                # Use first 16 bytes as IV for other modes
                if len(data) < 16:
                    continue
                iv = data[:16]
                ciphertext = data[16:]
                cipher = AES.new(key, mode, iv)
                decrypted = cipher.decrypt(ciphertext)
            
            # Test with and without padding removal
            for try_unpad in [True, False]:
                try:
                    test_data = decrypted
                    if try_unpad:
                        test_data = unpad(decrypted, AES.block_size)
                    
                    is_valid, text = validate_json_result(test_data)
                    if is_valid:
                        print(f"🎉 VALID JSON FOUND! Key: {key_desc}, Mode: {mode_name}, Padding: {try_unpad}")
                        print(f"Decrypted JSON: {text}")
                        return test_data
                    
                    # Also check for readable text even if not valid JSON
                    try:
                        text = test_data.decode('utf-8', errors='ignore')
                        readable_chars = sum(1 for c in text if c.isprintable())
                        if readable_chars / len(text) > 0.8:  # 80% printable
                            print(f"Readable text found with {key_desc} ({mode_name}): {text[:100]}")
                    except:
                        pass
                        
                except:
                    continue
                    
        except Exception as e:
            continue

def try_rc4_decryption(data):
    """Try RC4 decryption with various keys"""
    print(f"\n=== RC4 Decryption Attempts ===")
    
    # Simple RC4 implementation
    def rc4(key, data):
        S = list(range(256))
        j = 0
        for i in range(256):
            j = (j + S[i] + key[i % len(key)]) % 256
            S[i], S[j] = S[j], S[i]
        
        i = j = 0
        result = bytearray()
        for byte in data:
            i = (i + 1) % 256
            j = (j + S[i]) % 256
            S[i], S[j] = S[j], S[i]
            result.append(byte ^ S[(S[i] + S[j]) % 256])
        return result
    
    keys = [
        b"officebuilding_warrior",
        b"IdleOfficeTycoon",
        b"loveballs.club",
        b"gameapi",
        b"officebuilding",
        b"warrior",
        b"secret",
        b"2B10C097-6CB2-4C49-8EE1-AA47EBFC4EFE",
    ]
    
    for key in keys:
        try:
            decrypted = rc4(key, data)
            is_valid, text = validate_json_result(decrypted)
            if is_valid:
                print(f"🎉 RC4 SUCCESS! Key: {key}")
                print(f"Decrypted JSON: {text}")
                return decrypted
            
            # Check for readable text
            try:
                text = decrypted.decode('utf-8', errors='ignore')
                readable_chars = sum(1 for c in text if c.isprintable())
                if readable_chars / len(text) > 0.8:
                    print(f"RC4 readable text with key {key}: {text[:100]}")
            except:
                pass
                
        except Exception as e:
            continue
    
    print("No successful RC4 decryption found")

def try_multi_layer_decryption(data):
    """Try combinations of decryption methods (e.g., base64 -> AES -> XOR)"""
    print(f"\n=== Multi-Layer Decryption Attempts ===")
    
    # The data is already base64 decoded, so try additional layers
    
    # Try XOR then AES
    for xor_key in range(1, 256):
        try:
            xor_result = bytearray()
            for byte in data:
                xor_result.append(byte ^ xor_key)
            
            # Try AES on XOR result
            test_aes_with_key(bytes(xor_result), b"officebuilding_w"[:16], f"XOR(0x{xor_key:02x}) + AES")
        except:
            continue

def try_md5_aes_decryption(data):
    """Try AES decryption using MD5 hash of common keys"""
    print(f"\n=== AES Decryption with MD5 Key Attempts ===")
    try:
        from Crypto.Cipher import AES
        from Crypto.Util.Padding import unpad
        import hashlib
    except ImportError:
        print("PyCryptodome not installed. Install with: pip install pycryptodome")
        return

    # Common keys to try
    keys = [
        "officebuilding_warrior",
        "IdleOfficeTycoon",
        "loveballs.club",
        "gameapi",
        "2B10C097-6CB2-4C49-8EE1-AA47EBFC4EFE",
        "1234567890abcdef",
        "abcdef1234567890",
        "guigu1.loveballs.club",
        "x-wre-app-name",
        "officebuilding",
        "warrior",
        "loveballs",
        "office",
        "building",
        "game",
        "api",
        "secret",
        "key",
        "password",
    ]
    for key_str in keys:
        md5_key = hashlib.md5(key_str.encode('utf-8')).digest()
        try:
            cipher = AES.new(md5_key, AES.MODE_ECB)
            decrypted = cipher.decrypt(data)
            try:
                unpadded = unpad(decrypted, AES.block_size)
                text = unpadded.decode('utf-8', errors='ignore')
                if any(indicator in text for indicator in ['{', '"', 'data', 'status']):
                    print(f"AES ECB (MD5 key) success with key '{key_str}'")
                    print(f"Decrypted preview: {text[:200]}")
                    return unpadded
            except:
                text = decrypted.decode('utf-8', errors='ignore')
                if any(indicator in text for indicator in ['{', '"', 'data', 'status']):
                    print(f"AES ECB (MD5 key, no padding) success with key '{key_str}'")
                    print(f"Decrypted preview: {text[:200]}")
                    return decrypted
        except Exception as e:
            continue
    print("No successful AES decryption with MD5 key found")
