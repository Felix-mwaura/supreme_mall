#!/usr/bin/env python3
"""Export the project's Markdown decision records to Word (.docx) and PDF.

Why this exists: the specs in `docs/` are reviewed by people who want to read
them offline, mark them up in Word, or forward a PDF. The Markdown stays the
source of truth; these are generated copies.

Setup (once, in a throwaway venv):

    python3 -m venv /tmp/venv
    /tmp/venv/bin/pip install python-docx reportlab
    /tmp/venv/bin/python tools/export_doc.py docs/<file>.md docs/<file>.docx docs/<file>.pdf

The PDF uses the DejaVu fonts that ship with most Linux distributions
(/usr/share/fonts/truetype/dejavu) because they cover the arrows and symbols the
documents use. On another platform, point `font_dir` at any Unicode TTF set.

Supported Markdown: headings, paragraphs with **bold** / *italic* / `code` /
[links](url), bullet and numbered lists (including wrapped continuation lines),
checkbox items, pipe tables, fenced code blocks, blockquotes, horizontal rules.
"""

import re
import sys
from pathlib import Path

# --------------------------------------------------------------------------- #
# Parsing
# --------------------------------------------------------------------------- #

INLINE = re.compile(r"(\*\*.+?\*\*|\*[^*\n]+?\*|`[^`\n]+?`|\[[^\]\n]+\]\([^)\n]+\))")


def inline_tokens(text):
    """Split a line into (text, {bold|italic|code|link}) tokens."""
    out = []
    for part in INLINE.split(text):
        if not part:
            continue
        if part.startswith("**") and part.endswith("**") and len(part) > 4:
            out.append((part[2:-2], {"bold": True}))
        elif part.startswith("`") and part.endswith("`") and len(part) > 2:
            out.append((part[1:-1], {"code": True}))
        elif part.startswith("[") and part.endswith(")") and "](" in part:
            m = re.match(r"\[([^\]]+)\]\(([^)]+)\)", part)
            if m:
                out.append((m.group(1), {"link": m.group(2)}))
            else:
                out.append((part, {}))
        elif part.startswith("*") and part.endswith("*") and len(part) > 2:
            out.append((part[1:-1], {"italic": True}))
        else:
            out.append((part, {}))
    return out


def plain(text):
    """Inline text with the markup stripped (for widths / cell values)."""
    return "".join(t for t, _ in inline_tokens(text))


def split_row(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in line.split("|")]


