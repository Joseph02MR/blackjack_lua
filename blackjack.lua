-- title:   blackjack
-- author:  joseph02, email, etc.
-- desc:    simple blackjack port in lua
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

function BOOT()
	T=0
	DRAWN=false
	SW=8  --spr width
	CS=30 --card space
	CSS=18 --card short space

	XB=160 --coordinates for initial button
	YB=110

	PCARDS={} --play cards
	local deck_ptr=1
	DNUM=0
	for i=1,4 do
		for j=1,13 do
			PCARDS[deck_ptr]={i,j}
			deck_ptr=deck_ptr+1
		end
	end
	PDECK={}

	PLAYED={}
	PLAYED_PTR=0

	DEALER={}
	PLAYER={}

	P_BJ=false --blackjack flags
	D_BJ=false

	P_BUSTED=false --busted flags
	D_BUSTED=false

	CURRENT_CARD=0

	D_HEIGHT=5 --dealer card height
	P_HEIGHT=60 --players card heigth

	--TIC AUX
	DEALT=0
	GAME_END=false
	DEALER_SHOW=false
	ACTIONABLE=false
	ACTIVE_BTNS={0,0,0,0}
	EVAL=false
	RESULT=""
end



function shuffle(darr,dsize)
	for i=dsize,1,-1 do
		local j=math.random(1,i)
		local tmp=darr[i]
		darr[i]=darr[j]
		darr[j]=tmp
	end
end

