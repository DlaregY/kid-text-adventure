"""Finite-state story audit; no Godot, network, or player save writes.

Repeated commands can produce infinitely many play sequences. This checks every
reachable (scene, inventory, flags) state using available tiles, first eligible
rules and the same inventory/flag effects as Game.gd. UI/gesture behavior is not
modeled. Unknown requirement/effect types fail instead of silently passing.
"""
from __future__ import annotations
from collections import defaultdict, deque
from dataclasses import dataclass
import json
from pathlib import Path

STORIES = Path(__file__).resolve().parents[1] / "stories"
ACTIONS = frozenset({"go", "open", "take", "look", "talk", "give", "climb", "tell"})

@dataclass(frozen=True)
class State:
    scene: str
    inventory: frozenset[str] = frozenset()
    flags: frozenset[str] = frozenset()


def fits_slots(state: State, command: tuple[str, str]) -> bool:
    """Player input: action/held item first; non-action target/held item second."""
    return (len(command) == 2 and command[0] in (ACTIONS | state.inventory)
            and command[1] not in ACTIONS)


def apply(story: dict, state: State, command: tuple[str, str]) -> State:
    scene = story["scenes"][state.scene]
    available = set(scene["tiles"]) | state.inventory
    if not set(command) <= available:
        raise ValueError(f"Unavailable tiles at {state.scene}: {command}")
    if not fits_slots(state, command):
        raise ValueError(f"Invalid slot roles at {state.scene}: {command}")
    for rule in scene["commands"]:
        if tuple(rule["pattern"]) != command:
            continue
        req = rule.get("requirements", {})
        if set(req) - {"inventory_has", "flags_true"}:
            raise ValueError(f"Unmodeled requirements: {req}")
        if not set(req.get("inventory_has", [])) <= state.inventory:
            continue
        if not set(req.get("flags_true", [])) <= state.flags:
            continue
        eff = rule.get("effects", {})
        if set(eff) - {"inventory_add", "inventory_remove", "flags_set"}:
            raise ValueError(f"Unmodeled effects: {eff}")
        inventory = (state.inventory | frozenset(eff.get("inventory_add", []))) - frozenset(eff.get("inventory_remove", []))
        flags = set(state.flags)
        for key, value in eff.get("flags_set", {}).items():
            if type(value) is not bool:
                raise ValueError(f"Non-boolean flag: {key}")
            if value:
                flags.add(key)
            else:
                flags.discard(key)
        return State(rule.get("next", state.scene), frozenset(inventory), frozenset(flags))
    return state


def audit(story: dict, max_states: int = 50000) -> dict:
    start = State(story["start_scene"])
    previous = {start: None}
    reverse: dict[State, set[State]] = defaultdict(set)
    queue = deque([start])
    scenes = story["scenes"]
    # Current story schema supports only positive flag requirements; omitted and
    # false flags are behaviorally equivalent, hence flags are a set of true keys.
    while queue:
        state = queue.popleft()
        available = set(scenes[state.scene]["tiles"]) | state.inventory
        patterns = {tuple(rule["pattern"]) for rule in scenes[state.scene]["commands"]}
        for command in sorted(patterns):
            if len(command) != 2:
                raise ValueError("Expected two-token story command")
            if not set(command) <= available or not fits_slots(state, command):
                continue
            nxt = apply(story, state, command)
            reverse[nxt].add(state)
            if nxt not in previous:
                if len(previous) >= max_states:
                    raise ValueError("Story search exceeded its state budget")
                previous[nxt] = (state, command)
                queue.append(nxt)
    terminals = {state for state in previous if not any("next" in r for r in scenes[state.scene]["commands"])}
    good = set(terminals)
    queue = deque(terminals)
    while queue:
        for parent in reverse[queue.popleft()]:
            if parent not in good:
                good.add(parent)
                queue.append(parent)
    witnesses = {}
    for state in previous:
        if state.scene in witnesses:
            continue
        cursor, path = state, []
        while previous[cursor] is not None:
            cursor, command = previous[cursor]
            path.append(command)
        witnesses[state.scene] = list(reversed(path))
    return {
        "states": len(previous),
        "scenes": len(witnesses),
        "endings": sorted({scenes[s.scene]["ending"]["id"] for s in terminals}),
        "dead_states": len(previous.keys() - good),
        "unreachable_scenes": sorted(set(scenes) - set(witnesses)),
        "witnesses": witnesses,
    }


if __name__ == "__main__":
    results = {p.name: audit(json.loads(p.read_text(encoding="utf-8"))) for p in sorted(STORIES.glob("*.json"))}
    print(json.dumps(results, ensure_ascii=False, indent=2))
    raise SystemExit(int(any(r["dead_states"] or r["unreachable_scenes"] for r in results.values())))
