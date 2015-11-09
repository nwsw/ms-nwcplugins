-- Version 1.3

--[[----------------------------------------------------------------
This will draw a glissando line between two notes, with optional text above the line. If either of the notes is a chord, the bottom notehead
of that chord will be the starting or ending point of the line. It is strictly an ornament, and has no effect on playback.
@Pen
Specifies the type for lines: solid, dot, dash or wavy. The default setting is solid.
@Text
The text to appear above the glissando line, drawn in the StaffItalic system font. The default setting is "gliss."
@Scale
The scale factor for the text above the glissando line. This is a value from 5% to 400%, and the default setting is 75%.

The text scale factor can be incremented/decremented by selecting the object and pressing the + or - keys.
@StartOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@StartOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@Weight
This will adjust the weight (thickness) of both straight and wavy line types. The range of values is 0.0 to 5.0, where 1 is the standard line weight. The default setting is 1.
--]]----------------------------------------------------------------

local nextNote = nwc.drawpos.new()
local priorNote = nwc.drawpos.new()
local lineStyles = { 'solid', 'dot', 'dash', 'wavy' }
local squig = '~'

local spec_Glissando = {
	{ id='Pen', label='Line Style', type='enum', default=lineStyles[1], list=lineStyles },
	{ id='Text', label='Text', type='text', default='gliss.' },
    { id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=75 },
    { id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Weight', label='Line Weight', type='float', default=1, min=0, max=5, step=0.1 }
}

local function audit_Glissando(t)
	if t.Style then
		if (t.Style == 'Wavy') then t.Pen = 'wavy' end
		t.Style = nil
	end
end

local function draw_Glissando(t)
	local xyar = nwcdraw.getAspectRatio()
    local _, my = nwcdraw.getMicrons()
	local pen, text, weight = t.Pen, t.Text, t.Weight
	local thickness = my*.3*weight
	local xo, yo = .25, .5
	
	if not priorNote:find('prior', 'note') then return end
	if not nextNote:find('next', 'note') then return end
	
	local x1 = priorNote:xyRight()
    local y1 = priorNote:notePos(1)
	x1 = x1 + xo + t.StartOffsetX
	local y2 = nextNote:notePos(1)
	local x2 = t.EndOffsetX - xo
    local s = y1>y2 and 1 or y1<y2 and -1 or 0
	y1 = y1 - yo*s + t.StartOffsetY
	y2 = y2 + yo*s + t.EndOffsetY
	local angle = math.deg(math.atan2((y2-y1), (x2-x1)*xyar))
	if text ~= '' then
		nwcdraw.alignText('bottom', 'center')
		nwcdraw.setFontClass('StaffItalic')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*t.Scale*.01)
		nwcdraw.moveTo((x1+x2)*.5, (y1+y2)*.5)
		nwcdraw.text(text, angle)
	end
	if pen ~= 'wavy' then
		if thickness ~= 0 then
			nwcdraw.setPen(pen, thickness)	
			nwcdraw.line(x1, y1, x2, y2)
		end
	else
		nwcdraw.alignText('baseline', 'left')
		nwcdraw.setFontClass('StaffSymbols')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*weight)
		local w = nwcdraw.calcTextSize(squig)
		local len = math.sqrt((y2-y1)^2 + ((x2-x1)*xyar)^2)
		local count = math.floor(len/w/xyar)
		nwcdraw.moveTo(x1, y1-1)
		nwcdraw.text(string.rep(squig, count), angle)
	end
end

local function spin_Glissando(t, d)
	t.Scale = t.Scale + d*5
	t.Scale = t.Scale
end

return {
	spec = spec_Glissando,
	audit = audit_Glissando,
	spin = spin_Glissando,
	draw = draw_Glissando
}
