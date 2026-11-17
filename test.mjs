import {test} from 'node:test';
import assert from 'node:assert/strict';
import {rpc,call,allowedFile} from './server.mjs';
import {spawn} from 'node:child_process';
test('initialize, notifications, tool catalog',async()=>{
 const r=await rpc({jsonrpc:'2.0',id:1,method:'initialize',params:{protocolVersion:'2025-03-26'}});assert.equal(r.result.protocolVersion,'2025-03-26');
 assert.equal(await rpc({jsonrpc:'2.0',method:'notifications/initialized'}),null);
 const list=await rpc({jsonrpc:'2.0',id:2,method:'tools/list'});assert.equal(list.result.tools.length,10);
});
test('reject arbitrary command, bad arguments, unknown tool',async()=>{
 for(const [n,a] of [['control',{action:'cmd.exe'}],['control',{action:'pause',extra:true}],['window_snapshot',{hwnd:'-1'}],['list_wallpapers',{limit:10000}],['shell',{}],['window_pointer',{hwnd:'1',action:'drag',x:0,y:0}]])await assert.rejects(()=>call(n,a));
});
test('reject out-of-root file',async()=>{await assert.rejects(()=>allowedFile(new URL('./server.mjs',import.meta.url).pathname.replace(/^\/(\w:)/,'$1')));});
test('tool errors use MCP isError',async()=>{const r=await rpc({jsonrpc:'2.0',id:3,method:'tools/call',params:{name:'control',arguments:{action:'upload'}}});assert.equal(r.result.isError,true);});
test('unknown method',async()=>{assert.equal((await rpc({jsonrpc:'2.0',id:4,method:'bad'})).error.code,-32601);});
test('stdio transport emits valid JSON only, handles malformed input and notifications',async()=>{
 const child=spawn(process.execPath,['server.mjs'],{cwd:new URL('.',import.meta.url),windowsHide:true});let out='',err='';child.stdout.on('data',d=>out+=d);child.stderr.on('data',d=>err+=d);
 child.stdin.end('{bad json}\n'+JSON.stringify({jsonrpc:'2.0',id:1,method:'initialize',params:{protocolVersion:'2025-06-18'}})+'\n'+JSON.stringify({jsonrpc:'2.0',method:'notifications/initialized'})+'\n'+JSON.stringify({jsonrpc:'2.0',id:2,method:'tools/list'})+'\n');
 const code=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('close',resolve)});assert.equal(code,0,err);const lines=out.trim().split('\n').map(JSON.parse);assert.equal(lines.length,3);assert.equal(lines[0].error.code,-32700);assert.equal(lines[2].result.tools.length,10);
});
