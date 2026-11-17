$ErrorActionPreference='Stop'
[Console]::InputEncoding=New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding($false)
$r=[Console]::In.ReadToEnd() | ConvertFrom-Json
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes,System.Drawing
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class WEWin {
 public delegate bool EnumProc(IntPtr h,IntPtr l);
 [StructLayout(LayoutKind.Sequential)] public struct RECT {public int Left,Top,Right,Bottom;}
 [StructLayout(LayoutKind.Sequential)] public struct POINT {public int X,Y;}
 [StructLayout(LayoutKind.Sequential)] public struct GUIINFO {public int cbSize;public int flags;public IntPtr active,focus,capture,menuOwner,moveSize,caret;public RECT caretRect;}
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb,IntPtr l);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsChild(IntPtr parent,IntPtr child);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);
 [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr h,ref POINT p);
 [DllImport("user32.dll")] public static extern IntPtr ChildWindowFromPointEx(IntPtr h,POINT p,uint f);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")] public static extern bool GetGUIThreadInfo(uint id,ref GUIINFO g);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
[void][WEWin]::SetProcessDPIAware()
function Assert-Target([IntPtr]$h) {
 if(-not [WEWin]::IsWindow($h)){throw 'Window no longer exists'}
 [uint32]$procId=0;[void][WEWin]::GetWindowThreadProcessId($h,[ref]$procId)
 $p=Get-Process -Id $procId
 $allowed=@((Join-Path $r.install 'wallpaper64.exe'),(Join-Path $r.install 'wallpaper32.exe'),(Join-Path $r.install 'bin\wallpaperui.exe'),(Join-Path $r.install 'bin\ui32.exe'))
 if(-not ($allowed -contains $p.Path)){throw 'Rejected: window does not belong to configured Wallpaper Engine executables'}
 return $p
}
function Bounds([IntPtr]$h){$b=New-Object WEWin+RECT;if(-not [WEWin]::GetWindowRect($h,[ref]$b)){throw 'GetWindowRect failed'};return $b}
function Finite-Number($value){
 $n=[double]$value
 if([double]::IsNaN($n) -or [double]::IsInfinity($n)){return $null}
 return $n
}
function Safe-Bounds($rect){
 $x=Finite-Number $rect.X;$y=Finite-Number $rect.Y
 $width=Finite-Number $rect.Width;$height=Finite-Number $rect.Height
 if($null -eq $x -or $null -eq $y -or $null -eq $width -or $null -eq $height -or $width -lt 0 -or $height -lt 0){return $null}
 return @{x=$x;y=$y;width=$width;height=$height}
}
function Tree($element,$depth,$rows){
 if($depth -gt 12 -or $rows.Count -ge 500){return}
 try {
 $c=$element.Current;$id=($element.GetRuntimeId() -join '.')
 $b=$c.BoundingRectangle
 $safeBounds=Safe-Bounds $b
 $rows.Add(@{id=$id;name=$c.Name;type=$c.ControlType.ProgrammaticName;enabled=$c.IsEnabled;offscreen=$c.IsOffscreen;bounds=$safeBounds;boundsValid=($null -ne $safeBounds)})
 $walker=[System.Windows.Automation.TreeWalker]::ControlViewWalker;$child=$walker.GetFirstChild($element)
 while($null -ne $child -and $rows.Count -lt 500){Tree $child ($depth+1) $rows;$child=$walker.GetNextSibling($child)}
 }catch{}
}
function Find-Element($element,$id,$depth){
 if($depth -gt 15){return $null}
 if(($element.GetRuntimeId() -join '.') -eq $id){return $element}
 $walker=[System.Windows.Automation.TreeWalker]::ControlViewWalker;$child=$walker.GetFirstChild($element)
 while($null -ne $child){$found=Find-Element $child $id ($depth+1);if($null -ne $found){return $found};$child=$walker.GetNextSibling($child)}
 return $null
}
function Point-Target([IntPtr]$h,[int]$x,[int]$y){
 $b=Bounds $h;if($x -lt 0 -or $y -lt 0 -or $x -ge ($b.Right-$b.Left) -or $y -ge ($b.Bottom-$b.Top)){throw 'Point outside window'}
 $screen=New-Object WEWin+POINT;$screen.X=$b.Left+$x;$screen.Y=$b.Top+$y
 $target=$h
 for($i=0;$i -lt 15;$i++){
  $p=$screen;[void][WEWin]::ScreenToClient($target,[ref]$p)
  $child=[WEWin]::ChildWindowFromPointEx($target,$p,7)
  if($child -eq [IntPtr]::Zero -or $child -eq $target){break}
  [void](Assert-Target $child);$target=$child
 }
 $p=$screen;[void][WEWin]::ScreenToClient($target,[ref]$p)
 return @{handle=$target;x=$p.X;y=$p.Y;screenX=$screen.X;screenY=$screen.Y}
}
function Post([IntPtr]$h,[uint32]$msg,[long]$w,[int]$x,[int]$y){
 [void](Assert-Target $h)
 $lp=($x -band 65535) -bor (($y -band 65535) -shl 16)
 if(-not [WEWin]::PostMessage($h,$msg,[IntPtr]$w,[IntPtr]$lp)){throw 'Window message failed'}
}
try {
 if($r.operation -eq 'windows'){
 $rows=New-Object 'System.Collections.Generic.List[object]'
 $cb=[WEWin+EnumProc]{param($h,$l)
  try {if([WEWin]::IsWindowVisible($h)){$p=Assert-Target $h;$t=New-Object System.Text.StringBuilder 1024;[void][WEWin]::GetWindowText($h,$t,1024);$b=Bounds $h;$rows.Add(@{hwnd=$h.ToInt64().ToString();title=$t.ToString();pid=$p.Id;process=$p.ProcessName;minimized=[WEWin]::IsIconic($h);width=$b.Right-$b.Left;height=$b.Bottom-$b.Top})}}catch{}
  return $true
 }
 [void][WEWin]::EnumWindows($cb,[IntPtr]::Zero)
 $result=@{windows=@($rows.ToArray());sessionId=[System.Diagnostics.Process]::GetCurrentProcess().SessionId;note='An empty list can mean no visible window or an isolated desktop. Run the MCP in the same interactive Windows session as Wallpaper Engine.'}
 }else{
 $h=[IntPtr][long]$r.hwnd;[void](Assert-Target $h)
 if([WEWin]::IsIconic($h)){throw 'Restore this Wallpaper Engine window first'}
 switch($r.operation){
 'snapshot' {
  $b=Bounds $h;$w=[long]$b.Right-[long]$b.Left;$height=[long]$b.Bottom-[long]$b.Top
  if($w -lt 1 -or $height -lt 1 -or $w*$height -gt 20000000){throw 'Invalid capture dimensions'}
  $bitmap=[System.Drawing.Bitmap]::new([int]$w,[int]$height);$g=[System.Drawing.Graphics]::FromImage($bitmap);$dc=$g.GetHdc()
  try {$ok=[WEWin]::PrintWindow($h,$dc,2)}finally{$g.ReleaseHdc($dc);$g.Dispose()}
  if(-not $ok){$bitmap.Dispose();throw 'PrintWindow failed; no desktop capture fallback'}
  $ms=New-Object System.IO.MemoryStream
  try{$bitmap.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png);$image=[Convert]::ToBase64String($ms.ToArray())}finally{$ms.Dispose();$bitmap.Dispose()}
  $captureWidth=$w;$captureHeight=$height;$captureOrigin=@{x=$b.Left;y=$b.Top}
  $rows=New-Object 'System.Collections.Generic.List[object]';$el=[System.Windows.Automation.AutomationElement]::FromHandle($h);Tree $el 0 $rows
  $result=@{hwnd=$r.hwnd;image=$image;width=$captureWidth;height=$captureHeight;screenOrigin=$captureOrigin;elements=@($rows.ToArray());note='Element bounds are screen coordinates; pointer coordinates are image-relative. Invalid UI rectangles are null with boundsValid=false. GPU content may appear blank. Maximum 500 elements.'}
 }
 'uia' {
  $el=Find-Element ([System.Windows.Automation.AutomationElement]::FromHandle($h)) $r.elementId 0
  if($null -eq $el){throw 'Stale element ID; capture again'}
  $n=$el.Current.Name
  if($n -match '(?i)subscribe|publish|upload|\uad6c\ub3c5|\uac8c\uc2dc|\uc5c5\ub85c\ub4dc'){throw 'Subscription/publishing controls excluded'}
  [void](Assert-Target $h)
  switch($r.action){
   'invoke' {([System.Windows.Automation.InvokePattern]$el.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)).Invoke()}
   'select' {([System.Windows.Automation.SelectionItemPattern]$el.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)).Select()}
   'toggle' {([System.Windows.Automation.TogglePattern]$el.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)).Toggle()}
   'expand' {([System.Windows.Automation.ExpandCollapsePattern]$el.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)).Expand()}
   'collapse' {([System.Windows.Automation.ExpandCollapsePattern]$el.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)).Collapse()}
   'set_value' {if($null -eq $r.value){throw 'value required'};([System.Windows.Automation.ValuePattern]$el.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)).SetValue([string]$r.value)}
   default {throw 'Unknown UI action'}
  }
  $result=@{submitted=$true;verified=$false;action=$r.action}
 }
 'pointer' {
  $p=Point-Target $h $r.x $r.y;$target=$p.handle
  $down=513;$up=514;$flags=1;if($r.button -eq 'right'){$down=516;$up=517;$flags=2}
  switch($r.gesture){
   'click' {Post $target $down $flags $p.x $p.y;Post $target $up 0 $p.x $p.y}
   'double_click' {Post $target $down $flags $p.x $p.y;Post $target $up 0 $p.x $p.y;$dbl=515;if($r.button -eq 'right'){$dbl=518};Post $target $dbl $flags $p.x $p.y;Post $target $up 0 $p.x $p.y}
   'scroll' {Post $target 522 ([long]$r.delta -shl 16) $p.screenX $p.screenY}
   'drag' {
    $end=Point-Target $h $r.toX $r.toY;$pt=New-Object WEWin+POINT;$pt.X=$end.screenX;$pt.Y=$end.screenY;[void][WEWin]::ScreenToClient($target,[ref]$pt)
    Post $target $down $flags $p.x $p.y
    try{for($i=1;$i -le 12;$i++){Post $target 512 $flags ([int]($p.x+($pt.X-$p.x)*$i/12)) ([int]($p.y+($pt.Y-$p.y)*$i/12));Start-Sleep -Milliseconds 15}}finally{Post $target $up 0 $pt.X $pt.Y}
   }
   default {throw 'Unknown pointer action'}
  }
  $result=@{submitted=$true;verified=$false;experimental=$true}
 }
 'text' {
  [uint32]$procId=0;$thread=[WEWin]::GetWindowThreadProcessId($h,[ref]$procId)
  $info=New-Object WEWin+GUIINFO;$info.cbSize=[Runtime.InteropServices.Marshal]::SizeOf($info)
  if(-not [WEWin]::GetGUIThreadInfo($thread,[ref]$info) -or $info.focus -eq [IntPtr]::Zero){throw 'No focused control in target thread'}
  [void](Assert-Target $info.focus)
  if($info.focus -ne $h -and -not [WEWin]::IsChild($h,$info.focus)){throw 'Focused control belongs to a different window'}
  foreach($c in ([string]$r.text).ToCharArray()){if(-not [WEWin]::PostMessage($info.focus,258,[IntPtr][int]$c,[IntPtr]1)){throw 'Text message failed'}}
  $result=@{submitted=$true;verified=$false;experimental=$true}
 }
 default {throw 'Unknown operation'}
 }
 }
 $result | ConvertTo-Json -Depth 12 -Compress
}catch{@{error=$_.Exception.Message} | ConvertTo-Json -Compress}
