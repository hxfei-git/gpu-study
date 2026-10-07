"""生成 §3.2 的三张 64 位描述符位图；每格对应一位，按 32 位换行。"""
from pathlib import Path
from html import escape

OUT = Path(__file__).parent
COLORS = {'address': '#e3efff', 'control': '#fff0cd', 'attr': '#e4f3e9', 'unknown': '#edf0f4'}
W, CELL, LEFT = 1240, 36, 44

def text(x, y, value, size=20, weight=400, anchor='start', color='#18344f', mono=False):
    family = 'Consolas, monospace' if mono else 'Microsoft YaHei, sans-serif'
    return f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" fill="{color}">{escape(value)}</text>'

def make(name, title, subtitle, fields, notes, footer):
    bits = [b for hi, lo, *_ in fields for b in range(lo, hi+1)]
    assert sorted(bits) == list(range(64)), 'Each bit must be defined exactly once'
    rows = (len(notes)+1)//2
    height = 450 + rows*37 + 70
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{height}" viewBox="0 0 {W} {height}">',
           f'<rect width="{W}" height="{height}" fill="white"/>',
           text(LEFT, 48, title, 30, 700), text(LEFT, 84, subtitle, 20),
           '<desc>两行位图分别显示位 63 至 32、位 31 至 0；横向每格代表一位。下方说明字段用途与当前场景的判断条件。</desc>']
    for row, top in enumerate([63,31]):
        y = 151 + row*137
        svg += [text(LEFT, y-39, f'[{top}:{top-31}]', 16, 600, mono=True)]
        for bit in range(top,top-32,-1):
            x = LEFT + (top-bit)*CELL
            svg.append(text(x+CELL/2,y-10,str(bit),14,anchor='middle',mono=True,color='#516579'))
        for hi,lo,label,kind in fields:
            h,l = min(hi,top),max(lo,top-31)
            if h<l: continue
            x = LEFT+(top-h)*CELL
            width = (h-l+1)*CELL
            svg.append(f'<rect x="{x}" y="{y}" width="{width}" height="64" fill="{COLORS[kind]}" stroke="#8fa2b5"/>')
            shown = label
            if kind=='address':
                shown = ('下级表地址' if '下级' in label else '数据页地址') + f' [{h}:{l}]'
            svg.append(text(x+width/2,y+39,shown,18,600,anchor='middle'))
    svg.append(text(LEFT,394,'字段释义',21,700))
    for i,note in enumerate(notes):
        col,row=i%2,i//2
        svg.append(text(LEFT+col*596,431+row*37,note,18))
    svg.append(f'<line x1="{LEFT}" y1="{height-70}" x2="1196" y2="{height-70}" stroke="#ccd6e1"/>')
    svg += [text(LEFT,height-43,footer,18),text(LEFT,height-15,'? 表示该场景的完整定义待核实；不代表保留位或必须写 0。',17,color='#516579'),'</svg>']
    (OUT/(name+'.svg')).write_text('\n'.join(svg)+'\n',encoding='utf-8')

directory = [(63,59,'BFS','control'),(58,57,'?','unknown'),(56,56,'TF','control'),
             (55,55,'?','unknown'),(54,54,'P','control'),(53,48,'?','unknown'),
             (47,6,'下级表地址','address'),(5,3,'?','unknown'),
             (2,2,'C','attr'),(1,1,'S','attr'),(0,0,'V','attr')]

make('page-entry-formats','图 A　普通目录项：本例 PDB2 / PDB1',
     '适用条件：有效的普通目录项，P=0；地址指向下一级页表。',directory,[
     '地址 [47:6]：下一级页表基址，低 6 位补 0。',
     'P [54]：目录位置的用途选择；P=0 为目录。',
     'BFS [63:59]：块片段大小，按翻译阶段使用。',
     'TF [56]：本普通目录阶段不靠它判断继续。',
     'C [2] = SNOOPED：访问下级表的一致性属性。',
     'S [1] = SYSTEM：0 本地内存，1 系统内存。',
     'V [0] = VALID：表项是否有效。',
     'P=1 的高层叶子改用图 C，不能套本图。'],
     '按位位置分别列出字段；普通目录的继续查表规则由层级和配置决定。')

make('page-entry-further-format','图 B　TF=1 的继续翻译项：本例 PDB0',
     '适用条件：有效且 TF=1；将当前项按目录解释，继续读取 PTB。',directory,[
     'TF [56]：必须为 1，触发继续翻译。',
     '地址 [47:6]：PTB 基址，低 6 位补 0。',
     'BFS [63:59]：下方 PTB 每项的覆盖大小。',
     'P [54]：本例为 0；本分支由 TF 选择。',
     'C [2] = SNOOPED：访问 PTB 的一致性属性。',
     'S [1] = SYSTEM：0 本地内存，1 系统内存。',
     'V [0] = VALID：本图要求为有效项。',
     '[11:6] 属于表地址，不能当 FRAG / 写权限。'],
     '与图 A 共享目录地址布局，但进入这一解释方式的条件是有效且 TF=1。')

leaf = [(63,59,'?','unknown'),(58,57,'M','attr'),(56,56,'TF','control'),
        (55,55,'L','control'),(54,54,'P','control'),(53,52,'?','unknown'),
        (51,51,'T','control'),(50,48,'?','unknown'),(47,12,'数据页地址','address'),
        (11,7,'FRAG','control'),(6,6,'W','attr'),(5,5,'R','attr'),(4,4,'X','attr'),
        (3,3,'Z','control'),(2,2,'C','attr'),(1,1,'S','attr'),(0,0,'V','attr')]

make('page-entry-leaf-format','图 C　最终叶子项：直接描述数据映射',
     '适用条件：有效且已选中叶子解释；页大小还取决于层级和翻译配置。',leaf,[
     '地址 [47:12]：数据页基址，低 12 位补 0。',
     'M [58:57] = MTYPE：目标数据的内存类型。',
     'TF [56]：本篇有效叶子为 0，不再向下查表。',
     'P [54]：PDB1 大页为 1；本例 PDB0 / PTB 为 0。',
     'FRAG [11:7]：连续映射的片段大小编码。',
     'R / W [5 / 6]：READABLE / WRITEABLE。',
     'X [4] = EXECUTABLE：驱动的可执行映射标志。',
     'C [2] = SNOOPED：目标访问的一致性属性。',
     'S [1] = SYSTEM：0 本地内存，1 系统内存。',
     'V [0] = VALID：表项是否有效。',
     'T [51] = PRT：部分驻留映射相关标志。',
     'Z [3] = TMZ：可信内存区域相关标志。',
     'L [55] = LOG：位宏已确认，完整作用待核实。',
     '高层叶子需按大页大小对齐目标地址。'],
     '图 C 的 [11:6] 为属性；图 A、B 的同一位区间属于下级表地址。')

print('Generated 3 SVG bit maps; all 64 bits covered exactly once in each map.')
