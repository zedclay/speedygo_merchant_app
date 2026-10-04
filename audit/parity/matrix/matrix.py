import json, re
rows=json.load(open('/tmp/parity/rows.json'))
journey={'A/E':'1 Shell / dashboard · 5 Reports','B':'2 Orders','C':'3 Catalogue','D':'4 Store','F/G':'6 Settings · 7 Auth/registration'}
def batch_of(r):
    ref=r['ref']
    if r['batch']=='A/E':
        return 'B5 Reports' if any(k in ref for k in ['report','sales','daily','popular']) else 'B1 Shell/Dashboard'
    if r['batch']=='F/G':
        auth=['splash','onboarding','phone_login','otp','registration','document','verification']
        return 'B7 Auth/Registration' if any(k in ref for k in auth) else 'B6 Settings/Notifications'
    return {'B':'B2 Orders','C':'B3 Catalogue','D':'B4 Store'}[r['batch']]
def short(s,n=240):
    s=re.sub(r'\s+',' ',s or '').replace('|','/')
    return s if len(s)<=n else s[:n].rsplit(' ',1)[0]+'…'
out=[]
for i,r in enumerate(rows,1):
    name=r['ref'].strip('`* ')
    anchor=re.sub(r'[^a-z0-9_ -]','',name.lower()).replace(' ','-')
    link=f"[{r['file'].split('_')[0]}](../audit/parity/inventory/{r['file']}#{anchor})"
    out.append(f"| {i} | {batch_of(r)} | {r['ref']} | {short(r['route'],120)} | {short(r.get('diff','see inventory'))} | {short(r['work'],200)} | {r['status']} | — | {link} |")
open('/tmp/parity/rows.md','w').write('\n'.join(out))
print(len(out))
