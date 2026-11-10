#!/usr/bin/env python3
"""
benchmark.py - runs every query in a .sql file 5 times with
EXPLAIN (ANALYZE, BUFFERS), keeps the MEDIAN execution time and the plan
of the last run.

Usage:
    python3 benchmark.py baseline_queries.sql baseline_results.json
    python3 benchmark.py optimized_queries.sql optimized_results.json
"""
import json
import re
import statistics
import subprocess
import sys

DB = "retail"
RUNS = 5


def parse_queries(path):
    text = open(path).read()
    parts = re.split(r"^-- (Q\d+): (.*)$", text, flags=re.M)
    queries = []
    for i in range(1, len(parts), 3):
        qid, title, body = parts[i], parts[i + 1], parts[i + 2]
        sql = "\n".join(l for l in body.splitlines() if not l.strip().startswith("-- =")).strip()
        queries.append({"id": qid, "title": title.strip(), "sql": sql})
    return queries


def explain(sql):
    stmt = "EXPLAIN (ANALYZE, BUFFERS) " + sql
    out = subprocess.run(
        ["psql", "-d", DB, "-X", "-A", "-t", "-c", stmt],
        capture_output=True, text=True, check=True,
    ).stdout
    m = re.search(r"Execution Time: ([\d.]+) ms", out)
    return float(m.group(1)), out.strip()


def main(sql_file, out_file):
    results = []
    for q in parse_queries(sql_file):
        explain(q["sql"])  # warm-up run (not counted)
        times, plan = [], ""
        for _ in range(RUNS):
            t, plan = explain(q["sql"])
            times.append(t)
        results.append({
            "id": q["id"],
            "title": q["title"],
            "sql": q["sql"],
            "median_ms": round(statistics.median(times), 3),
            "min_ms": round(min(times), 3),
            "max_ms": round(max(times), 3),
            "runs": times,
            "plan": plan,
        })
        print(f'{q["id"]}: median {results[-1]["median_ms"]} ms  ({q["title"]})')
    json.dump(results, open(out_file, "w"), indent=2)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
