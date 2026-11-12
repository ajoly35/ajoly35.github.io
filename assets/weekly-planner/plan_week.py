#!/usr/bin/env python3
"""Weekly planner: Sunday priorities + fixed rhythm -> time blocks.

Deterministic (no LLM, no tokens): Claude's only job on Sunday is to turn what
you say into priorities/<monday>.md, then run this.

  python3 plan_week.py 2026-11-16                 # preview (markdown) + plan-2026-11-16.ics
  python3 plan_week.py 2026-11-16 --apple "Claude plan"
        # push to an Apple Calendar calendar; first deletes this week's events in it,
        # so re-running after a tweak replaces the plan instead of duplicating it.
        # (osascript: must run outside Claude's sandbox; you approve the command.)
"""
import re, sys, subprocess, datetime as dt
from pathlib import Path

HERE = Path(__file__).resolve().parent
DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
SETS = {"daily": DAYS, "weekdays": DAYS[:5], "weekend": DAYS[5:]}
DEEP_AREAS = {"research", "core"}
MIN_BLOCK = 30  # minutes; shorter leftovers become "Open / catch-up"


def hm(s):
    h, m = s.split(":"); return int(h) * 60 + int(m)


def fmt(m):
    return f"{m // 60:02d}:{m % 60:02d}"


def place(day_slots, new):
    """Add slot `new`; it overrides whatever it overlaps (later lines win)."""
    s, e = new["start"], new["end"]
    out = []
    for x in day_slots:
        if x["end"] <= s or x["start"] >= e:
            out.append(x); continue
        if x["start"] < s: out.append({**x, "end": s})
        if x["end"] > e: out.append({**x, "start": e})
    out.append(new)
    day_slots[:] = sorted(out, key=lambda x: x["start"])


def read_template():
    week = {d: [] for d in DAYS}
    for ln in (HERE / "template.txt").read_text().splitlines():
        ln = ln.strip()
        if not ln or ln.startswith("#"): continue
        days, span, kind, title = re.split(r"\s+", ln, maxsplit=3)
        a, b = span.split("-")
        for d in SETS.get(days, days.split(",")):
            place(week[d], {"start": hm(a), "end": hm(b), "kind": kind, "title": title})
    return week


def read_priorities(path):
    prios, events = [], []
    for ln in path.read_text().splitlines():
        m = re.match(r"\s*-\s*\[(\w+)\]\s*(.+)", ln)
        if not m: continue
        area, rest = m.group(1).lower(), m.group(2).strip()
        if area in ("event", "free"):  # free = turn a fixed slot back into a project slot
            e = re.match(r"(\w{3})\w*\s+(\d\d:\d\d)-(\d\d:\d\d)\s*(.*)", rest)
            if e: events.append((e.group(1).lower(), hm(e.group(2)), hm(e.group(3)),
                                 e.group(4) or "Project block", "event" if area == "event" else "project"))
            continue
        what, _, hrs = rest.rpartition("|")
        prios.append({"area": area, "what": what.strip(), "left": float(hrs) * 60})
    return prios, events