function create_deck(deck_num)
	local aux={}
	local k=0
	local ptr=1
	repeat
		for i=1,52 do
			aux[ptr]=i
			ptr=ptr+1
		end
		k=k+1
	until(deck_num==k)
	shuffle(aux,#aux)
	DNUM=deck_num
	return aux
end

function sel_tile(x,y)
	if x==0 and y==0 then return 0;
		elseif x==0 and y==3 then return 1
		elseif x==2 and y==0 then return 2
		elseif x==2 and y==3 then return 3
		else return 4;
	end
end

function draw_card(card,x,y)
	for i=0,3,1	do
		for j=0,2,1 do
			spr(sel_tile(j,i),(SW*j)+x,(SW*i)+y,0,1,0,0,1,1)
		end
	end

 	local c=31+PCARDS[card][1]
 	local n=47+PCARDS[card][2]
	spr(c,(SW+x),(SW+y) ,0,1,0,0,1,1);
	spr(n,(SW+x),(SW*2)+y+1,0,1,0,0,1,1);
end

function draw_back(x,y)
	local aux=0
	for i=0,3,1	do
		for j=0,2,1 do
			spr(16+aux,(SW*j)+x,(SW*i)+y,0,1,0,0,1,1)
			aux=aux+1
		end
	end
end

function update_played(card,owner)
	PLAYED_PTR=PLAYED_PTR+1
	PLAYED[PLAYED_PTR] = {card,owner}
end

function first_deal()
	local card=1
	for cn=1,2 do
		PLAYER[cn]=PDECK[card]
		update_played(PLAYER[cn],1)
		PDECK[card]=0
		card=card+1
		DEALER[cn]=PDECK[card]
		update_played(DEALER[cn],0)
		PDECK[card]=0
		card=card+1
	end
	return card
end

function deal(owner, card)
	local aux=-1
	owner[#owner+1]=PDECK[card]
	if owner==PLAYER then aux=1
	else aux=0
	end
	update_played(owner[#owner],aux)
	card=card+1
	return card
end

function draw(cards, DEALER_SHOW)
	local increment=0
	local pinc=0
	local dinc=0
	for i=1, cards do
		if i==4 and not DEALER_SHOW then
			draw_back(80+(increment)*CSS,D_HEIGHT)
		else
			if PLAYED[i][2]~=0 then
				if i>4 then pinc=pinc+1 end
				draw_card(PLAYED[i][1],80+(increment+pinc)*CSS,P_HEIGHT)
			else
				if i>4 then dinc=dinc+1 end
				draw_card(PLAYED[i][1],80+(increment+dinc)*CSS,D_HEIGHT)
			end
		end
		if i%2==0 and i<=4 then increment=increment+1 end
	end
end

function draw_buttons()
	local aux=0
	for i=0, 3 do
		if ACTIVE_BTNS[i+1]==i+1 then aux=5 else aux=9 end
		spr(aux+i,XB-(i*34),YB,0,2,0,0,1,1)
		line(XB+2-(i*34),YB-2,XB+13-(i*34),YB-2,8)
		line(XB+2-(i*34),YB-1,XB+13-(i*34),YB-1,8)
	end
end

function eval_count(owner)
	local id=-1
	if owner==PLAYER then id=1 else id=0 end
	local pcnt=0
	local aux=0
	local aces=0
	for i=1,#owner do
		aux=PCARDS[owner[i]][2]
		if aux >=2 and aux <=10 then pcnt=pcnt+aux
		elseif aux==11 or aux==12 or aux==13 then pcnt=pcnt+10
		else aces=aces+1
		end
	end
	if aces>0 then
		local add=0
		for i=1, aces do
			if pcnt+(i+10)<=21 then add=i+10 else add=i end
		end
		pcnt=pcnt+add
	end
	if pcnt==21 and #owner==2 then
		if id==1 then P_BJ=true else D_BJ=true end
	end
	if pcnt>21 then
		if id==1 then P_BUSTED=true else D_BUSTED=true end
	end
	return pcnt
end

function dealer_play()
	local dcnt=eval_count(DEALER)
	if dcnt<=16 then
		deal(DEALER,CURRENT_CARD)
		dcnt=eval_count(DEALER)
		DEALT=DEALT+1
	else EVAL=true
	end
end

function eval_options()
	if GAME_END then ACTIVE_BTNS = {0,0,0,0} else
		local pcnt=eval_count(PLAYER)
		if pcnt<21 then ACTIVE_BTNS[1]=1 else ACTIVE_BTNS[1]=0 end --hit
		if pcnt<21 then ACTIVE_BTNS[4]=4 else ACTIVE_BTNS[4]=0 end --stand
		if #PLAYER==2 then ACTIVE_BTNS[2]=2 else ACTIVE_BTNS[2]=0 end --double
		if PCARDS[PLAYER[1]][2]==PCARDS[PLAYER[2]][2] then ACTIVE_BTNS[3]=3 else ACTIVE_BTNS[3]=0 end --split
	end
end


function draw_selected()
	local mx,my=mouse()
	local x_in=false
	local y_in=false
	local b=-1
	for i=0, 3 do
		if(XB-(i*34) < mx and mx < XB-(i*34)+16) then x_in=true
			if(YB < my and my < YB+16) then
				y_in=true
				b=i
			end
		end
	end
	if y_in and x_in then
		if ACTIVE_BTNS[b+1]==b+1 then spr(14,XB-(b*34)-2,YB-4,0,2,0,0,2,2) end
	end
end

function eval_click()
	local mx,my,ml=mouse()
	local x_in=false
	local y_in=false
	local b=-1
	for i=0, 3 do
		if(XB-(i*34) < mx and mx < XB-(i*34)+16) then x_in=true
			if(YB < my and my < YB+16) then
				y_in=true
				b=i
			end
		end
	end
	if y_in and x_in then
		if ml and ACTIONABLE and not GAME_END then button_click(b); ACTIONABLE=false; eval_options() end
	end
	if not ml then ACTIONABLE=true end
end

function eval_pressed() --falta corregir multiaccion
	if btn(4) and ACTIONABLE then hit();ACTIONABLE=false;
	elseif btn(5) and ACTIONABLE then stand(); ACTIONABLE=false;
	elseif btn(6) and ACTIONABLE then double(); ACTIONABLE=false;
	elseif btn(7) and ACTIONABLE then split(); ACTIONABLE=false;
	end
	if not (btn(4) or btn(5) or btn(6) or btn(7)) then ACTIONABLE=true end
end

function button_click(b)
	if b==0 then hit()
	elseif b==1 then double();
	elseif b==2 then split();
	elseif b==3 then stand();
	end
end

function hit()
	print("hit",0,130)
	CURRENT_CARD=deal(PLAYER,CURRENT_CARD)
	DEALT=DEALT+1
end

function double()
	print("double",0,130)
end

function split()
	print("split",0,130)
end

function stand()
	print("stand",0,130)
	GAME_END=true
	DEALER_SHOW=true
end

function eval_game(pcnt, dcnt)
	if P_BUSTED or (D_BJ and not P_BJ) or dcnt>pcnt then RESULT="LOSE" end
	if D_BUSTED or (P_BJ and not D_BJ) or pcnt>dcnt then RESULT="WIN"
	elseif pcnt==dcnt or (P_BJ and D_BJ) then RESULT="PUSH"
	end
	return RESULT
end

function TIC()
	cls(6)
	if not DRAWN then
	PDECK=create_deck(2)
	CURRENT_CARD=first_deal()
	DRAWN = true
	end

	if T%30==0 and DEALT<=4 then
		if DEALT==4 then ACTIONABLE=true; eval_options()
		else DEALT=DEALT+1
		end
	end

	draw(DEALT,DEALER_SHOW)

	draw_selected()
	draw_buttons()
	eval_click()
	--eval_pressed()
	local pcnt=eval_count(PLAYER)
	local dcnt=eval_count(DEALER)

	print(pcnt, 65,P_HEIGHT)
	--print(dcnt, 70,D_HEIGHT)

	if GAME_END and T%30==0 then
		dealer_play()
	end

	if EVAL then
		print(eval_game(pcnt,dcnt), 210,130)
	end


	T=T+1
	print(DEALT,230,0)
	--print(ACTIONABLE,230,124)

--[[ debug-check shuffle	
	aux=0
	z=0
	for i=1,#PDECK do
		print(PDECK[i],z,aux)
		aux=aux+6
		if aux>120 then z=z+20;aux=0 end
	end
	--]]
	local aux2=0
	for i=1,#PLAYER do
		print(PCARDS[PLAYER[i]][1].. " ".. PCARDS[PLAYER[i]][2],0,aux2)
		aux2=aux2+6
	end
	print("dealer",0,aux2)
	aux2=aux2+6
	for i=1,#DEALER do
		print(PCARDS[DEALER[i]][1].." "..PCARDS[DEALER[i]][2],0,aux2)
		aux2=aux2+6
	end

	print(D_BUSTED,0,100)
	print(P_BUSTED,0,106)
	print(D_BJ,0,112)
	print(P_BJ,0,118)
end

--14390
--15052






-- <TILES>
-- 000:0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 001:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc0ccccccc
-- 002:ccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 003:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0
-- 004:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 005:8666666886866868868668688688886886866868868668688666666808888880
-- 006:8aaaaaa88a888aa88a8aa8a88a8aa8a88a8aa8a88a888aa88aaaaaa808888880
-- 007:8488444884844448844844488488884884448848844484488444444808888880
-- 008:8222222882888828828222288288882882222828828888288222222808888880
-- 009:8777777887877878878778788788887887877878878778788777777808888880
-- 010:8999999889888998898998988989989889899898898889988999999808888880
-- 011:8b88bbb88b8bbbb88bb8bbb88b8888b88bbb88b88bbb8bb88bbbbbb808888880
-- 012:8111111881888818818111188188881881111818818888188111111808888880
-- 014:00cccccc0c000000c0000000c0000000c0000000c0000000c0000000c0000000
-- 015:00000000c00000000c0000000c0000000c0000000c0000000c0000000c000000
-- 016:0ccccccccc444444c4322222c4234444c4243222c4242344c4242432c4242423
-- 017:cccccccc44444444222222224444444422222222444444442222222244444444
-- 018:ccccccc0444444cc2222234c4444324c2223424c4432424c2342424c3242424c
-- 019:c4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424
-- 020:3434434343422434342222434322223432222223422222242222222222222222
-- 021:4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424c
-- 022:c4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424
-- 023:2222222222222222422222243222222343222234342222434342243434344343
-- 024:4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424c
-- 025:c4242423c4242432c4242344c4243222c4234444c4322222cc4444440ccccccc
-- 026:44444444222222224444444422222222444444442222222244444444cccccccc
-- 027:3242424c2342424c4432424c2223424c4444324c2222234c444444ccccccccc0
-- 030:c00000000c00000000cccccc0000000000000000000000000000000000000000
-- 031:0c000000c0000000000000000000000000000000000000000000000000000000
-- 032:000ff00000ffff000ffffff0ffffffffffffffffffffffffff0ff0ff00ffff00
-- 033:000ff00000ffff0000ffff000f0ff0f0ffffffffffffffff0f0ff0f000ffff00
-- 034:0220022022222222222222222222222222222222022222200022220000022000
-- 035:0002200000222200022222202222222222222222022222200022220000022000
-- 036:0f000000fff00000f0f000000000000000000000000000000000000000000000
-- 037:0f000000fff000000f0000000000000000000000000000000000000000000000
-- 038:2020000022200000020000000000000000000000000000000000000000000000
-- 039:0200000022200000020000000000000000000000000000000000000000000000
-- 048:0088880008888880088008800880088008888880088008800880088008800880
-- 049:0088880008800880088008800000888000888800088800000880088008888880
-- 050:0088880008000880080008800008880000000880080008800800088000888800
-- 051:0080880008808800080088008800880088888880000088000000880000008800
-- 052:0888888008800000088000000888888000000088088000880880008800888880
-- 053:0088888008800008088000000888888008800088088000880880008800888880
-- 054:0888888808000888080008800000880000008800000880000008800000088000
-- 055:0088888008800088088000880088888008800088088000880888888800888880
-- 056:0088888008800088088000880880008800888888000000880000008800888880
-- 057:0800888088088008080880880808808808088808080888080808800888808880
-- 058:0088888800000880000008800000088000000880000008800880088000888800
-- 059:0088880008800080088000800880008008800080088088800880088800888808
-- 060:0880088008800880088088000888800008808800088088000880088008800880
-- 064:8880000080800000888000008080000080800000000000000000000000000000
-- 065:8880000000800000888000008000000088800000000000000000000000000000
-- 066:8880000000800000088000000080000088800000000000000000000000000000
-- 067:8080000080800000888000000080000000800000000000000000000000000000
-- 068:8880000080000000888000000080000088800000000000000000000000000000
-- 069:8880000080000000888000008080000088800000000000000000000000000000
-- 070:8880000000800000008000000080000000800000000000000000000000000000
-- 071:8880000080800000888000008080000088800000000000000000000000000000
-- 072:8880000080800000888000000080000088800000000000000000000000000000
-- 073:8088800080808000808080008080800080888000000000000000000000000000
-- 074:8880000008000000080000000800000088000000000000000000000000000000
-- 075:8880000080800000808000008800000000800000000000000000000000000000
-- 076:8080000080800000880000008080000080800000000000000000000000000000
-- 089:8000000080000000800000008000000080000000000000000000000000000000
-- 114:0ccccccccc444444c4322222c4234444c4243222c4242344c4242432c4242423
-- 115:cccccccc44444444222222224444444422222222444444442222222244444444
-- 116:ccccccc0444444cc2222234c4444324c2223424c4432424c2342424c3242424c
-- 118:0ccccccccccfccccccfffccccccfcccccccccccccc888ccccc8ccccccc888ccc
-- 119:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 120:ccccccc0cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 130:c4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424
-- 131:3434434343422434342222434322223432222223422222242222222222222222
-- 132:4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424c
-- 134:cccc8ccccc888ccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 135:00ffff0000ffff0000ffff00ff0ff0ffffffffffffffffffff0ff0ff000ff000
-- 136:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 146:c4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424
-- 147:2222222222222222422222243222222343222234342222434342243434344343
-- 148:4242424c4242424c4242424c4242424c4242424c4242424c4242424c4242424c
-- 150:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 151:0888888008800000088000000888888000000088088000880880008800888880
-- 152:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 162:c4242423c4242432c4242344c4243222c4234444c4322222cc4444440ccccccc
-- 163:44444444222222224444444422222222444444442222222244444444cccccccc
-- 164:3242424c2342424c4432424c2223424c4444324c2222234c444444ccccccccc0
-- 166:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc0ccccccc
-- 167:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 168:cccccccccccccccccccffccccffffffccfcffcfcccffffcccccffcccccccccc0
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c650418b13e53ef7d57ffcd75a7f07038b76425717900000028408941a6f6ae894cf4f4f494b0c2566c86333c57
-- </PALETTE>

