"""A reader gap as a thing (a part of ir.py; unit `tooling: the Reader in parts, the same IR to the byte`).

A gap is what the reader could not read: its `kind`, the rule and the line it is a gap of, and the slots the sentence is made from (the words it could not read, what it
looked for, where). The sentence is rendered from the template and the slots, and it is the same text the reader has always written, so the document carries the same four
fields (`rule`, `line`, `kind`, `what`) and nothing downstream changes. The slots stay on the object (`gap.slots`) for a test or a count that wants the words and not the sentence.
"""
from __future__ import annotations


class Gap(dict):
    """A dict of the four fields the IR carries, with the template and slots it was rendered from kept beside it (not in the document)."""

    def __init__(self, kind: str, rule: str, line: int, template: str, **slots):
        super().__init__(rule=rule, line=line, kind=kind, what=template.format(**slots))
        self.template, self.slots = template, slots

    def __reduce__(self):      # a copy or a pickle is the dict it renders
        return (dict, (dict(self),))


def gap(kind: str, rule: str, line: int, template: str, **slots) -> Gap:
    return Gap(kind, rule, line, template, **slots)