def fill(week, prios):
    for d in DAYS:
        deep_today = None
        todo = [x for x in week[d] if x["kind"] in ("deep", "project")]
        while todo:
            x = todo.pop(0)
            if x["end"] - x["start"] < MIN_BLOCK:
                x["title"], x["kind"] = "Buffer", "open"; continue
            pool = [p for p in prios if p["left"] >= MIN_BLOCK]
            if x["kind"] == "deep":
                pool = [p for p in pool if p["area"] in DEEP_AREAS]
            elif deep_today:  # variety: afternoon goes to something else if possible
                pool = [p for p in pool if p is not deep_today] or pool
            if not pool:
                x["title"] = "Open / catch-up"; x["kind"] = "open"; continue
            p = pool[0]
            length = x["end"] - x["start"]
            use = min(length, int(p["left"] // 30 * 30))
            p["left"] -= use
            if x["kind"] == "deep": deep_today = p
            label = "Deep work" if x["kind"] == "deep" else "Block"
            if use < length:  # leftover goes back in the queue for the next priority
                rest = {"start": x["start"] + use, "end": x["end"], "kind": x["kind"], "title": x["title"]}
                week[d].append(rest); todo.insert(0, rest)
                x["end"] = x["start"] + use
            x["kind"] = "filled"
            x["title"] = f"{label} [{p['area']}]: {p['what']}"
        week[d].sort(key=lambda x: x["start"])


def build(monday, only=None):
    pfile = HERE / "priorities" / f"{monday}.md"
    if not pfile.exists(): sys.exit(f"no priorities file: {pfile}")
    week = read_template()
    if only:  # plan some days only (e.g. a mid-week start): blank the rest BEFORE filling
        for d in DAYS:
            if d not in only: week[d] = []
    prios, events = read_priorities(pfile)
    for d, a, b, t, k in events:
        place(week[d], {"start": a, "end": b, "kind": k, "title": t})
    fill(week, prios)
    return week, prios


def dates(monday):
    m = dt.date.fromisoformat(monday)
    return {d: m + dt.timedelta(i) for i, d in enumerate(DAYS)}


def preview(week, prios, monday):
    ds = dates(monday)
    out = [f"# Plan, week of {monday}\n"]
    for d in DAYS:
        out.append(f"\n## {d.capitalize()} {ds[d]:%d %b}\n\n| Time | Block |\n|---|---|")
        out += [f"| {fmt(x['start'])}–{fmt(x['end'])} | {x['title']} |" for x in week[d]]
    free = sum(x["end"] - x["start"] for d in DAYS for x in week[d] if x["kind"] == "open") / 60
    out.append(f"\n## Capacity\n\n{free:g} h of work slots left open this week.")
    out.append("\n## Hours not placed (move a priority up or cut it)\n")
    short = [f"- [{p['area']}] {p['what']}: {p['left'] / 60:g} h" for p in prios if p["left"] > 0]
    out += short or ["- none: every priority fits"]
    return "\n".join(out)


def ics(week, monday):
    ds, now = dates(monday), dt.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    L = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//claude-kit//weekly-planner//EN"]
    for d in DAYS:
        for i, x in enumerate(week[d]):
            day = ds[d].strftime("%Y%m%d")
            L += ["BEGIN:VEVENT", f"UID:claude-plan-{day}-{i}@local", f"DTSTAMP:{now}",
                  f"DTSTART;TZID=Europe/London:{day}T{fmt(x['start']).replace(':', '')}00",
                  f"DTEND;TZID=Europe/London:{day}T{fmt(x['end']).replace(':', '')}00",
                  "SUMMARY:" + x["title"].replace(",", "\\,"), "END:VEVENT"]
    return "\r\n".join(L + ["END:VCALENDAR"]) + "\r\n"


def push_apple(week, monday, cal):
    ds = dates(monday)
    def d_expr(var, day, minutes):
        return (f'set {var} to current date\nset year of {var} to {day.year}\nset month of {var} to {day.month}\n'
                f'set day of {var} to {day.day}\nset time of {var} to {minutes * 60}\n')
    q = lambda s: s.replace("\\", "\\\\").replace('"', '\\"')
    sc = [f'tell application "Calendar"\ntell calendar "{q(cal)}"']
    for d in DAYS:  # replace only the days being planned
        if not week[d]: continue
        sc += [d_expr("w0", ds[d], 0), d_expr("w1", ds[d], 24 * 60 - 1),
               "delete (every event whose start date ≥ w0 and start date ≤ w1)"]
    for d in DAYS:
        for x in week[d]:
            sc += [d_expr("s", ds[d], x["start"]), d_expr("e", ds[d], x["end"]),
                   f'make new event with properties {{summary:"{q(x["title"])}", start date:s, end date:e}}']
    sc.append("end tell\nend tell")
    subprocess.run(["osascript", "-"], input="\n".join(sc), text=True, check=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args: sys.exit(__doc__)
    monday = args[0]
    only = args[args.index("--only") + 1].split(",") if "--only" in args else None
    week, prios = build(monday, only)
    md = preview(week, prios, monday)
    (HERE / f"plan-{monday}.md").write_text(md)
    (HERE / f"plan-{monday}.ics").write_text(ics(week, monday))
    print(md)
    if "--apple" in args:
        push_apple(week, monday, args[args.index("--apple") + 1])
        print(f"\npushed to Apple Calendar: {args[args.index('--apple') + 1]}")
