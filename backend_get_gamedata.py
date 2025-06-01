import json
import os
import requests
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import base64

# AES parameters
PASSWORD = b"k40cmgi3v*f8vm49gkp1=x9&msd#dk2!"  # 32 bytes
IV = b"leyogame68368354"  # 16 bytes
BLOCK_SIZE = 16

def aes_decrypt(b64_ciphertext: str) -> str:
    encrypted = base64.b64decode(b64_ciphertext)
    cipher = AES.new(PASSWORD, AES.MODE_CBC, IV)
    decrypted = unpad(cipher.decrypt(encrypted), BLOCK_SIZE)
    return decrypted.decode('utf-8', errors='replace')

def prompt_headers(header_dict):
    headers = {}
    for h, default in header_dict.items():
        val = input(f"Enter value for header '{h}' [{default}]: ").strip()
        headers[h] = val if val else default
    return headers

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

    # 6. Prompt for requestDataFlow endpoint
    reqdata_url_base = "https://guigu1.loveballs.club/gameapi/v1/data/getGameDataByUserId?uuid="
    reqdata_url_send = reqdata_url_base + uuid + "&appId=officebuilding_warrior_ioshw"
    data_headers_dict = {
        'content-type': 'application/json',
        'x-wre-app-name': 'officebuilding_warrior_ioshw',
        'x-wre-token': token,
        'accept': '*/*',
        'userid': uuid,
        'x-wre-app-id': 'officebuilding_warrior_ioshw',
        'x-wre-channel': 'gp_ios',
        'x-wre-version': '1.0.1',
        'accept-language': 'en-SE;q=1, sv-SE;q=0.9',
        'user-agent': 'IdleOfficeTycoon/1.7.7 (iPhone; iOS 18.5; Scale/3.00)'
    }

    print("Requesting player data via requestDataFlow...")
    resp2 = requests.get(reqdata_url_send, headers=data_headers_dict)
    if not resp2.ok:
        print(f"Request failed: {resp2.status_code} {resp2.text}")
        return
    data_resp = resp2.json()
    # 8. Extract and decrypt game data
    encrypted_data = data_resp.get('data') or data_resp.get('gameData')
    if not encrypted_data:
        print("No encrypted game data found in response!")
        return
    try:
        decrypted_json = aes_decrypt(encrypted_data)
        print("Decrypted game data (JSON):\n")
        print(decrypted_json)
        # Optionally save to file
        out_path = input("Enter output file path to save JSON (or leave blank to skip): ").strip()
        if out_path:
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(decrypted_json)
            print(f"Decrypted data saved to: {out_path}")
    except Exception as e:
        print(f"Decryption failed: {e}")

if __name__ == "__main__":
    main()
