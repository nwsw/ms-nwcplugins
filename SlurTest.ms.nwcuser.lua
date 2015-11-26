-- Version 0.1

--[[----------------------------------------------------------------
This plugin draws a solid, dashed or dotted slur with adjustable end point positions and curve shape. 
It can be used for special situations where a normal slur does not work well, such as a slur-within-a-slur, or for 
"conditional" slurs for different verses on a vocal staff. This object is ornamental only, and does not affect playback.

To add a slur, insert the user object immediately before the note/chord where you want the slur to start. 
The slur object will detect the starting and ending chords' position, duration, stem direction and slur direction 
settings, and will determine curvature strength, direction and end points that are appropriate for most 
situations. These settings can be overridden by use of various parameters.
@Span
The number of notes/chords to include in the slur. The minimum value is 2, which is the default setting.
@Pen
The type of line to draw for the slur: solid, dash or dot. The solid line type will create a shaped Bezier 
curve that is thinner at the end points, similar in appearance to regular Noteworthy slurs. The dot and dash 
line types are drawn with a uniform line thickness. The default value is solid.
@Dir
The direction of the slur: Default, Upward or Downward. When set to Default, the slur will take its direction 
from the starting note's Slur Direction property, which in turn is based on the stem directions of the starting 
and ending notes. When set to Upward or Downward, the slur direction is set explicitly.

Note that upward slurs are positioned at the top notes of the starting and ending chords, while downward 
slurs are positioned at the bottom notes. For starting or ending rests, the default endpoints will be the same
as for normal slurs.
@StartOffsetX
This will adjust the auto-determined horizontal (X) position of the slur's start point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@StartOffsetY
This will adjust the auto-determined vertical (Y) position of the slur's start point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the auto-determined horizontal (X) position of the slur's end point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the auto-determined vertical (Y) position of the slur's end point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@Strength
This will adjust the strength (shape) of the curve. The range of values is 0.00 to 10.00, where a value 
of 1 is the auto-determined curve strength. Lower values will result in a shallower curve, and stronger 
values a steeper curve. A value of 0 results in a straight line. The default setting is 1.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local dirList = { 'Default', 'Upward', 'Downward' }
local dirNum = { Default=0, Upward=1, Downward=-1 }
local paramNameList = { '&Span', 'Start Offset &X', 'Start Offset &Y', 'End Offset &X', 'End Offset &Y', 'S&trength', '&Pitch' }
local paramIdList = { 'Span', 'StartOffsetX', 'StartOffsetY', 'EndOffsetX', 'EndOffsetY', 'Strength', 'Pitch' }
local paramIncList = { 1, .1, .1, .1, .1, .1, .01 }
local showAnchors = false
local adjustParam = 1

local menu_Slur = {
	{ type='command', name='&Show Anchors', disable=false },
	{ type='choice', name='&Adjust Parameter', default=nil, list=paramNameList, disable=false },
}

local function menuInit_Slur(t)
	menu_Slur[1].checkmark = showAnchors
	menu_Slur[2].default = paramNameList[adjustParam]
end

local function menuClick_Slur(t, menu, choice)
	local m = menu_Slur[menu]
	if m.type == 'command' then
		showAnchors = not showAnchors
	else
		adjustParam = choice
	end
end

local spec_Slur = {
	{ id='Span', label='Note Span', type='int', default=2, min=2 },
	{ id='Pen', label='Line Type', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='Dir', label='Direction', type='enum', default='Default', list=dirList },
	{ id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Strength', label='Strength', type='float', default=1, min=0, max=10, step=0.1 },
	{ id='Pitch', label='Pitch', type='float', default=0.5, min=0, max=0.5, step=0.01 },
}

local function box(x, y)
	nwcdraw.moveTo(x, y)
	nwcdraw.roundRect(0.2)
end

local function noteStuff(item, slurDir)
	local opts = item:objProp('Opts') or ''
	local stem, slur, baseNote, dotted
	local slurNote = 1
	if item:isSplitVoice() and item:objType() ~= 'RestChord' then
		slur = slurDir == 0 and item:stemDir() or slurDir
		if slur == 1 then slurNote = item:noteCount() end
		stem = item:stemDir(slurNote)
		baseNote, dotted = item:durationBase(slurNote), item:isDotted(slurNote)
	else
		stem = item:stemDir()
		baseNote, dotted = item:durationBase(), item:isDotted()
		slur = slurDir == 0 and (dirNum[opts:match('Slur=(%a+)')] or -stem) or slurDir 
	end
	local arcPitch, noteheadOffset = 3.75, .5
	if baseNote == 'Whole' and dotted then
		arcPitch, noteheadOffset = 7.75, .65
	elseif baseNote == 'Whole' then
		arcPitch, noteheadOffset = 5.75, .65
	elseif baseNote == 'Half' then
		arcPitch = 5.75
	end
	return stem, slur, arcPitch, noteheadOffset, baseNote
end

local function draw_Slur(t)
	local xyar = nwcdraw.getAspectRatio()
	local _, my = nwcdraw.getMicrons()
	local solidPenWidth, dotDashPenWidth = my*0.12, my*.375
	local span = t.Span
	local pen = t.Pen
	local dir = dirNum[t.Dir]
	local strength = t.Strength
	local startOffsetX, startOffsetY = t.StartOffsetX, t.StartOffsetY
	local endOffsetX, endOffsetY = t.EndOffsetX, t.EndOffsetY
	startNote:find('next', 'noteOrRest')
	for i = 1, span do
		if not endNote:find('next', 'noteOrRest') then return end
	end
	local startStem, slurDir, ya, xo1, startNotehead = noteStuff(startNote, dir)
	local endStem, _, _, xo2, endNotehead = noteStuff(endNote, slurDir)

	ya = ya * strength * .65
	if dir ~= 0 then slurDir = dir end
	local x1, y1, x2, y2
	local startObjType, endObjType = startNote:objType(), endNote:objType()
	if startObjType == 'Rest' then
		local xl, yl = startNote:xyAnchor()
		local xr, yr = startNote:xyRight()
		x1, y1 = (xl + xr) * .5 + startOffsetX, yl + startOffsetY + slurDir * 4
	elseif startObjType == 'RestChord' and startStem == slurDir then
		local xl, yl = startNote:xyAnchor(startStem)
		local xr, yr = startNote:xyRight(startStem)
		x1, y1 = (xl + xr) * .5 + startOffsetX, yl + startOffsetY + slurDir * 2
	else
		local startNoteYBottom, startNoteYTop = startNote:notePos(1) or 0, startNote:notePos(startNote:noteCount()) or 0
		x1 = startNote:xyStemAnchor(startStem) or startNote:xyRight(startStem)
		if (slurDir == -1 and startStem == 1) or (slurDir == 1 and startStem == 1 and startNotehead == 'Whole') then xo1 = -xo1 end
		x1 = x1 + startOffsetX + xo1
		y1 = (slurDir == 1) and startNoteYTop + startOffsetY + 1.75 or startNoteYBottom - startOffsetY - 1.75
	end
	if endObjType == 'Rest' then
		local xl, yl = endNote:xyAnchor()
		local xr, yr = endNote:xyRight()
		x2, y2 = (xl + xr) * .5 + endOffsetX, yl + endOffsetY + slurDir * 4
	elseif endObjType == 'RestChord' and endStem == slurDir then
		local xl, yl = endNote:xyAnchor(endStem)
		local xr, yr = endNote:xyRight(endStem)
		x2, y2 = (xl + xr) * .5 + endOffsetX, yl + endOffsetY + slurDir * 2
	else
		local endNoteYBottom, endNoteYTop = endNote:notePos(1) or 0, endNote:notePos(endNote:noteCount()) or 0
		x2 = endNote:xyStemAnchor(endStem) or endNote:xyAnchor(endStem)
		if (slurDir == 1 and endStem == -1) or (slurDir == 1 and endStem == -1 and endNotehead == 'Whole') then xo2 = -xo2 end
		x2 = x2 + endOffsetX - xo2
		y2 = (slurDir == 1) and endNoteYTop + endOffsetY + 1.75 or endNoteYBottom - endOffsetY - 1.75
	end
	local xa = x1 + (x2-x1) * t.Pitch
	local xb = x1 + (x2-x1) * (1-t.Pitch)
	local m = (y2-y1)/(x2-x1)
	local ya0 = y1 + (y2-y1) * t.Pitch
	local yb0 = y1 + (y2-y1) * (1-t.Pitch)
	local ya1 = ya0 + slurDir * ya
	local yb1 = yb0 + slurDir * ya
	nwcdraw.moveTo(x1, y1)
	if t.Pen == 'solid' then
		local bw = startNote:isGrace() and .1 or .2
		nwcdraw.setPen(t.Pen, solidPenWidth)
		nwcdraw.beginPath()
		nwcdraw.bezier(xa, ya1+bw, xb, yb1+bw, x2, y2)
		nwcdraw.bezier(xb, yb1-bw, xa, ya1-bw, x1, y1)
		nwcdraw.endPath()
		if showAnchors then
			box(x1, y1)
			box(xa, ya1)
			box(xa, ya0)
			box(xb, yb1)
			box(xb, yb0)
			box(x2, y2)
		--nwcdraw.line(x1,y1,x2,y2)
		end
	else
		nwcdraw.setPen(t.Pen, dotDashPenWidth)
		nwcdraw.bezier(xa, ya1, xb, yb1, x2, y2)
	end
end

local function spin_Slur(t, d)
	local x = paramIdList[adjustParam] or 1
	t[x] = t[x] + d*paramIncList[adjustParam]
	t[x] = t[x]
end

return {
	spec = spec_Slur,
	spin = spin_Slur,
	draw = draw_Slur,
	menu = menu_Slur,
	menuInit = menuInit_Slur,
	menuClick = menuClick_Slur,
}