def parse(md_text):
    blocks = []
    lines = md_text.split("\n")
    i = 0
    n = len(lines)

    while i < n:
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        # fenced code
        if stripped.startswith("```"):
            i += 1
            code = []
            while i < n and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            i += 1
            blocks.append(("code", code))
            continue

        # horizontal rule
        if re.fullmatch(r"-{3,}", stripped):
            blocks.append(("hr", None))
            i += 1
            continue

        # headings
        m = re.match(r"(#{1,4})\s+(.*)$", stripped)
        if m:
            level = len(m.group(1))
            blocks.append((f"h{level}", m.group(2).strip()))
            i += 1
            continue

        # table
        if stripped.startswith("|") and i + 1 < n and re.fullmatch(
            r"\|[\s:\-|]+\|?", lines[i + 1].strip()
        ):
            header = split_row(stripped)
            i += 2
            rows = []
            while i < n and lines[i].strip().startswith("|"):
                rows.append(split_row(lines[i]))
                i += 1
            blocks.append(("table", (header, rows)))
            continue

        # blockquote
        if stripped.startswith(">"):
            quote = []
            while i < n and lines[i].strip().startswith(">"):
                quote.append(lines[i].strip().lstrip(">").strip())
                i += 1
            blocks.append(("quote", " ".join(q for q in quote if q)))
            continue

        # lists (bullet / numbered / checkbox)
        if re.match(r"^\s*([-*]|\d+\.)\s+", line):
            items = []
            ordered = bool(re.match(r"^\s*\d+\.\s+", line))
            while i < n:
                m = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)$", lines[i])
                if not m:
                    break
                indent = len(m.group(1))
                level = min(indent // 2, 2)
                body = m.group(3).strip()
                i += 1
                # a wrapped paragraph continues the same item
                cont = []
                while i < n:
                    nxt = lines[i]
                    if not nxt.strip():
                        break
                    if re.match(r"^(\s*)([-*]|\d+\.)\s+", nxt):
                        break
                    if re.match(r"^\s*(#{1,4}\s|>|\||```)", nxt):
                        break
                    if re.fullmatch(r"-{3,}", nxt.strip()):
                        break
                    if len(nxt) - len(nxt.lstrip(" ")) == 0:
                        break
                    cont.append(nxt.strip())
                    i += 1
                if cont:
                    body = " ".join([body] + cont)
                checked = None
                cm = re.match(r"^\[( |x|X)\]\s*(.*)$", body)
                if cm:
                    checked = cm.group(1).lower() == "x"
                    body = cm.group(2)
                items.append({"level": level, "text": body, "checked": checked})
            blocks.append(("ol" if ordered else "ul", items))
            continue

        # paragraph (gather wrapped lines)
        para = [stripped]
        i += 1
        while i < n and lines[i].strip() and not re.match(
            r"^\s*(#{1,4}\s|[-*]\s|\d+\.\s|>|\||```)", lines[i]
        ) and not re.fullmatch(r"-{3,}", lines[i].strip()):
            para.append(lines[i].strip())
            i += 1
        blocks.append(("p", " ".join(para)))

    return blocks



def column_widths_cm(total_cm, weights, min_cm=2.5):
    """Give every column a readable minimum, then share the rest by weight."""
    n = len(weights)
    base = min(min_cm, total_cm / max(n, 1))
    spare = max(total_cm - base * n, 0.0)
    total_weight = sum(weights) or 1
    return [base + spare * w / total_weight for w in weights]


# --------------------------------------------------------------------------- #
# DOCX
# --------------------------------------------------------------------------- #

NAVY = (0x0B, 0x2D, 0x5B)
GOLD = (0xB0, 0x84, 0x0F)
INK = (0x1F, 0x29, 0x37)
MUTED = (0x5B, 0x66, 0x77)
RULE = "D8DEE6"
CODE_BG = "F3F4F6"
HEAD_BG = "0B2D5B"
ZEBRA = "F5F7FA"

BASE_FONT = "Calibri"
MONO_FONT = "Consolas"
CONTENT_CM = 17.0


def docx_export(blocks, out_path, source_name, title_text):
    from docx import Document
    from docx.enum.section import WD_SECTION
    from docx.enum.table import WD_TABLE_ALIGNMENT
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.oxml import OxmlElement
    from docx.oxml.ns import qn
    from docx.shared import Cm, Pt, RGBColor

    document = Document()

    # page setup
    for section in document.sections:
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)
        section.top_margin = Cm(2.0)
        section.bottom_margin = Cm(1.8)
        section.left_margin = Cm(2.0)
        section.right_margin = Cm(2.0)

    # base style
    normal = document.styles["Normal"]
    normal.font.name = BASE_FONT
    normal.font.size = Pt(10.5)
    normal.font.color.rgb = RGBColor(*INK)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.15
    rpr = normal.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        rfonts.set(qn(attr), BASE_FONT)

    def shade(el, fill):
        pr = el.get_or_add_pPr() if hasattr(el, "get_or_add_pPr") else el
        shd = OxmlElement("w:shd")
        shd.set(qn("w:val"), "clear")
        shd.set(qn("w:color"), "auto")
        shd.set(qn("w:fill"), fill)
        pr.append(shd)

    def rule_below(paragraph, color=RULE, size=6):
        ppr = paragraph._p.get_or_add_pPr()
        borders = OxmlElement("w:pBdr")
        bottom = OxmlElement("w:bottom")
        bottom.set(qn("w:val"), "single")
        bottom.set(qn("w:sz"), str(size))
        bottom.set(qn("w:space"), "4")
        bottom.set(qn("w:color"), color)
        borders.append(bottom)
        ppr.append(borders)

    def add_runs(paragraph, text, size=None, color=None, mono_for_code=True):
        for chunk, attrs in inline_tokens(text):
            run = paragraph.add_run(chunk)
            if size:
                run.font.size = Pt(size)
            if color:
                run.font.color.rgb = RGBColor(*color)
            if attrs.get("bold"):
                run.bold = True
            if attrs.get("italic"):
                run.italic = True
            if attrs.get("code") and mono_for_code:
                run.font.name = MONO_FONT
                run.font.size = Pt((size or 10.5) - 1)
                run.font.color.rgb = RGBColor(0x8A, 0x4B, 0x08)
            if attrs.get("link"):
                run.font.color.rgb = RGBColor(0x1D, 0x4E, 0xD8)
                run.underline = True
        return paragraph

    # markdown level -> built-in Word style, so the navigation pane and an
    # automatic table of contents both work in Word
    WORD_STYLE = {1: "Title", 2: "Heading 1", 3: "Heading 2", 4: "Heading 3"}

    def heading(text, level):
        sizes = {1: 21, 2: 15, 3: 12, 4: 11}
        colors = {1: NAVY, 2: NAVY, 3: GOLD, 4: MUTED}
        try:
            p = document.add_paragraph(style=WORD_STYLE.get(level, "Heading 3"))
        except KeyError:
            p = document.add_paragraph()
        p.paragraph_format.space_before = Pt(16 if level <= 2 else 11)
        p.paragraph_format.space_after = Pt(6 if level <= 2 else 4)
        p.paragraph_format.keep_with_next = True
        add_runs(p, text, size=sizes[level], color=colors[level])
        for run in p.runs:
            run.bold = True
        if level == 2:
            rule_below(p, color="E3B94A", size=8)
        return p

    first_heading = True

    for kind, payload in blocks:
        if kind == "h1":
            if not first_heading:
                document.add_page_break()
            first_heading = False
            heading(payload, 1)
        elif kind == "h2":
            heading(payload, 2)
        elif kind == "h3":
            heading(payload, 3)
        elif kind == "h4":
            heading(payload, 4)
        elif kind == "p":
            p = document.add_paragraph()
            p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
            add_runs(p, payload)
        elif kind == "quote":
            p = document.add_paragraph()
            p.paragraph_format.left_indent = Cm(0.5)
            p.paragraph_format.right_indent = Cm(0.3)
            p.paragraph_format.space_before = Pt(6)
            p.paragraph_format.space_after = Pt(10)
            shade(p._p, "F7F8FA")
            add_runs(p, payload, size=10, color=MUTED)
            for run in p.runs:
                run.italic = True
        elif kind == "code":
            p = document.add_paragraph()
            p.paragraph_format.left_indent = Cm(0.35)
            p.paragraph_format.space_before = Pt(4)
            p.paragraph_format.space_after = Pt(10)
            p.paragraph_format.line_spacing = 1.0
            shade(p._p, CODE_BG)
            for idx, code_line in enumerate(payload):
                run = p.add_run(code_line if code_line else " ")
                run.font.name = MONO_FONT
                run.font.size = Pt(8.5)
                run.font.color.rgb = RGBColor(0x24, 0x29, 0x2F)
                if idx < len(payload) - 1:
                    run.add_break()
        elif kind == "hr":
            p = document.add_paragraph()
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(10)
            rule_below(p, color=RULE, size=6)
        elif kind in ("ul", "ol"):
            for item in payload:
                style = "List Bullet" if kind == "ul" else "List Number"
                if item["level"] > 0:
                    style = f"{style} {min(item['level'] + 1, 3)}"
                try:
                    p = document.add_paragraph(style=style)
                except KeyError:
                    p = document.add_paragraph()
                p.paragraph_format.space_after = Pt(3)
                prefix = ""
                if item["checked"] is not None:
                    prefix = "☐ " if not item["checked"] else "☒ "
                add_runs(p, prefix + item["text"])
        elif kind == "table":
            header, rows = payload
            if all(not h.strip() for h in header):
                header = None
            ncols = max([len(header or [])] + [len(r) for r in rows]) if rows else len(header or [])
            table = document.add_table(rows=0, cols=ncols)
            table.style = "Table Grid"
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            table.autofit = False

            # column weights from content length
            weights = []
            for c in range(ncols):
                lengths = [len(plain(header[c])) if header and c < len(header) else 0]
                for r in rows:
                    if c < len(r):
                        lengths.append(len(plain(r[c])))
                weights.append(max(15, min(58, max(lengths))))
            widths = [Cm(w) for w in column_widths_cm(CONTENT_CM, weights)]

            if header:
                hdr = table.add_row()
                trpr = hdr._tr.get_or_add_trPr()
                tbl_header = OxmlElement("w:tblHeader")
                tbl_header.set(qn("w:val"), "true")
                trpr.append(tbl_header)
                for c in range(ncols):
                    cell = hdr.cells[c]
                    cell.width = widths[c]
                    shade_cell(cell, HEAD_BG)
                    p = cell.paragraphs[0]
                    p.paragraph_format.space_after = Pt(1)
                    if c < len(header):
                        add_runs(p, header[c], size=8.5, color=(0xFF, 0xFF, 0xFF))
                        for run in p.runs:
                            run.bold = True

            for ridx, row in enumerate(rows):
                new_row = table.add_row()
                can_split = OxmlElement("w:cantSplit")
                new_row._tr.get_or_add_trPr().append(can_split)
                cells = new_row.cells
                for c in range(ncols):
                    cells[c].width = widths[c]
                    if ridx % 2 == 1:
                        shade_cell(cells[c], ZEBRA)
                    p = cells[c].paragraphs[0]
                    p.paragraph_format.space_after = Pt(1)
                    p.paragraph_format.line_spacing = 1.05
                    if c < len(row):
                        add_runs(p, row[c], size=8.5)

            document.add_paragraph().paragraph_format.space_after = Pt(2)

    # footer
    footer_p = document.sections[0].footer.paragraphs[0]
    footer_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    frun = footer_p.add_run(f"Supreme Mall · {title_text} · exported from {source_name}  —  page ")
    frun.font.size = Pt(8)
    frun.font.color.rgb = RGBColor(*MUTED)
    fld = OxmlElement("w:fldSimple")
    fld.set(qn("w:instr"), "PAGE")
    footer_p._p.append(fld)

    props = document.core_properties
    props.title = title_text
    props.author = "Supreme Mall"
    props.subject = "Decision record for review"
    props.comments = f"Exported from {source_name}"

    document.save(str(out_path))


