import asyncio
import json
import sys
import uuid
import websockets

TOKEN = "f5gelexrjuzkdgx04koy"
POD_ID = "m083v170w5fdxm"
KERNEL_ID = "3af5a85f-5ef7-4dea-af4f-b8e8b4910d9b"
URI = f"wss://{POD_ID}-8888.proxy.runpod.net/api/kernels/{KERNEL_ID}/channels?token={TOKEN}"

async def exec_bash(cmd: str, timeout: float = 300.0):
    async with websockets.connect(URI, ping_interval=20, ping_timeout=20) as ws:
        msg_id = str(uuid.uuid4())
        
        # We run the command via bash and print stdout/stderr
        python_code = f"""
import subprocess, sys
p = subprocess.Popen({repr(cmd)}, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, executable='/bin/bash')
for line in iter(p.stdout.readline, ''):
    sys.stdout.write(line)
    sys.stdout.flush()
p.wait()
print(f"\\n__RETURN_CODE__={{p.returncode}}")
"""
        req = {
            "header": {
                "msg_id": msg_id,
                "username": "username",
                "session": str(uuid.uuid4()),
                "msg_type": "execute_request",
                "version": "5.3"
            },
            "parent_header": {},
            "metadata": {},
            "content": {
                "code": python_code,
                "silent": False,
                "store_history": True,
                "user_expressions": {},
                "allow_stdin": False
            },
            "channel": "shell"
        }
        await ws.send(json.dumps(req))
        
        output = ""
        ret_code = 0
        start_time = asyncio.get_event_loop().time()
        
        while True:
            if asyncio.get_event_loop().time() - start_time > timeout:
                print(f"[TIMEOUT after {timeout}s]")
                ret_code = 124
                break
            try:
                res = await asyncio.wait_for(ws.recv(), timeout=10.0)
                data = json.loads(res)
                msg_type = data.get("msg_type")
                parent_id = data.get("parent_header", {}).get("msg_id")
                if parent_id == msg_id:
                    if msg_type == "stream":
                        text = data["content"]["text"]
                        output += text
                        sys.stdout.write(text)
                        sys.stdout.flush()
                    elif msg_type == "error":
                        err_text = "\n".join(data["content"]["traceback"])
                        output += err_text
                        sys.stderr.write(err_text + "\n")
                        ret_code = 1
                    elif msg_type == "status" and data["content"]["execution_state"] == "idle":
                        break
            except asyncio.TimeoutError:
                pass
        
        if "__RETURN_CODE__=" in output:
            try:
                ret_code = int(output.split("__RETURN_CODE__=")[1].splitlines()[0].strip())
            except Exception:
                pass
        return ret_code

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 runpod_kernel_exec.py '<comando>' [timeout]")
        sys.exit(1)
    command = sys.argv[1]
    timeout = float(sys.argv[2]) if len(sys.argv) > 2 else 300.0
    code = asyncio.run(exec_bash(command, timeout))
    sys.exit(code)
