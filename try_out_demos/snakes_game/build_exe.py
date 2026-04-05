import os
import subprocess

try:
    os.chdir(r"C:\Users\Dancy Naik\Documents\VS_Code_Test\wow_ai\try_out_demos\snakes_game")
    result = subprocess.run(["python", "-m", "PyInstaller", "--onefile", "--windowed", "snakes_ladders.py"], capture_output=True, text=True)
    if result.returncode == 0:
        print("Build succeeded")
    else:
        print("Build failed")
        print(result.stdout)
        print(result.stderr)
except Exception as e:
    print(f"Error: {e}")
