import os
import time
import pyautogui
import screen_brightness_control as sbc
import firebase_admin
from firebase_admin import credentials, firestore

# Setup
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("--- NEXA REMOTE: FULL SYSTEM ACTIVE ---")

def execute_action(action):
    try:
        print(f"Action Attempt: {action}")

        if action == "open_explorer":
            os.system("start explorer")

        elif action == "open_chrome":
            os.system("start chrome")

        elif action == "volume_up":
            for _ in range(10): pyautogui.press('volumeup')

        elif action == "volume_down":
            for _ in range(10): pyautogui.press('volumedown')

        elif action == "brightness_up":
            # Nested try because some PC monitors don't allow brightness control
            try:
                curr = sbc.get_brightness()[0]
                sbc.set_brightness(min(curr + 25, 100))
            except: print("Hardware blocked brightness control.")

        elif action == "brightness_down":
            try:
                curr = sbc.get_brightness()[0]
                sbc.set_brightness(max(curr - 25, 0))
            except: print("Hardware blocked brightness control.")

        elif action == "screenshot":
            path = os.path.join(os.path.expanduser('~'), 'Desktop', 'nexa_shot.png')
            pyautogui.screenshot(path)
            os.startfile(path)

        elif action == "close_window":
            # Force Alt+F4
            pyautogui.keyDown('alt')
            pyautogui.press('f4')
            pyautogui.keyUp('alt')

        elif action == "power_off":
            os.system("shutdown /s /t 10")

        print(f"Result: {action} Success")

    except Exception as e:
        print(f"CRITICAL ERROR on {action}: {e}")

def on_snapshot(col_snapshot, changes, read_time):
    for change in changes:
        if change.type.name == 'ADDED':
            data = change.document.to_dict()
            action = data.get('action')

            # 1. Execute with full error handling
            execute_action(action)

            # 2. Cleanup Firebase immediately
            change.document.reference.delete()

# Watcher
db.collection("commands").on_snapshot(on_snapshot)

while True:
    time.sleep(1)
