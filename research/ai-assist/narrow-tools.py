#!/usr/bin/env python3
"""Convert plantoir-mcp tools/list output to the OpenAI-shaped, narrowed
surface the local model actually sees — mirroring AssistAgent.NarrowToLocal
and Briefly() exactly."""
import json, sys

FOR_THE_LOCAL_MODEL = {
    "list_pages", "read_page", "check_section",
    "plan_publish_class_on", "publish_class_on",
    "plan_publish_pages", "publish_pages",
    "plan_unpublish_pages", "unpublish_pages",
    "rebuild_preview", "undo_last_change",
    "deploy_section", "plan_scheduled_deploy", "schedule_deploy", "cancel_scheduled_deploy",
}

def briefly(description):
    kept = []
    end = description.find('". ')
    if description.startswith("TEACHERS SAY:") and end > 0:
        kept.append(description[:end + 2])
        description = description[end + 3:]
    stop = description.find(". ")
    kept.append(description[:stop + 1] if stop > 0 else description)
    return " ".join(kept).strip()

raw = json.load(open(sys.argv[1], encoding="utf-8-sig"))
tools = raw["result"]["tools"]
kept = []
for tool in tools:
    if tool["name"] not in FOR_THE_LOCAL_MODEL:
        continue
    kept.append({
        "type": "function",
        "function": {
            "name": tool["name"],
            "description": briefly(tool.get("description", "")),
            "parameters": tool.get("inputSchema", {"type": "object"}),
        },
    })
json.dump(kept, open(sys.argv[2], "w", encoding="utf-8"), indent=1)
full = [t["name"] for t in tools]
print("server tools: %d, narrowed: %d" % (len(full), len(kept)))
print("kept:", ", ".join(t["function"]["name"] for t in kept))
missing = FOR_THE_LOCAL_MODEL - set(full)
if missing:
    print("IN THE SET BUT NOT ON THE SERVER:", ", ".join(sorted(missing)))
chars = len(json.dumps(kept))
print("narrowed surface: %d chars (~%d tokens at 3.6 chars/token)" % (chars, chars / 3.6))
