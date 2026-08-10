import os
import time
import pyautogui
import firebase_admin
from firebase_admin import credentials, firestore


try:

    cred = credentials.Certificate("new_key.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    print(f"Nexa remote is listening, Waiting for commands!")
except Exception as e:
    print(f"CONNECTION FAILED: {e}")
    exit()

def execute_action(action):
    print(f" ATTEMPTING ACTION: {action}")
    try:
        if action == "open_explorer":
            os.system("start explorer")
        elif action == "open_chrome":
            os.system("start chrome")
        elif action == "screenshot":
            path = os.path.join(os.path.expanduser('~'), 'Desktop', 'nexa_shot.png')
            pyautogui.screenshot(path)
            os.startfile(path)
        elif action == "volume_up":
            for _ in range(10): pyautogui.press('volumeup')
        elif action == "volume_down":
            for _ in range(10): pyautogui.press('volumedown')
        elif action == "close_window":
            pyautogui.hotkey('alt', 'f4')
        print(f"{action} executed successfully!")
    except Exception as e:
        print(f"Hardware Error: {e}")

while True:
    try:
        docs = db.collection("commands").get()

        if len(docs) > 0:
            print(f"Found {len(docs)} new commands!")
            for doc in docs:
                action = doc.to_dict().get('action')
                execute_action(action)
                doc.reference.delete() # Clear it
        else:
            print("... listening ...", end="\r")

    except Exception as e:
        print(f"\nFIREBASE ERROR: {e}")
        time.sleep(5)

    time.sleep(1) # Check every 1 second
