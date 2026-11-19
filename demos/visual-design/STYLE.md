# Grace render style

Feel: a calm expert in the room. Clarity over ornament.
Never busy, decorative, loud or playful.

Colour    INKs only (light and dark follow the device). No screen names a colour.
          Hierarchy by opacity, not by extra colours.
Type      Tailwind defaults. At most 3 sizes per screen.
          Page title text-3xl tracking-tight · section text-xl · body text-base leading-7
          Muted lines (descriptions, meta) at reduced opacity.
Spacing   8-point rhythm: gap-2/4/6/8, stacks space-y-4/6/8.
          Sections py-16; the page head py-12. Add space before adding styling.
Width     Shell max-w-7xl mx-auto px-6; reading text max-w-3xl.
Shell     One top bar on every signed-in screen: product name left,
          the menu centre, the person's name and Sign out right. Hairline under it.
Surfaces  Every card, table, form and result sits on .raised (INKs):
          hairline border, p-10, faint gradient, light blur. No shadows.
          .raised inside .raised gets the stronger sage border.
          Tables and lists: .raised rounded overflow-hidden p-0, rows edge to edge.
Cards     Dashboard tiles: .raised rounded-lg in a gap-6 grid, title + one muted
          line saying what's inside; hover adds shadow-sm.
Results   Pass and fail panels: .raised with a green or red border, nothing louder.
Tables    Hairline rows, no zebra, header in muted small caps.
Buttons   Primary px-6 py-3 text-base font-medium rounded-lg; secondary px-4 py-2 text-sm.
          No pills.
Forms     Label above field, one column, max-w-md.
Rules     Prefer whitespace over borders. Consistency beats precision.

Source: Scott's Cognatix type and spacing system (demos/multi-party-approval/VisualDesignSystem.md)
and the .raised surface of inkset.css, as the Next render of Beacon uses them. Scott, 2026-11-19.
