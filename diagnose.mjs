import {call,rpc} from './server.mjs';
try {
 const status=await call('status');
 const items=await call('list_wallpapers',{limit:1});
 console.log(JSON.stringify({status,wallpaperCount:items.total,catalogWarnings:items.warnings},null,2));
 if(!status.windows.length)console.log('WARNING: No accessible Wallpaper Engine window. Open the library/editor in the same interactive desktop session, then retry. UI features are NOT verified.');
 else {
  const target=status.windows.filter(x=>!x.minimized&&x.process==='wallpaperui'&&x.width>=200&&x.height>=150).sort((a,b)=>b.width*b.height-a.width*a.height)[0];
  if(target){const s=await call('window_snapshot',{hwnd:target.hwnd});console.log(JSON.stringify({captureWidth:s.width,captureHeight:s.height,pngBytes:Buffer.from(s.image,'base64').length,elementCount:s.elements.length}));}
 }
 const list=await rpc({jsonrpc:'2.0',id:1,method:'tools/list'});console.log('MCP tools: '+list.result.tools.length);
}catch(e){console.error(e.message);process.exitCode=1;}