def shade_cell(cell, fill):
    from docx.oxml import OxmlElement
    from docx.oxml.ns import qn

    tcpr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    tcpr.append(shd)


# --------------------------------------------------------------------------- #
# PDF
# --------------------------------------------------------------------------- #

def pdf_export(blocks, out_path, source_name, title_text):
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_LEFT
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import (
        BaseDocTemplate,
        Frame,
        KeepTogether,
        PageTemplate,
        Paragraph,
        Preformatted,
        Spacer,
        Table,
        TableStyle,
    )

    font_dir = Path("/usr/share/fonts/truetype/dejavu")
    pdfmetrics.registerFont(TTFont("DV", str(font_dir / "DejaVuSans.ttf")))
    pdfmetrics.registerFont(TTFont("DV-B", str(font_dir / "DejaVuSans-Bold.ttf")))
    pdfmetrics.registerFont(TTFont("DV-M", str(font_dir / "DejaVuSansMono.ttf")))
    bold_italic = font_dir / "DejaVuSans-Bold.ttf"
    pdfmetrics.registerFontFamily("DV", normal="DV", bold="DV-B", italic="DV", boldItalic="DV-B")

    navy = colors.HexColor("#0B2D5B")
    gold = colors.HexColor("#B0840F")
    ink = colors.HexColor("#1F2937")
    muted = colors.HexColor("#5B6677")
    rule = colors.HexColor("#D8DEE6")
    zebra = colors.HexColor("#F5F7FA")

    body = ParagraphStyle("body", fontName="DV", fontSize=9.4, leading=12.7,
                          textColor=ink, spaceAfter=4.4, alignment=TA_LEFT)
    h1 = ParagraphStyle("h1", parent=body, fontName="DV-B", fontSize=20, leading=24,
                        textColor=navy, spaceAfter=10, spaceBefore=0)
    h2 = ParagraphStyle("h2", parent=body, fontName="DV-B", fontSize=13.5, leading=17,
                        textColor=navy, spaceBefore=12, spaceAfter=5,
                        keepWithNext=True)
    h3 = ParagraphStyle("h3", parent=body, fontName="DV-B", fontSize=10.5, leading=14,
                        textColor=gold, spaceBefore=9, spaceAfter=3.5,
                        keepWithNext=True)
    h4 = ParagraphStyle("h4", parent=body, fontName="DV-B", fontSize=9.5,
                        textColor=muted, spaceBefore=8, spaceAfter=3,
                        keepWithNext=True)
    cell_style = ParagraphStyle("cell", fontName="DV", fontSize=7.9, leading=10, textColor=ink)
    cell_head = ParagraphStyle("cellhead", fontName="DV-B", fontSize=8.2, leading=10.5,
                               textColor=colors.white)
    code_style = ParagraphStyle("code", fontName="DV-M", fontSize=7.6, leading=9.6,
                                textColor=colors.HexColor("#24292F"))
    lead_style = ParagraphStyle("lead", parent=body, keepWithNext=True)
    quote_style = ParagraphStyle("quote", parent=body, fontName="DV", fontSize=9,
                                 leading=13, textColor=muted, leftIndent=12, rightIndent=6)
    bullet = ParagraphStyle("bullet", parent=body, leftIndent=14, bulletIndent=4, spaceAfter=2)
    bullet_l2 = ParagraphStyle("bullet2", parent=bullet, leftIndent=28, bulletIndent=18)

    def inline_markup(text):
        out = []
        for chunk, attrs in inline_tokens(text):
            safe = (
                chunk.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            )
            if attrs.get("code"):
                out.append(f'<font name="DV-M" size="8.4" color="#8A4B08">{safe}</font>')
            elif attrs.get("bold"):
                out.append(f"<b>{safe}</b>")
            elif attrs.get("italic"):
                out.append(f"<i>{safe}</i>")
            elif attrs.get("link"):
                out.append(f'<font color="#1D4ED8"><u>{safe}</u></font>')
            else:
                out.append(safe)
        return "".join(out)

    story = []
    for kind, payload in blocks:
        if kind == "h1":
            story.append(Paragraph(inline_markup(payload), h1))
            story.append(Table([[""]], colWidths=[17 * cm], rowHeights=[2],
                               style=TableStyle([("BACKGROUND", (0, 0), (-1, -1), gold)])))
            story.append(Spacer(1, 10))
        elif kind == "h2":
            story.append(Paragraph(inline_markup(payload), h2))
        elif kind == "h3":
            story.append(Paragraph(inline_markup(payload), h3))
        elif kind == "h4":
            story.append(Paragraph(inline_markup(payload), h4))
        elif kind == "p":
            style = lead_style if payload.rstrip().endswith(":") else body
            story.append(Paragraph(inline_markup(payload), style))
        elif kind == "quote":
            story.append(Paragraph(inline_markup(payload), quote_style))
            story.append(Spacer(1, 4))
        elif kind == "code":
            story.append(Spacer(1, 3))
            story.append(Table(
                [[Preformatted("\n".join(payload), code_style)]],
                colWidths=[17 * cm],
                style=TableStyle([
                    ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F3F4F6")),
                    ("LEFTPADDING", (0, 0), (-1, -1), 8),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                    ("TOPPADDING", (0, 0), (-1, -1), 7),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
                    ("LINEBEFORE", (0, 0), (0, -1), 2, gold),
                ]),
            ))
            story.append(Spacer(1, 6))
        elif kind == "hr":
            story.append(Table([[""]], colWidths=[17 * cm], rowHeights=[1],
                               style=TableStyle([("BACKGROUND", (0, 0), (-1, -1), rule)])))
            story.append(Spacer(1, 8))
        elif kind in ("ul", "ol"):
            counters = {}
            for item in payload:
                style = bullet_l2 if item["level"] > 0 else bullet
                if item["checked"] is not None:
                    mark = "☐" if not item["checked"] else "☒"
                    text = f"{mark} {inline_markup(item['text'])}"
                elif kind == "ol":
                    lvl = item["level"]
                    counters[lvl] = counters.get(lvl, 0) + 1
                    text = f"{counters[lvl]}. {inline_markup(item['text'])}"
                else:
                    text = f"• {inline_markup(item['text'])}"
                story.append(Paragraph(text, style))
            story.append(Spacer(1, 4))
        elif kind == "table":
            header, rows = payload
            if all(not h.strip() for h in header):
                header = None
            ncols = max([len(header or [])] + [len(r) for r in rows]) if rows else len(header or [])
            weights = []
            for c in range(ncols):
                lengths = [len(plain(header[c])) if header and c < len(header) else 0]
                for r in rows:
                    if c < len(r):
                        lengths.append(len(plain(r[c])))
                weights.append(max(15, min(52, max(lengths))))
            widths = [w * cm for w in column_widths_cm(17.0, weights)]

            data = []
            if header:
                data.append([
                    Paragraph(inline_markup(header[c]) if c < len(header) else "", cell_head)
                    for c in range(ncols)
                ])
            for r in rows:
                data.append([
                    Paragraph(inline_markup(r[c]) if c < len(r) else "", cell_style)
                    for c in range(ncols)
                ])

            style_cmds = [
                ("GRID", (0, 0), (-1, -1), 0.4, rule),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 3.2),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3.2),
            ]
            start = 0
            if header:
                style_cmds.append(("BACKGROUND", (0, 0), (-1, 0), navy))
                start = 1
            for idx in range(start, len(data)):
                if (idx - start) % 2 == 1:
                    style_cmds.append(("BACKGROUND", (0, idx), (-1, idx), zebra))
            story.append(Table(data, colWidths=widths, repeatRows=1 if header else 0,
                               style=TableStyle(style_cmds)))
            story.append(Spacer(1, 6))

    # A heading must never sit alone at the foot of a page: pair every h2-h4
    # with the flowable that follows it.
    merged = []
    idx = 0
    while idx < len(story):
        item = story[idx]
        is_heading = (
            isinstance(item, Paragraph) and getattr(item.style, "name", "") in ("h2", "h3", "h4")
        )
        if is_heading:
            group = [item]
            j = idx + 1
            while j < len(story) and isinstance(story[j], Spacer):
                group.append(story[j])
                j += 1
            if j < len(story):
                group.append(story[j])
                j += 1
                # a heading over a list travels with the whole list
                while (
                    j < len(story)
                    and isinstance(story[j], Paragraph)
                    and getattr(story[j].style, "name", "").startswith("bullet")
                ):
                    group.append(story[j])
                    j += 1
            merged.append(KeepTogether(group))
            idx = j
            continue
        if isinstance(item, Paragraph) and getattr(item.style, "name", "").startswith("bullet"):
            run = [item]
            j = idx + 1
            while (
                j < len(story)
                and isinstance(story[j], Paragraph)
                and getattr(story[j].style, "name", "").startswith("bullet")
            ):
                run.append(story[j])
                j += 1
            if len(run) > 2:
                merged.append(KeepTogether(run))
            else:
                merged.extend(run)
            idx = j
            continue
        merged.append(item)
        idx += 1
    story[:] = merged

    def decorate(canvas, doc):
        canvas.saveState()
        canvas.setFont("DV", 7.2)
        canvas.setFillColor(muted)
        canvas.drawString(2 * cm, 1.1 * cm, f"Supreme Mall — decision record · {source_name}")
        canvas.drawRightString(19 * cm, 1.1 * cm, f"page {doc.page}")
        canvas.setStrokeColor(rule)
        canvas.setLineWidth(0.5)
        canvas.line(2 * cm, 1.5 * cm, 19 * cm, 1.5 * cm)
        canvas.restoreState()

    doc = BaseDocTemplate(
        str(out_path),
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=1.9 * cm,
        bottomMargin=2.0 * cm,
        title=title_text,
        author="Supreme Mall",
        subject="Decision record for review",
    )
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="body")
    doc.addPageTemplates([PageTemplate(id="main", frames=[frame], onPage=decorate)])
    doc.build(story)


# --------------------------------------------------------------------------- #

def main():
    if len(sys.argv) < 4:
        print("usage: export_doc.py <input.md> <output.docx> <output.pdf>")
        raise SystemExit(2)

    md_path = Path(sys.argv[1])
    docx_path = Path(sys.argv[2])
    pdf_path = Path(sys.argv[3])

    text = md_path.read_text(encoding="utf-8")
    blocks = parse(text)

    title_text = next(
        (plain(b[1]) for b in blocks if b[0] == "h1"), md_path.stem.replace("-", " ")
    )

    docx_export(blocks, docx_path, md_path.name, title_text)
    pdf_export(blocks, pdf_path, md_path.name, title_text)

    print(f"blocks: {len(blocks)}")
    print(f"docx: {docx_path} ({docx_path.stat().st_size // 1024} KB)")
    print(f"pdf : {pdf_path} ({pdf_path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
