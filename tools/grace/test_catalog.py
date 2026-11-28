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
        entries = re.findall(r"^\*\*\[[^\]]+\]\(\./atoms/([\w-]+)\.(?:md|idd)\)\*\*", self.text, re.M)
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
        # unit `atoms: held references are key needs, the batch`: the sentence names every atom that holds one
        said = [ln for ln in lines if "a key need typed opaque, which any atom that offers a key meets" in ln]
        self.assertEqual(len(said), 1)
        for name in ("Category", "Comment", "Favorite", "Notification", "Ordering", "Reaction", "Tag"):
            self.assertIn(name, said[0])

    def test_bond_graph_hubs_are_tags(self):
        v = catalog.bond_layers(self.data)
        hubs = {self.data["titles"][o] for o, _ in v["hubs"]}
        self.assertEqual(hubs, {"Actor Identity", "Event Log"})
        lines = catalog.bond_graph(ROOT, self.data)
        # no arrow points at a hub; the needing atoms carry its word as a tag
        self.assertFalse(any("-->" in ln and ln.rstrip().endswith(("_actor_identity", "_event_log")) for ln in lines))
        self.assertTrue(any(ln.startswith('  b1_task["Task<br/><small>actor id') for ln in lines))

    def test_bond_graph_leaves_out_stand_alones(self):
        v = catalog.bond_layers(self.data)
        lines = catalog.bond_graph(ROOT, self.data)
        page = "\n".join(lines)
        alone = {self.data["titles"][p] for p in v["alone"]}
        # an atom that needs nothing and that nothing needs (hub tags aside) is neither drawn nor listed
        self.assertIn("Money", alone)
        self.assertNotIn("(./atoms/money.md)", page)
        self.assertFalse(any(ln.lstrip().startswith("b0_money") for ln in lines))
        # layer 0 holds only foundations: atoms some drawn atom's arrow reaches
        reached = {q for p in v["drawn"] for q, _ in v["arrows"][p]}
        for p in v["drawn"]:
            if v["layer"][p] == 0:
                self.assertIn(p, reached)

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


class Connections(unittest.TestCase):
    """An app's connector diagram (unit `site: an app's connector diagram, generated — the to-do app first`,
    Scott 2026-11-27): drawn from the bond lines, never by hand."""

    def test_fixture_with_an_instance_and_a_glue_tag(self):
        aye, bee, cee, hub = (Path(f"/x/library/atoms/{n}.md") for n in ("aye", "bee", "cee", "hub"))

        def b(path, side, kind, line, **fields):
            return {"path": path, "side": side, "kind": kind, "line": line, "fields": fields}
        aye_task, cee_list, hub_actor = b(aye, "offer", "key", 9, key="task id"), b(cee, "offer", "key", 9, key="list id"), \
            b(hub, "offer", "key", 9, key="actor id")
        aye_needs_actor = b(aye, "need", "key", 5, key="actor id")
        bee_opaque, bee_list = b(bee, "need", "key", 5, key="opaque"), b(bee, "need", "key", 6, key="list id")
        lines = {aye: [aye_needs_actor, aye_task], bee: [bee_opaque, bee_list], cee: [cee_list], hub: [hub_actor]}
        meets = {(aye, 5): [hub_actor], (bee, 5): [aye_task, cee_list, hub_actor], (bee, 6): [cee_list]}
        titles = {aye: "Aye", bee: "Bee", cee: "Cee", hub: "Hub"}
        text = ("## Bonds\n\n```\nBond instance 1: Bee's key need that pairs entries MUST be served by Aye's key offer "
                "of task id (Bonds Bond 7).\n```\n\n## Glue\n\n```\nclaim: claim MUST be Bee's Assign whose assignee "
                "is the caller. {birth: bond candidate}\nlink: Aye's Add MUST be followed by Cee's Grant. "
                "{birth: bond candidate}\n```\n\n## Actions\n")
        c = catalog.app_connections(text, [aye, bee, cee, hub], lines, meets, titles, {(hub, 9)})
        c["own"] = []
        page = catalog.render_connections(c, "Fixture")
        # the one key need met by one plain offer is an arrow; the hub's is a tag; the ambiguous need is the instance's
        self.assertIn('  c_bee -->|"list id"| c_cee', page)
        self.assertIn('  c_aye["Aye<br/><small>actor id</small>"]', page)
        self.assertIn('  c_bee -->|"instance 1: task id"| c_aye', page)
        self.assertIn("  linkStyle 1 stroke:#e8a33d", page)
        # a glue line naming one atom is a tag on it; one naming two is a dashed arrow from the first
        self.assertIn('  c_bee["Bee<br/><small>glue: claim (bond candidate)</small>"]', page)
        self.assertIn('  c_aye -.->|"glue: link<br/>bond candidate"| c_cee', page)
        # the headline, the diagram's first line: the atoms used, and the instance and glue lines written
        self.assertIn("```mermaid\n---\ntitle: atomic weight 4 · lines written 3\n---\n", page)
        self.assertIn("**3 bonds**: 1 key arrow, 1 tag (actor id 1), and 1 bond instance. **2 glue lines**, which are "
                      "not bonds: claim, link.", page)
        self.assertIn("| Bee | — | glue | claim (bond candidate) | tag |", page)

    def test_the_todo_app_reproduces_its_hand_tally(self):
        page = catalog.connections_page(ROOT / "library" / "apps" / "todo" / "index.md", catalog.corpus(ROOT))
        # unit `bonds: the follow-up bond kind, accept grants first` (2026-11-27): accept grants left the glue as the
        # follow-up bond, Permissions' Grant after Invitation's Accept, a green arrow
        # unit `composition: Login dissolved, the first dissolve` (2026-11-28): sign in left the glue as a follow-up
        # bond, Session's Issue after Credential's Verify, and Session pairs on Credential's credential id
        self.assertIn("**18 bonds**: 2 follow-up arrows, 5 key arrows, 10 tags (actor id 7, journal 3), and 1 bond instance. "
                      "**1 glue line**, which is not a bond: claim.", page)
        self.assertIn('  c_permissions -->|"follow-up: Grant after Accept"| c_invitation', page)
        self.assertIn('  c_session -->|"follow-up: Issue after Verify"| c_credential', page)
        self.assertIn('  c_session -->|"credential id"| c_credential', page)
        self.assertIn("- **Green arrow:**", page)
        self.assertIn('  c_ordering -->|"instance 1: task id"| c_task', page)
        self.assertIn("title: atomic weight 10 · lines written 2", page)
        self.assertNotIn("glue: sign in", page)

    def test_every_app_gets_one_and_glue_naming_no_atom_is_listed(self):
        # Scott 2026-11-27 11:25 AM Central: "yes every app"
        apps = sorted(p.parent.name for p in (ROOT / "library" / "apps").glob("*/index.md"))
        self.assertEqual(sorted(catalog.CONNECTOR_APPS), apps)
        page = catalog.connections_page(ROOT / "library" / "apps" / "recoverable-invocation" / "index.md",
                                        catalog.corpus(ROOT))
        self.assertIn('  c_sweep -->|"critical section key"| c_lease', page)
        self.assertIn("| — | — | glue | commit 1 (", page)
        self.assertIn(") | not drawn: names no atom |", page)


if __name__ == "__main__":
    unittest.main()
