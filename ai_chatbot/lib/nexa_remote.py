import os
import time
import pyautogui
import screen_brightness_control as sbc
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("new_key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print(f"Connected to Nexa Remote! Waiting for commands!")

def execute_action(action):
    try:
        if action == "open_explorer":
            os.system("start explorer")
        elif action == "open_chrome":
            os.system("start chrome")
        elif action == "volume_up":
            pyautogui.press('volumeup', presses=10)
        elif action == "volume_down":
            pyautogui.press('volumedown', presses=10)
        elif action == "brightness_up":
            curr = sbc.get_brightness()[0]
            sbc.set_brightness(min(curr + 25, 100))
        elif action == "brightness_down":
            curr = sbc.get_brightness()[0]
            sbc.set_brightness(max(curr - 25, 0))
        elif action == "screenshot":
            path = os.path.join(os.path.expanduser('~'), 'Desktop', 'nexa_shot.png')
            pyautogui.screenshot(path)
            os.startfile(path)
        elif action == "close_window":
            pyautogui.hotkey('alt', 'f4')
        elif action == "power_off":
            os.system("shutdown /s /t 10")
    except Exception as e:
        print(f"Hardware Error: {e}")

while True:
    try:
        docs = db.collection("commands").get()
        for doc in docs:
            action = doc.to_dict().get('action')
            execute_action(action)
            doc.reference.delete()
    except Exception:
        time.sleep(5)
    time.sleep(1)
