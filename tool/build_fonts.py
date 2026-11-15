#!/usr/bin/env python3
"""生成 assets/fonts 下的 Noto Serif SC 子集字体。

为什么要子集化
--------------
完整的 Noto Serif SC 变量字体是 24MB，两个静态字重加起来也超过 20MB。
本项目只在标题（`kSerifStyle`）里用衬线体，字符集不需要覆盖全部 3 万汉字，
所以裁到「GB2312 + ASCII + 常用标点」共 7553 字，两个字重合计约 6.5MB。

字体来源
--------
优先读环境变量 `VENERA_SERIF_SRC` 指定的文件；否则按顺序尝试系统常见路径。
字体授权为 SIL Open Font License 1.1，允许随应用内嵌分发。

依赖
----
    pip install fonttools

用法
----
    python tool/build_fonts.py

会覆盖 assets/fonts/NotoSerifSC-{Regular,Bold}.ttf。
"""
import os
import sys

try:
    from fontTools import subset
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer
except ImportError:
    sys.exit("缺少 fonttools，请先执行：pip install fonttools")

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUTDIR = os.path.join(ROOT, "assets", "fonts")

# 候选源字体。按顺序找第一个存在的。
CANDIDATES = [
    os.environ.get("VENERA_SERIF_SRC", ""),
    r"C:\Windows\Fonts\NotoSerifSC-VF.ttf",
    "/usr/share/fonts/opentype/noto/NotoSerifCJK-VF.otf.ttc",
    "/System/Library/Fonts/Supplemental/Songti.ttc",
]

# 目标字重 -> 输出文件名
TARGETS = [(400, "NotoSerifSC-Regular"), (700, "NotoSerifSC-Bold")]

# 设计里用到的额外字符（弯引号、破折号、项目符号等），GB2312 不含这些
EXTRA = "　、。〈〉《》「」『』【】〔〕・ー–—…‘’“”※★☆♥♪×÷±°′″¥€£§¶†‡•‥"


def build_charset():
    """GB2312 全字符 + ASCII + 常用符号。"""
    chars = set()
    for hi in range(0xA1, 0xF8):
        for lo in range(0xA1, 0xFF):
            try:
                chars.add(bytes([hi, lo]).decode("gb2312"))
            except UnicodeDecodeError:
                pass
    chars |= {chr(c) for c in range(0x20, 0x7F)}
    chars |= set(EXTRA)
    return "".join(sorted(chars))


def find_source():
    for c in CANDIDATES:
        if c and os.path.isfile(c):
            return c
    sys.exit(
        "找不到 Noto Serif SC 源字体。\n"
        "请设置环境变量 VENERA_SERIF_SRC 指向字体文件，"
        "或从 https://fonts.google.com/noto/specimen/Noto+Serif+SC 下载。"
    )


def main():
    src = find_source()
    print(f"源字体: {src}")
    text = build_charset()
    print(f"字符集: {len(text)} 字")

    os.makedirs(OUTDIR, exist_ok=True)
    tmpdir = os.path.join(OUTDIR, ".tmp")
    os.makedirs(tmpdir, exist_ok=True)

    for weight, name in TARGETS:
        tmp = os.path.join(tmpdir, f"inst_{weight}.ttf")

        # 1) 变量字体实例化：把 wght 轴钉死，产出真正的静态字体。
        #    只做 subset 不做 instantiate 的话，fvar 表会保留，
        #    两个文件都还是「任意字重」，字重差异不会生效。
        vf = TTFont(src)
        inst = instancer.instantiateVariableFont(
            vf, {"wght": weight}, inplace=False, updateFontNames=True
        )
        inst.save(tmp)
        inst.close()
        vf.close()

        # 2) 子集化
        opts = subset.Options()
        opts.layout_features = ["*"]
        opts.name_IDs = ["*"]
        opts.name_legacy = True
        opts.name_languages = ["*"]
        opts.notdef_outline = True
        opts.recommended_glyphs = True

        font = subset.load_font(tmp, opts)
        sub = subset.Subsetter(options=opts)
        sub.populate(text=text)
        sub.subset(font)

        out = os.path.join(OUTDIR, name + ".ttf")
        font.save(out)
        font.close()
        os.remove(tmp)

        check = TTFont(out, lazy=True)
        assert "fvar" not in check, "字重没有真正固定，instantiate 失败"
        size = os.path.getsize(out) / 1024 / 1024
        print(
            f"  {name}.ttf  {size:.2f} MB  "
            f"weight={check['OS/2'].usWeightClass}  "
            f"glyphs={len(check.getGlyphOrder())}"
        )
        check.close()

    try:
        os.rmdir(tmpdir)
    except OSError:
        pass


if __name__ == "__main__":
    main()
