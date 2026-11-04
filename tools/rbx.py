"""Tiny client for Roblox Studio's built-in MCP server.
usage: python rbx.py list
       python rbx.py run steps.json      (list of {"tool":..., "args":{...}, "code_file":..., "save":...})
One connection for the whole batch; waits until Studio shows up first.
"""
import asyncio, base64, json, os, sys
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

BAT = os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")


def is_err(res):
    return getattr(res, "is_error", None) or getattr(res, "isError", False)


async def main():
    params = StdioServerParameters(command="cmd.exe", args=["/c", BAT])
    async with stdio_client(params) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            if sys.argv[1] == "list":
                for t in (await s.list_tools()).tools:
                    schema = getattr(t, "input_schema", None) or getattr(t, "inputSchema", {})
                    print(t.name, "::", json.dumps(schema.get("properties", {})))
                return
            sid = None
            for _ in range(40):
                res = await s.call_tool("list_roblox_studios", {})
                studios = json.loads(res.content[0].text).get("studios", [])
                if studios:  # 11-03: two Studios can be open; this tool drives Place1 (the heist game)
                    sid = next((x["id"] for x in studios if x.get("name") == "Place1"), studios[0]["id"])
                    break
                await asyncio.sleep(0.5)
            if not sid:
                sys.exit("no studio connected")
            steps = json.load(open(sys.argv[2], encoding="utf-8"))
            failed = False
            for i, st in enumerate(steps):
                args = dict(st.get("args", {}), studio_id=sid)
                if "code_file" in st:
                    args["code"] = open(st["code_file"], encoding="utf-8").read()
                res = await s.call_tool(st["tool"], args)
                for c in res.content:
                    if c.type == "text":
                        print(f"[{i} {st['tool']}]", c.text[:4000])
                    elif c.type == "image" and st.get("save"):
                        open(st["save"], "wb").write(base64.b64decode(c.data))
                        print(f"[{i}] saved", st["save"])
                if is_err(res):
                    failed = True
                    print(f"[{i}] ERROR")
                    break
            sys.exit(1 if failed else 0)


asyncio.run(main())
