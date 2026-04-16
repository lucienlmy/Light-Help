import os
import shutil
from pathlib import Path
import time

# 動態獲取當前用戶主目錄，適配所有 Win10/11 電腦
BASE_DIR = Path.home()

def log(message):
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {message}")

def get_size(path: Path):
    total = 0
    try:
        if path.exists():
            for f in path.rglob('*'):
                try: total += f.stat().st_size
                except: pass
    except: pass
    return total

def run_cleanup():
    log(f"=== 深度清理工具啟動 (目標: {BASE_DIR}) ===")
    
    targets = []
    log("正在掃描緩存與臨時文件...")
    # 掃描邏輯優化
    search_paths = [BASE_DIR / "AppData/Local/Temp", BASE_DIR / "AppData/Local/CrashDumps"]
    
    for root, dirs, files in os.walk(BASE_DIR):
        for dir_name in dirs:
            if any(kw in dir_name for kw in ["Temp", "Cache", "CrashDumps"]):
                targets.append(Path(root) / dir_name)

    if not targets:
        log("未發現可清理目錄。")
        return

    log(f"發現 {len(targets)} 個潛在清理項目。")
    confirm = input("是否執行清理？(Y/N): ").strip().lower()
    if confirm not in ['y', 'yes']:
        print("清理已取消。")
        return

    total_freed = 0
    for folder in targets:
        try:
            if folder.exists() and folder.is_dir():
                size = get_size(folder)
                shutil.rmtree(folder, ignore_errors=True)
                total_freed += size
                log(f"成功清理: {folder.name} ({size/1024/1024:.2f} MB)")
        except:
            pass

    log(f"=== 清理完成，總計釋放: {total_freed/1024/1024:.2f} MB ===")

if __name__ == "__main__":
    run_cleanup()
    input("\n[任務結束] 按回車鍵退出...")