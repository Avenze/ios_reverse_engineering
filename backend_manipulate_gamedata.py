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
    login_url = "https://guigu1.loveballs.club/gameapi/v1/users/login/v2"
    login_headers_dict = {
        'content-type': 'application/json',
        'x-wre-app-name': 'officebuilding_warrior_ioshw',
        'accept': '*/*',
        'x-wre-app-id': 'officebuilding_warrior_ioshw',
        'x-wre-channel': 'gp_ios',
        'x-wre-version': '1.0.1',
        'accept-language': 'en-SE;q=1, sv-SE;q=0.9',
        'user-agent': 'IdleOfficeTycoon/1.7.7 (iPhone; iOS 18.5; Scale/3.00)'
    }
    login_parameters_dict = {
        'deviceId': 'C9A3333D-1E1F-4F1E-9B51-11A885E51B3E',
        'loginType': '',
        'accountId': ''
    }

    # 3. Send userLogin request
    print("Requesting token via userLogin...")
    resp = requests.post(login_url, json=login_parameters_dict, headers=login_headers_dict)
    if not resp.ok:
        print(f"Login failed: {resp.status_code} {resp.text}")
        return
    login_data = resp.json()
    token = login_data.get('token') or login_data.get('data', {}).get('token')
    uuid = login_data.get('uuid') or login_data.get('data', {}).get('uuid')
    if not token:
        print("No token found in response!")
        return
    if not uuid:
        print("No UUID found in response!")
        return
    print(f"Received token: {token}")
    print(f"Received UUID: {uuid}")

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

    reqdata_url_base = "https://guigu1.loveballs.club/gameapi/v1/data/game"
    data_headers_dict = {
        'content-type': 'application/json',
        'x-wre-app-name': 'officebuilding_warrior_ioshw',
        'x-wre-token': token,
        'accept': '*/*',
        'x-wre-app-id': 'officebuilding_warrior_ioshw',
        'x-wre-channel': 'gp_ios',
        'x-wre-version': '1.0.1',
        'accept-language': 'en-SE;q=1, sv-SE;q=0.9',
        'user-agent': 'IdleOfficeTycoon/1.7.7 (iPhone; iOS 18.5; Scale/3.00)'
    }
    data_parameters_dict = {
        'appId': 'officebuilding_warrior_ioshw',
        'uuid': uuid,
        'data': encrypted_b64
    }

    print("Sending encrypted game data...")
    resp2 = requests.post(reqdata_url_base, json=data_parameters_dict, headers=data_headers_dict)
    print(f"Response: {resp2.status_code}\n{resp2.text}")

if __name__ == "__main__":
    main()
