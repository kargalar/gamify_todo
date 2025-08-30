import json
from pathlib import Path
p=Path(r'c:/KARGALAR/Projeler/Flutter/gamify_todo/assets/translations')
files=['en.json','tr.json','fr.json','de.json','ru.json']
data={}
for f in files:
    data[f]=json.loads((p/f).read_text(encoding='utf-8'))
all_keys=set().union(*[set(v.keys()) for v in data.values()])
missing={}
for f,d in data.items():
    missing[f]=sorted(list(all_keys - set(d.keys())))
print(json.dumps(missing,ensure_ascii=False,indent=2))
