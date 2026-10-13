#!/usr/bin/env lua
-- HOME LAND PRO | حقوق المطور @FFF70F | القناة @Bb_1_p
local https=require("ssl.https")
local ltn12=require("ltn12")
local json=require("cjson")
local socket=require("socket")
https.TIMEOUT=30
local token=os.getenv("BOT_TOKEN")
local file=os.getenv("DATA_FILE") or "/opt/homeland/data.json"
if not token or token=="" then io.stderr:write("BOT_TOKEN missing\n"); os.exit(1) end
local apiurl="https://api.telegram.org/bot"..token.."/"
local rights="مطور السورس: @FFF70F\nقناة السورس: @Bb_1_p"
local db={chats={}}
local spam={}
local function decode(s) local ok,v=pcall(json.decode,s); if ok and type(v)=="table" then return v end end
local function load()
 local f=io.open(file,"r"); if not f then return end
 local raw=f:read("*a"); f:close(); if raw=="" then return end
 local d=decode(raw); if not d then io.stderr:write("Invalid data JSON; refusing to overwrite\n"); os.exit(2) end
 db=d; db.chats=db.chats or {}
end
local function save()
 local f,e=io.open(file..".tmp","w"); if not f then io.stderr:write(tostring(e).."\n"); return false end
 f:write(json.encode(db)); f:flush(); f:close(); return os.rename(file..".tmp",file)
