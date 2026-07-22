# aowljson — a small, self-contained JSON value type for Nimony

`aowljson` is a plain, ergonomic JSON library for **Nimony**: a reference
`JsonValue` tree with a recursive-descent parser, a compact serializer, safe
nested access, and value builders. No dependencies beyond Nimony's `std/strutils`.

## Why not `std/json`?

Nimony ships a NIF-backed `std/json`, but its document is **move-only** and only
exposes **root-level** key lookup — awkward to thread through an ordinary API
where you want `req{"params"}{"name"}.getStr("")`. `aowljson` owns a normal
`ref` value tree instead, so JSON reads and builds the way you'd expect.

In keeping with the aoughwl stack: **errors are values, never exceptions.**
`parseJson` reports failure through an `err` out-parameter; nothing raises.

## Build / test

Requires the Nimony compiler (`~/nimony/bin/nimony`). No external dependency.

```sh
git clone https://github.com/aoughwl/aowljson
cd aowljson
./build.sh            # runs tests/tjson.nim
```

Point elsewhere with `NIMONY=/path/to/nimony ./build.sh`.

## Use it

```nim
import aowljson

var err = ""
let v = parseJson("""{"user":{"name":"ada"},"tags":["x","y"]}""", err)
assert err.len == 0

echo v{"user"}{"name"}.getStr("")     # ada  — missing paths chain to null safely
echo v{"tags"}.at(0).getStr           # x
echo v{"nope"}{"deep"}.getStr("fb")   # fb   — no fault, no nil check

let o = newJObject()
o["ok"] = newJBool(true)
o["n"] = newJInt(42)
let a = newJArray(); a.add(newJString("z")); o["items"] = a
echo $o                                # {"ok":true,"n":42,"items":["z"]}
```

## API

| Group | API |
|---|---|
| parse | `parseJson(s, err): JsonValue` — error by value, never raised |
| serialize | `$v` — compact; numbers round-trip by their source lexeme |
| navigate | `v{"key"}` (object), `v.at(i)` (array) — missing paths yield a JNull |
| read | `getStr`, `getInt`, `getBool`, `len`, `hasKey`, `isNull`, `items`, `pairs` |
| build | `newJObject`, `newJArray`, `newJString`, `newJInt`, `newJBool`, `newJNull`, `newJRawNumber`, `obj["k"] = v`, `arr.add v` |

`JsonValue` is a `ref object` variant over `jnNull / jnBool / jnNumber / jnString
/ jnArray / jnObject`. Numbers are stored as their source lexeme, so any JSON
number re-serializes byte-for-byte; `getInt` decodes on demand. Object members
keep insertion order.

## Layout

```
src/aowljson.nim     the library (import this)
tests/tjson.nim      round-trip, nested access, builders, unicode-escape tests
```

## Used by

- [aowlmcp](https://github.com/aoughwl/aowlmcp) — MCP servers in Nimony.

## Licence

See [LICENSE](LICENSE).
