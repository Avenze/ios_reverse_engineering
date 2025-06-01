import json
import os
import requests
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
import base64

# AES parameters
PASSWORD = b"k40cmgi3v*f8vm49gkp1=x9&msd#dk2!"  # 32 bytes
IV = b"leyogame68368354"  # 16 bytes
BLOCK_SIZE = 16

# Helper: AES encrypt and base64 encode
def aes_encrypt(plaintext: str) -> str:
    cipher = AES.new(PASSWORD, AES.MODE_CBC, IV)
    padded = pad(plaintext.encode('utf-8'), BLOCK_SIZE)
    encrypted = cipher.encrypt(padded)
    return base64.b64encode(encrypted).decode('utf-8')

# Helper: Re-encrypt all PWD_ fields in-place
def process_pwd_fields(obj):
    if isinstance(obj, dict):
        keys = list(obj.keys())
        for k in keys:
            v = obj[k]
            if k.startswith('PWD_'):
                field = k[4:]
                if field in obj:
                    obj[k] = aes_encrypt(str(obj[field]))
            else:
                process_pwd_fields(v)
    elif isinstance(obj, list):
        for item in obj:
            process_pwd_fields(item)

# Main workflow

def main():
    # 1. Load userLogin request template
    userlogin_path = os.path.join('BackendRequestFlow', 'netResponse', '1-userLogin.json')
    with open(userlogin_path, 'r', encoding='utf-8') as f:
        userlogin_req = json.load(f)
    # 2. Prompt for login endpoint
    login_url = input("Enter the userLogin endpoint URL (e.g. http://127.0.0.1:8000/userLogin): ").strip()
    # 3. Send userLogin request
    print("Requesting token via userLogin...")
    resp = requests.post(login_url, json=userlogin_req)
    if not resp.ok:
        print(f"Login failed: {resp.status_code} {resp.text}")
        return
    login_data = resp.json()
    token = login_data.get('token') or login_data.get('data', {}).get('token')
    if not token:
        print("No token found in response!")
        return
    print(f"Received token: {token}")

    # 4. Prompt for game data file
    game_data_path = input("Enter the path to the game data JSON file: ").strip()
    if not os.path.isfile(game_data_path):
        print(f"File not found: {game_data_path}")
        return
    with open(game_data_path, 'r', encoding='utf-8') as f:
        game_data = json.load(f)
    # 5. Re-encrypt all PWD_ fields
    process_pwd_fields(game_data)
    # 6. Encrypt and encode the entire JSON
    json_str = json.dumps(game_data, ensure_ascii=False, separators=(",", ":"))
    encrypted_b64 = aes_encrypt(json_str)

    # 7. Load gameapi_saving request template
    saving_path = os.path.join('BackendRequestFlow', 'netResponse', '3-gameapi_saving.json')
    with open(saving_path, 'r', encoding='utf-8') as f:
        saving_req = json.load(f)
    # 8. Insert token and encrypted data
    if 'token' in saving_req:
        saving_req['token'] = token
    elif 'data' in saving_req and isinstance(saving_req['data'], dict):
        saving_req['data']['token'] = token
    # Insert encrypted data (assuming field is 'data' or similar)
    if 'data' in saving_req:
        saving_req['data']['gameData'] = encrypted_b64
    else:
        saving_req['gameData'] = encrypted_b64

    # 9. Prompt for gameapi_saving endpoint
    saving_url = input("Enter the gameapi_saving endpoint URL (e.g. http://127.0.0.1:8000/gameapi_saving): ").strip()
    # 10. Send gameapi_saving request
    print("Sending encrypted game data...")
    resp2 = requests.post(saving_url, json=saving_req)
    print(f"Response: {resp2.status_code}\n{resp2.text}")

if __name__ == "__main__":
    main()