end
local function api(method,p)
 local body=json.encode(p or {}); local out={}
 local ok,err=https.request({url=apiurl..method,method="POST",headers={["Content-Type"]="application/json",["Content-Length"]=tostring(#body)},source=ltn12.source.string(body),sink=ltn12.sink.table(out)})
 if not ok then return nil,tostring(err) end
 local r=decode(table.concat(out)); if not r or not r.ok then return nil,r and r.description or "bad response" end
 return r.result
end
local function send(cid,text,markup)
 local p={chat_id=cid,text=text,disable_web_page_preview=true}; if markup then p.reply_markup=markup end
 return api("sendMessage",p)
end
local function answer(id,text) api("answerCallbackQuery",{callback_query_id=id,text=text or ""}) end
local function group(c) return c and (c.type=="group" or c.type=="supergroup") end
local function sget(cid)
 local k=tostring(cid); db.chats[k]=db.chats[k] or {welcome="أهلاً بيك {name} بكروبنا ❤️",goodbye=true,antilink=false,antispam=true,custom={},ranks={},warnings={},stats={messages=0,deleted=0,joins=0,leaves=0,games=0}}
 local s=db.chats[k]; s.custom=s.custom or {}; s.ranks=s.ranks or {}; s.warnings=s.warnings or {}; s.stats=s.stats or {messages=0,deleted=0,joins=0,leaves=0,games=0}; return s
end
local function status(cid,uid) local m=api("getChatMember",{chat_id=cid,user_id=uid}); return m and m.status or "unknown" end
local function admin(cid,uid) local st=status(cid,uid); return st=="creator" or st=="administrator" end
local function level(cid,uid) if admin(cid,uid) then return 100 end; local r=sget(cid).ranks[tostring(uid)]; if r=="مدير" then return 80 elseif r=="مميز" then return 30 elseif r=="موثوق" then return 20 end; return 0 end
local function name(u) return u and (u.first_name or u.username) or "صديقنا" end
local function target(m) return m.reply_to_message and m.reply_to_message.from and m.reply_to_message.from.id end
local function parse(t) if type(t)~="string" then return end; local c,a=t:match("^%s*/([%w_]+)@?[%w_]*%s*(.-)%s*$"); if c then return c:lower(),a or "" end end
local function kb(rows) return {inline_keyboard=rows} end
local function help() return "🇮🇶 HOME LAND PRO — سورس وطن\n\n/start /help /panel /id /ping /stats\n\nإدارة (بالرد على العضو): /ban /kick /mute 10 /unmute /warn /warnings /clearwarn\n\nإعدادات: /antilink on|off\n/antispam on|off\n/welcome نص (استعمل {name})\n/goodbye on|off\n/custom كلمة | رد\n/delcustom كلمة\n/rank بالرد مدير|مميز|موثوق|عادي\n\nتسلية: /coin /dice\n\n"..rights end
local function panel(cid) send(cid,"🏠 HOME LAND PRO\nاختار القسم:",kb({
 {{text="🛡️ الحماية",callback_data="sec"},{text="👋 الترحيب",callback_data="wel"}},
 {{text="📊 الإحصائيات",callback_data="stats"},{text="🎮 التسلية",callback_data="games"}},
 {{text="📖 الأوامر",callback_data="help"}}
})) end
local function callback(q)
 local m=q.message; if not m then answer(q.id); return end
 local cid=m.chat.id; local uid=q.from.id; local s=sget(cid); local d=q.data
 if d~="games" and d~="help" and not admin(cid,uid) and level(cid,uid)<80 then answer(q.id,"للمشرفين فقط"); return end
 if d=="help" then api("editMessageText",{chat_id=cid,message_id=m.message_id,text=help(),reply_markup=kb({{{text="⬅️ رجوع",callback_data="home"}}})})
 elseif d=="home" then api("editMessageText",{chat_id=cid,message_id=m.message_id,text="🏠 HOME LAND PRO",reply_markup=kb({{{text="🛡️ الحماية",callback_data="sec"},{text="👋 الترحيب",callback_data="wel"}},{{text="📊 الإحصائيات",callback_data="stats"},{text="🎮 التسلية",callback_data="games"}},{{text="📖 الأوامر",callback_data="help"}}})})
 elseif d=="sec" then api("editMessageText",{chat_id=cid,message_id=m.message_id,text="الحماية\nمنع الروابط: "..tostring(s.antilink).."\nمكافحة التكرار: "..tostring(s.antispam),reply_markup=kb({{{text="تبديل منع الروابط",callback_data="t:antilink"},{text="تبديل السبام",callback_data="t:antispam"}},{{text="⬅️ رجوع",callback_data="home"}}})})
 elseif d=="wel" then api("editMessageText",{chat_id=cid,message_id=m.message_id,text="الترحيب: "..s.welcome.."\nالمغادرة: "..tostring(s.goodbye).."\nلتعديل الترحيب: /welcome نص",reply_markup=kb({{{text="تبديل المغادرة",callback_data="t:goodbye"}},{{text="⬅️ رجوع",callback_data="home"}}})})
 elseif d=="stats" then local x=s.stats; api("editMessageText",{chat_id=cid,message_id=m.message_id,text="📊 إحصائيات\nرسائل: "..x.messages.."\nمحذوفة: "..x.deleted.."\nانضمام: "..x.joins.."\nمغادرة: "..x.leaves.."\nألعاب: "..x.games,reply_markup=kb({{{text="⬅️ رجوع",callback_data="home"}}})})
 elseif d=="games" then api("editMessageText",{chat_id=cid,message_id=m.message_id,text="🎮 اختار لعبة",reply_markup=kb({{{text="🪙 عملة",callback_data="g:coin"},{text="🎲 نرد",callback_data="g:dice"}},{{text="⬅️ رجوع",callback_data="home"}}})})
 elseif d:match("^t:") then local k=d:sub(3); s[k]=not s[k]; save(); answer(q.id,"تم تحديث الإعداد"); panel(cid)
 elseif d=="g:coin" or d=="g:dice" then local r=d=="g:coin" and (math.random(2)==1 and "صورة 🪙" or "كتابة 🪙") or ("🎲 "..math.random(1,6)); s.stats.games=s.stats.games+1; save(); answer(q.id,r)
 else answer(q.id) end
end
local function moderate(m,c,arg)
 local cid=m.chat.id; local uid=m.from and m.from.id
 if not uid or level(cid,uid)<80 then send(cid,"هذا الأمر للمشرفين أو رتبة مدير فقط."); return end
 local tid=target(m); if not tid then send(cid,"استخدم الأمر بالرد على العضو."); return end
 if tid==uid or admin(cid,tid) then send(cid,"ما أگدر أنفذ الإجراء على نفسك أو مشرف."); return end
 if c=="ban" then local r,e=api("banChatMember",{chat_id=cid,user_id=tid}); send(cid,r and "تم الحظر." or ("تعذر: "..tostring(e)))
 elseif c=="kick" then local r,e=api("banChatMember",{chat_id=cid,user_id=tid}); if r then api("unbanChatMember",{chat_id=cid,user_id=tid,only_if_banned=true}); send(cid,"تم الطرد.") else send(cid,tostring(e)) end
 elseif c=="mute" then local n=tonumber(arg); if not n or n<1 or n>10080 then send(cid,"استخدم /mute عدد_الدقائق بالرد."); return end; local r,e=api("restrictChatMember",{chat_id=cid,user_id=tid,permissions={can_send_messages=false},until_date=os.time()+n*60}); send(cid,r and "تم الكتم." or tostring(e))
 elseif c=="unmute" then local r,e=api("restrictChatMember",{chat_id=cid,user_id=tid,permissions={can_send_messages=true,can_send_audios=true,can_send_documents=true,can_send_photos=true,can_send_videos=true,can_send_video_notes=true,can_send_voice_notes=true,can_send_polls=true,can_send_other_messages=true,can_add_web_page_previews=true}}); send(cid,r and "تم إلغاء الكتم." or tostring(e))
 elseif c=="warn" then local k=tostring(tid); sget(cid).warnings[k]=(sget(cid).warnings[k] or 0)+1; local n=sget(cid).warnings[k]; save(); send(cid,"إنذار "..n); if n>=3 then api("restrictChatMember",{chat_id=cid,user_id=tid,permissions={can_send_messages=false},until_date=os.time()+600}); send(cid,"وصل 3 إنذارات، محاولة كتم 10 دقائق.") end
 elseif c=="warnings" then send(cid,"الإنذارات: "..tostring(sget(cid).warnings[tostring(tid)] or 0))
 elseif c=="clearwarn" then sget(cid).warnings[tostring(tid)]=0; save(); send(cid,"تم تصفير الإنذارات.") end
end
local function process(m)
 if not m or not m.chat then return end
 local cid=m.chat.id; local chat=m.chat; local text=m.text or ""; local s=sget(cid)
 if group(chat) then s.stats.messages=s.stats.messages+1 end
 if group(chat) and m.new_chat_members then for _,u in ipairs(m.new_chat_members) do s.stats.joins=s.stats.joins+1; if not u.is_bot then send(cid,(s.welcome:gsub("{name}",name(u)))) end end; save() end
 if group(chat) and m.left_chat_member then s.stats.leaves=s.stats.leaves+1; if s.goodbye then send(cid,"مع السلامة "..name(m.left_chat_member).." 👋") end; save() end
 if group(chat) and m.from and not m.from.is_bot then
  local key=tostring(cid)..":"..tostring(m.from.id); local now=socket.gettime(); spam[key]=spam[key] or {}; local a={}
  for _,t in ipairs(spam[key]) do if now-t<8 then a[#a+1]=t end end; a[#a+1]=now; spam[key]=a
  if s.antispam and #a>=6 and not admin(cid,m.from.id) then local r=api("deleteMessage",{chat_id=cid,message_id=m.message_id}); if r then s.stats.deleted=s.stats.deleted+1; save() end; return end
  if s.antilink and text:match("[Hh][Tt][Tt][Pp][Ss]?://") and not admin(cid,m.from.id) then local r=api("deleteMessage",{chat_id=cid,message_id=m.message_id}); if r then s.stats.deleted=s.stats.deleted+1; save() end; return end
 end
 local c,arg=parse(text)
 if c then
  if c=="start" or c=="help" then send(cid,help())
  elseif c=="panel" then if not group(chat) or admin(cid,m.from.id) or level(cid,m.from.id)>=80 then panel(cid) else send(cid,"اللوحة للمشرفين.") end
  elseif c=="id" then send(cid,"Chat ID: "..cid..(m.from and "\nUser ID: "..m.from.id or ""))
  elseif c=="ping" then send(cid,"🏠 HOME LAND PRO يعمل.\n"..rights)
  elseif c=="stats" then local x=s.stats; send(cid,"📊 رسائل "..x.messages.." | محذوفة "..x.deleted.." | انضمام "..x.joins.." | مغادرة "..x.leaves.." | ألعاب "..x.games)
  elseif c=="coin" or c=="dice" then s.stats.games=s.stats.games+1; save(); send(cid,c=="coin" and (math.random(2)==1 and "صورة 🪙" or "كتابة 🪙") or ("🎲 "..math.random(1,6)))
  elseif c=="ban" or c=="kick" or c=="mute" or c=="unmute" or c=="warn" or c=="warnings" or c=="clearwarn" then if group(chat) then moderate(m,c,arg) else send(cid,"استخدمه داخل كروب.") end
  elseif c=="antilink" or c=="antispam" or c=="goodbye" then if not group(chat) or not admin(cid,m.from.id) then send(cid,"للمشرفين فقط.") elseif arg=="on" or arg=="off" then s[c=="antilink" and "antilink" or c=="antispam" and "antispam" or "goodbye"]=(arg=="on"); save(); send(cid,"تم تحديث الإعداد.") else send(cid,"استخدم on أو off.") end
  elseif c=="welcome" then if group(chat) and admin(cid,m.from.id) and arg~="" then s.welcome=arg; save(); send(cid,"تم حفظ الترحيب.") else send(cid,"للمشرفين: /welcome نص (يدعم {name})") end
  elseif c=="custom" then if group(chat) and admin(cid,m.from.id) then local k,v=arg:match("^([^|]+)|(.+)$"); if k and v then s.custom[k:lower():match("^%s*(.-)%s*$")]=v; save(); send(cid,"تم حفظ الرد.") else send(cid,"/custom كلمة | الرد") end else send(cid,"للمشرفين فقط.") end
  elseif c=="delcustom" then if group(chat) and admin(cid,m.from.id) then s.custom[arg:lower()]=nil; save(); send(cid,"تم الحذف إذا كان موجوداً.") end
  elseif c=="rank" then if group(chat) and admin(cid,m.from.id) then local tid=target(m); if tid and (arg=="مدير" or arg=="مميز" or arg=="موثوق") then s.ranks[tostring(tid)]=arg; save(); send(cid,"تم تعيين الرتبة "..arg) elseif tid and arg=="عادي" then s.ranks[tostring(tid)]=nil; save(); send(cid,"تمت إزالة الرتبة.") else send(cid,"رد على عضو: /rank مدير|مميز|موثوق|عادي") end end
  else local v=s.custom[c]; if v then send(cid,v) end end
 else local v=s.custom[text:lower()]; if v then send(cid,v) end end
 if group(chat) and s.stats.messages%25==0 then save() end
end
load(); math.randomseed(os.time()); print("HOME LAND PRO started | @FFF70F | @Bb_1_p")
local offset=0
while true do
 local updates,err=api("getUpdates",{offset=offset,timeout=25,allowed_updates={"message","callback_query"}})
 if updates then for _,u in ipairs(updates) do offset=u.update_id+1; local ok,e=pcall(function() if u.message then process(u.message) elseif u.callback_query then callback(u.callback_query) end end); if not ok then io.stderr:write("Handler error: "..tostring(e).."\n") end end
 else io.stderr:write("Polling error: "..tostring(err).."\n"); socket.sleep(5) end
end
