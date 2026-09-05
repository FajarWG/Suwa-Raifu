import subprocess, json, sys

files = [
    ('src/shared/data/Fishing.lua', 'game.ReplicatedStorage.Shared.data.Fishing'),
    ('src/shared/constants/Config.lua', 'game.ReplicatedStorage.Shared.constants.Config'),
    ('src/client/controllers/InventoryController.lua', 'game.StarterPlayer.StarterPlayerScripts.Client.controllers.InventoryController'),
    ('src/server/services/ProfileService.lua', 'game.ServerScriptService.Server.services.ProfileService'),
    ('src/server/services/FishingGameService.lua', 'game.ServerScriptService.Server.services.FishingGameService'),
]

for src_path, target_expr in files:
    with open(src_path, 'r') as f:
        content = f.read()

    # Build Lua script to assign s.Source
    # Encode content into json string literal
    encoded_source = json.dumps(content)
    lua_code = f'''
    local target = {target_expr}
    target.Source = {encoded_source}
    return "Updated " .. target:GetFullName() .. " (" .. tostring(#target.Source) .. " bytes)"
    '''

    cmd = ['node', 'scripts/mcp-exec.js', 'exec', lua_code, 'Edit']
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error updating {target_expr}: {res.stderr}")
        sys.exit(1)
    try:
        out = json.loads(res.stdout)
        print(out['content'][0]['text'])
    except Exception as e:
        print(f"Failed parsing output for {target_expr}: {res.stdout}")
        sys.exit(1)

print("All files synced to Studio successfully!")
