// Mimics LDtk misc/FileWatcher.hx: fs.watch on the file, act on "change", ignore "rename"
const fs=require('fs'), path='/tmp/claude-1000/leveleditors/test/nodew/t.png';
fs.writeFileSync(path,'v0');
fs.watch(path,(ev)=>console.log(Date.now()%100000, 'event', ev, ev==='change'?'-> LDtk reloads':'-> LDtk ignores'));
const w=(s)=>fs.writeFileSync(path,s);
const atomic=(s)=>{fs.writeFileSync(path+'.tmp',s); fs.renameSync(path+'.tmp',path);};
const steps=[['inplace #1',()=>w('v1')],['atomic #2',()=>atomic('v2')],['inplace #3',()=>w('v3')],['inplace #4',()=>w('v4')]];
let i=0; const iv=setInterval(()=>{ if(i>=steps.length){clearInterval(iv); setTimeout(()=>process.exit(0),500); return;} console.log('--',steps[i][0]); steps[i][1](); i++; },700);
