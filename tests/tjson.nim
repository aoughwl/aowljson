import std/[syncio, assertions]
import "../src/aowljson"

proc rt(s: string): string =
  var err = ""
  let v = parseJson(s, err)
  assert err.len == 0, "parse error: " & err & " for " & s
  result = $v

# round-trips (compact, key order preserved)
assert rt("""{"a":1,"b":[true,false,null],"c":"hi"}""") ==
       """{"a":1,"b":[true,false,null],"c":"hi"}"""
assert rt("[]") == "[]"
assert rt("{}") == "{}"
assert rt("""  {  "x" : 42 }  """) == """{"x":42}"""
assert rt("\"a\\nb\"") == "\"a\\nb\""
assert rt("-12.5e3") == "-12.5e3"

# nested access
var err = ""
let req = parseJson("""{"method":"tools/call","id":7,"params":{"name":"greet","arguments":{"who":"world"}}}""", err)
assert err.len == 0
assert req{"method"}.getStr == "tools/call"
assert req{"id"}.getInt == 7
assert req{"params"}{"name"}.getStr == "greet"
assert req{"params"}{"arguments"}{"who"}.getStr == "world"
# missing keys chain to null safely
assert req{"nope"}{"deep"}.getStr("fallback") == "fallback"
assert req{"nope"}.isNull

# builders
let o = newJObject()
o["jsonrpc"] = newJString("2.0")
o["id"] = newJInt(7)
let arr = newJArray()
arr.add(newJString("x"))
arr.add(newJBool(true))
o["items"] = arr
assert $o == """{"jsonrpc":"2.0","id":7,"items":["x",true]}"""

# error surfacing
var e2 = ""
discard parseJson("{bad}", e2)
assert e2.len > 0

# unicode escape decode
assert rt("\"\\u0041\\u00e9\"") == "\"Aé\""

echo "aowljson: OK"

# --- absence is nil, and every accessor tolerates nil -----------------------
# The bug this pins: `{}` used to hand back a fresh JNull for a key that is NOT
# THERE, so `!= nil` -- the presence test everyone writes -- was always true and
# never fired. A Telegram bridge used it to tell a button tap from a chat
# message, took the button branch on every message, and silently answered
# nothing.
assert req{"nope"} == nil, "a MISSING key must be nil, not a JNull"
assert req{"params"} != nil, "a PRESENT key must not be nil"
assert not (req{"params"} == nil)

# ...and chain safety is still paid for, just in the accessors instead.
assert req{"a"}{"b"}{"c"} == nil
assert req{"a"}{"b"}.getStr("d") == "d"
assert req{"a"}.getInt(9) == 9
assert req{"a"}.getBool(true) == true
assert req{"a"}.len == 0
assert req{"a"}.hasKey("x") == false
assert req{"a"}.at(0) == nil
assert req{"a"}.isNull, "nil reads as 'no value here'"
assert req{"a"}.kindOf == jnNull
var n = 0
for _ in req{"a"}: inc n
assert n == 0, "iterating an absent array must yield nothing, not fault"
for _, _ in req{"a"}: inc n
assert n == 0

# an explicit JSON null is PRESENT -- `== nil` is what tells them apart
let withNull = parseJson("""{"k":null}""", err)
assert err.len == 0
assert withNull{"k"} != nil, "an explicit null is present"
assert withNull{"k"}.isNull
assert withNull{"nope"} == nil
assert withNull.hasKey("k") and not withNull.hasKey("nope")

# building with an absent value must not fault, and serialises as null
let obj = newJObject()
obj["here"] = newJString("x")
obj["gone"] = req{"nope"}          # nil
assert $obj == """{"here":"x","gone":null}"""
let arr2 = newJArray()
arr2.add req{"nope"}
assert $arr2 == "[null]"
# add/[]= on a non-container are no-ops rather than faults
req{"nope"}.add newJInt(1)
req{"nope"}["k"] = newJInt(1)

echo "tjson: all assertions passed"
