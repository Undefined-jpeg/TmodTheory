# Tmod Theory [RECODE!!!] — Script Source

Luau scripts exported from the Roblox place
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

Scripts per service in the original export (before the unused and duplicate files were removed):

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

The script ends with `OK 123  BAD 0` when every kept file matches the place exactly.
After you edit any script, its manifest row will no longer match. That is
expected: the manifest is a snapshot from the export.

## Unused and duplicate scripts removed

This repository keeps only the **123 scripts that are used**. The other 61 have been deleted from the repo:
- 18 scripts that never run and are never required.
- 43 byte-for-byte duplicates.

[USAGE_REPORT.md](USAGE_REPORT.md) lists each removed file and the reason it was removed. The removed files are still in git history at commit `d005069`, under `_Unused/` and `_Duplicates/`. They also still exist in the place itself. In particular, the Workspace duplicates are needed there, because each door and part runs its own copy.

`manifest.tsv` still has all 184 rows. Its columns are:
- `status`: used, unused or duplicate.
- `studio_path`: where the file came from.
- `note`: the reason for its status.

`tools/verify.py` checks only the used rows.
