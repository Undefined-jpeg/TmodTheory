# Tmod Theory [RECODE!!!] — Script Source

All 184 Luau scripts (1,150,054 bytes) exported from the Roblox place
**Tmod Theory [RECODE!!!]** (placeId `127143595327317`).

This folder holds **scripts only**. Models, parts, UI, sounds, animations and
other instances stay in the place file. Keep the `.rbxl` or the published place
as the source of truth for everything that is not code.

## Layout (Rojo-style)

| Roblox class   | File extension  |
|----------------|-----------------|
| `Script`       | `.server.luau`  |
| `LocalScript`  | `.client.luau`  |
| `ModuleScript` | `.luau`         |

- Each top-level folder is a service (`ReplicatedStorage/`, `ServerScriptService/`, …).
- Below that, the folder path follows the instance hierarchy in the place.
- A script that has script children becomes a folder, and its own source goes in `init.<ext>` inside it.
- Siblings with the same name get `_2`, `_3`, … suffixes, in the order the place lists them.

| Service             | Scripts |
|---------------------|--------:|
| ReplicatedStorage   | 69 |
| Workspace           | 39 |
| ServerScriptService | 33 |
| StarterPlayer       | 28 |
| ServerStorage       | 14 |
| ReplicatedFirst     | 1 |

## Integrity check

`manifest.tsv` lists every exported script: its index, byte length, FNV-1a
32-bit hash and path. The length and hash were computed **inside Studio** from
`Script.Source` at export time.

```bash
python3 tools/verify.py          # check every file
python3 tools/verify.py 74 87    # check specific indices
```

The script ends with `OK 184  BAD 0` when every file matches the place exactly.
After you edit any script, its manifest row will no longer match. That is
expected: the manifest is a snapshot from the export.

## Used, unused and duplicate scripts

The export has been sorted. See [USAGE_REPORT.md](USAGE_REPORT.md) for the full list and the reason for each file.

| Folder | Contents | Count |
|--------|----------|------:|
| service folders (`ReplicatedStorage/`, …) | scripts that run or are required | 123 |
| `_Unused/` | scripts that never run and are never required: empty scripts, ServerStorage backups, unrequired modules, and scripts inside asset templates | 18 |
| `_Duplicates/` | byte-for-byte copies of another script; the first copy stays in its normal place | 43 |

Inside `_Unused/` and `_Duplicates/`, files keep their original path.

In `manifest.tsv` the `path` column gives each file's current location. The `studio_path` column gives where the file came from, `status` says used, unused or duplicate, and `note` gives the reason. Unused and duplicate files are still in the place itself. In particular, the Workspace duplicates are needed there: each door and part runs its own copy.
