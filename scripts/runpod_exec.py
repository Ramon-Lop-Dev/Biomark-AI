import asyncio
import base64
import json
import sys
import websockets

TOKEN = "f5gelexrjuzkdgx04koy"
POD_ID = "m083v170w5fdxm"
URI = f"wss://{POD_ID}-8888.proxy.runpod.net/terminals/websocket/1?token={TOKEN}"

async def run_command(command: str, timeout: float = 60.0):
    async with websockets.connect(URI) as ws:
        # Create execution script inside the container
        b64_cmd = base64.b64encode(command.encode()).decode()
        setup_script = (
            f"echo '{b64_cmd}' | base64 -d > /tmp/task.sh && "
            f"chmod +x /tmp/task.sh && "
            f"/tmp/task.sh > /tmp/task.log 2>&1; echo \"EXEC_STATUS:$?\"\n"
        )
        await ws.send(json.dumps(["stdin", setup_script]))
        
        # Wait for EXEC_STATUS:X
        start_time = asyncio.get_event_loop().time()
        exit_code = -1
        while True:
            if asyncio.get_event_loop().time() - start_time > timeout:
                print(f"[TIMEOUT after {timeout}s]")
                break
            try:
                msg = await asyncio.wait_for(ws.recv(), timeout=2.0)
                data = json.loads(msg)
                if data[0] == "stdout":
                    text = data[1]
                    if "EXEC_STATUS:" in text:
                        for line in text.splitlines():
                            if "EXEC_STATUS:" in line:
                                try:
                                    exit_code = int(line.split("EXEC_STATUS:")[1].strip())
                                except Exception:
                                    exit_code = 0
                        break
            except asyncio.TimeoutError:
                pass
        
        # Fetch log file content
        await ws.send(json.dumps(["stdin", "cat /tmp/task.log; echo 'LOG_END_MARKER'\n"]))
        log_content = ""
        while True:
            try:
                msg = await asyncio.wait_for(ws.recv(), timeout=2.0)
                data = json.loads(msg)
                if data[0] == "stdout":
                    chunk = data[1]
                    log_content += chunk
                    if "LOG_END_MARKER" in log_content:
                        break
            except asyncio.TimeoutError:
                break
        
        # Clean log
        cleaned = log_content.split("cat /tmp/task.log")[-1].split("LOG_END_MARKER")[0].strip()
        print(cleaned)
        return exit_code

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 runpod_exec.py '<comando>' [timeout]")
        sys.exit(1)
    cmd = sys.argv[1]
    timeout = float(sys.argv[2]) if len(sys.argv) > 2 else 60.0
    code = asyncio.run(run_command(cmd, timeout))
    sys.exit(code)
