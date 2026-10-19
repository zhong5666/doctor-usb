# -*- coding: utf-8 -*-
# 数码医生 v3 病历卡生成器 - 本地纯计算, 无需网络
# 用法: python makecard.py    (自动取 report\ 最新报告)
import sys, os, glob, re, datetime

def dec(b):
    for enc in ('utf-8-sig', 'utf-8', 'gbk'):
        try:
            return b.decode(enc)
        except UnicodeDecodeError:
            continue
    return b.decode('utf-8', errors='replace')

def find_latest(d, prefix):
    fs = sorted(glob.glob(os.path.join(d, prefix + '*.txt')))
    return fs[-1] if fs else None

def main():
    if getattr(sys, 'frozen', False):
        # PyInstaller 打包后: 以 exe 所在目录为基准 (U盘任意盘符都行)
        base = os.path.dirname(os.path.abspath(sys.executable))
    else:
        base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    rpt_dir = os.path.join(base, 'report')
    ts = datetime.datetime.now().strftime('%Y%m%d%H%M%S')

    host = '未知电脑'
    disks = []
    rpt = find_latest(rpt_dir, '体检报告_')
    if rpt:
        t = dec(open(rpt, 'rb').read())
        m = re.search(r'电脑名[:：]\s*(\S+)', t)
        if m:
            host = m.group(1)
        for l in t.splitlines():
            l = l.strip()
            if re.match(r'^[A-Z]:\s+total_GB', l):
                disks.append(l[:60])

    ai_summary = '无AI结论(尚未运行AI分析)'
    ai_txt = find_latest(rpt_dir, 'AI分析_')
    if ai_txt:
        t = dec(open(ai_txt, 'rb').read())
        idx = t.find('【')
        ai_summary = (t[idx:] if idx >= 0 else t).strip()[:450]

    lines = ['【数码医生病历卡】',
             '电脑: ' + host,
             '体检: ' + ts[:8] + ' (完整报告在U盘report\)']
    if disks:
        lines.append('磁盘: ' + ' | '.join(disks)[:90])
    lines.append('')
    lines.append('【AI结论】')
    lines.append(ai_summary)
    text = '\n'.join(lines)

    try:
        import qrcode
    except ImportError:
        print('ERROR: 需要 qrcode 库 -> pip install qrcode pillow')
        sys.exit(1)
    img = qrcode.make(text)
    png = os.path.join(rpt_dir, '病历卡_%s.png' % ts)
    img.save(png)
    open(os.path.join(rpt_dir, '病历卡摘要_%s.txt' % ts), 'w', encoding='utf-8').write(text)
    print('病历卡已生成(本地计算, 无网络):')
    print('  ', png)
    print('  摘要字数:', len(text))

if __name__ == '__main__':
    main()
