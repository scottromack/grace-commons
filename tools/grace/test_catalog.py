#!/usr/bin/env python3
"""The catalog (unit `tooling: the catalog`): catalog.py writes one entry per atom and per app from the bond
lines check.py parses, and draws the bond graph that heads library/graph.md."""
import os
import re
import sys
import unittest
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import catalog  # noqa: E402
import check  # noqa: E402

ROOT = Path(HERE).resolve().parents[1]


class Catalog(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = catalog.corpus(ROOT)
        cls.text = catalog.catalog(ROOT, cls.data)

    def test_one_entry_per_atom(self):
        atoms = [p for p in check.pattern_files(ROOT) if p.parent.name == "atoms"]
        entries = re.findall(r"^\*\*\[[^\]]+\]\(\./atoms/([\w-]+)\.md\)\*\*", self.text, re.M)
        self.assertEqual(entries, [p.stem for p in atoms])

    def test_mints_are_key_offers(self):
        self.assertIn("**[Task](./atoms/task.md)**", self.text)
        task = self.text.split("**[Task](./atoms/task.md)**", 1)[1].split("\n**[", 1)[0]
        self.assertIn("Mints task id.", task)
        self.assertIn("Needs key list id; key actor id; journal task events.", task)
        self.assertIn("Offers key task id.", task)

    def test_first_sentence(self):
        page = "## What it is\n\nA [Lease](./lease.md) holds a key. It ends.\n\n## Next\n"
        self.assertEqual(catalog.first_sentence(page), "A Lease holds a key.")
        self.assertEqual(catalog.first_sentence("## Summary\n\nIt asks *who?* Then it answers.\n"), "It asks *who?*")

    def test_app_entry_names_its_bond_instances(self):
        for app in self.data["apps"]:
            self.assertIn(f"(./apps/{app.parent.name}/index.md)", self.text)
        self.assertIn("- Sweep needs key invocation id: met by Durable Intent.", self.text)

    def test_bond_graph_edges(self):
        lines = catalog.bond_graph(ROOT, self.data)
        self.assertIn('  b1_task -->|"list id"| b1_list', lines)
        # an opaque key need (Ordering's) meets every key offer, so it is drawn as no arrow, and said once
        self.assertFalse(any(ln.startswith("  b1_ordering ") and '"opaque"' in ln for ln in lines))
        self.assertTrue(any(ln.startswith("Ordering can order the records of any atom") for ln in lines))

    def test_bond_graph_hubs_are_tags(self):
        v = catalog.bond_layers(self.data)
        hubs = {self.data["titles"][o] for o, _ in v["hubs"]}
        self.assertEqual(hubs, {"Actor Identity", "Event Log"})
        lines = catalog.bond_graph(ROOT, self.data)
        # no arrow points at a hub; the needing atoms carry its word as a tag
        self.assertFalse(any("-->" in ln and ln.rstrip().endswith(("_actor_identity", "_event_log")) for ln in lines))
        self.assertTrue(any(ln.startswith('  b1_task["Task<br/><small>actor id') for ln in lines))

    def test_bond_graph_layers(self):
        v = catalog.bond_layers(self.data)
        by = {self.data["titles"][p]: k for p, k in v["layer"].items()}
        # an atom that needs nothing is layer 0; an atom is one deeper than the deepest atom it needs
        self.assertEqual(by["List"], 0)
        self.assertEqual(by["Task"], 1)
        self.assertEqual(by["Assignment"], 2)
        for p, arrows in v["arrows"].items():
            for q, _ in arrows:
                self.assertGreater(v["layer"][p], v["layer"][q])

    def test_the_page_is_current(self):
        self.assertEqual((ROOT / "library" / "catalog.md").read_text(encoding="utf-8"), self.text)


if __name__ == "__main__":
    unittest.main()
