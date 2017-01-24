-- Version 2.0

--[[----------------------------------------------------------------
This plugin draws 8va/15ma/22ma (bassa) markings in a score by looking for 
Instrument Change commands with a Transpose settings corresponding to one, 
two or three octaves upward/downward. The markings include a starting label
and dashed line that spans systems when required. Settings are available 
to customize the style and appearance of the markings.

To use the object, insert a copy at the start of each staff which will use 
the markings. Then insert Instrument Change commands at the start and end 
of each section that you wish to mark, with the starting instrument change
having an effective transpose of 12, -12, 24, -24, 36 or -36 and the 
ending instrument change having an effective transpose of 0.  If you want to 
discontinue 8va markings in your score, insert another copy of the object 
and set its visibility to Never. To re-enable the markings, add another 
visible one later in the score.
@UpOneText
Label text to use for transposing up one octave. The default setting is "8va".
@DownOneText
Label text to use for transposing down one octave. The default setting is "8va bassa".
@UpTwoText
Label text to use for transposing up two octaves. The default setting is "15ma".
@DownTwoText
Label text to use for transposing down two octaves. The default setting is "15ma bassa".
@UpThreeText
Label text to use for transposing up three octaves. The default setting is "22ma".
@DownThreeTextText
Label text to use for transposing down three octaves. The default setting is "22ma bassa".
@Courtesy
Determines whether "( )" should be added around the label when a section 
extends from the previous system. The default setting is enabled (checked).
@IncludeRests
This will allow an 8va section to include beginning or trailing rests. Normally, 
the markings will be automatically positioned at the first and last notes 
between the instrument changes (which is standard engraving practice). 
When this setting is enabled, leading and trailing rests in this section 
will also be included. The default setting is disabled (unchecked).
@SuppressLine
Determines whether the dashed line should be suppressed for sections which are shorter
than the label text (e.g. single notes). The default setting is disabled (unchecked), 
which draws lines for all sections.
@StaffTranspose
Staff transposition value, to allow for non-C instrument parts. This should be set to the 
transpose value for the staff's default instrument. The default setting is 0.

When using 8va markings on transposed staves, this value should be taken into 
account for the Instrument Change commands that start and end each marked 
section. For example, a Bb clarinet staff would generally have a staff instrument 
transpose of -2. Therefore, an 8va section for this instrument would have starting 
and ending transpose values of 10 and -2.
@StartOffset
Horizontal offset for the position of the label text, relative to the first note or rest
of the 8va section. The range of values is -10.0 to 10.0, and the default value is 0.
@EndOffset
Horizontal offset for the position of the ending tail, relative to the last note or rest
of the 8va section. The range of values is -10.0 to 10.0, and the default value is 0.
--]]----------------------------------------------------------------
if nwcut then
	local userObjTypeName = arg[1]
	local score = nwcut.loadFile()
	local staffTrans = 0
	local markTrans = { ['22ma']=36, ['15ma']=24, ['8va']=12, ['8va bassa']=-12, ['15ma bassa']=-24, ['22ma bassa']=-36 }
	local markType = nwcut.prompt('Type:', '|22ma|15ma|8va|8va bassa|15ma bassa|22ma bassa', '8va')
	local trans = markTrans[markType]
	local pos = trans > 0 and 10 or -10
	
	local function getStaffTrans(o)
		if o:IsFake() and o.ObjType == 'Instrument' and not o.Opts.DynVel then
			staffTrans = o.Opts.Trans
		end
	end
	
	local function insertInstrChange(trans, pos)
		local o = nwcItem.new('|Instrument')
		o.Opts.Trans = trans
		o.Opts.Pos = pos
		return o
	end

	local staff, i1, i2 = score:getSelection()
	score:forSelection(getStaffTrans)
	table.insert(staff.Items, i1, insertInstrChange(trans + staffTrans, pos))
	staff:add(insertInstrChange(staffTrans, pos))
	score:setSelection(staff)
	score:save()
	return
end

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local user = nwcdraw.user
local transposeLookup = { [12] = 1, [-12] = -1, [24] = 2, [-24] = -2, [36] = 3, [-36] = -3 }
local labelTextLookup = { [-3] = 'DownThreeText', [-2] = 'DownTwoText', [-1] = 'DownOneText', [1] = 'UpOneText', [2] = 'UpTwoText', [3] = 'UpThreeText' }
local priorUser8va = nwc.ntnidx.new()
local nextUser8va = nwc.ntnidx.new()
local priorPatch = nwc.ntnidx.new()
local nextPatch = nwc.ntnidx.new()
local edgeNotePos = nwc.drawpos.new()
local endOfStaff = nwc.drawpos.new()

local dtt = { int='#', float='#.#' }

local menu_Ottavamatic = {}

local spec_Ottavamatic = {
	{ id='UpOneText', label='+1 &Octave Text', type='text', default='8va' },
	{ id='DownOneText', label='-1 &Octave Text', type='text', default='8va bassa' },
	{ id='UpTwoText', label='+2 &Octave Text', type='text', default='15ma' },
	{ id='DownTwoText', label='-2 &Octave Text', type='text', default='15ma bassa' },
	{ id='UpThreeText', label='+3 &Octave Text', type='text', default='22ma' },
	{ id='DownThreeText', label='-3 &Octave Text', type='text', default='22ma bassa' },
	{ id='Courtesy', label='Add Courtesy Marks', type='bool', default=true },
	{ id='IncludeRests', label='Include Rests', type='bool', default=false },
	{ id='SuppressLine', label='Suppress Line for Short Sections', type='bool', default=false },
	{ id='StaffTranspose', label='Staff Transpose', type='int', default=0, min=-120, max=120 },
	{ id='StartOffset', label='Start Offset', type='float', default=0, min=-10, max=10, step=0.1 },
	{ id='EndOffset', label='End Offset', type='float', default=0, min=-10, max=10, step=0.1 },
}

for k, s in ipairs(spec_Ottavamatic) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type == 'enum' then
		a.type = 'choice'
		a.list = s.list
	else
		a.type = 'command'
	end
	menu_Ottavamatic[#menu_Ottavamatic+1] = a
end

local function menuInit_Ottavamatic(t)
	for _, m in ipairs(menu_Ottavamatic) do
		local s = spec_Ottavamatic[m.data]
		local v = t[s.id]
		if s.type == 'bool' then
			m.checkmark = v
		elseif s.type == 'enum' then
			m.default = v
		else
			m.name = string.format('%s\t%s', s.label, v)
		end
	end
end

local function menuClick_Ottavamatic(t, menu, choice)
	local m = menu_Ottavamatic[menu]
	local s = spec_Ottavamatic[m.data]
	local v = t[s.id]
	if s.type == 'bool' then
		t[s.id] = not v
	elseif s.type == 'enum' then
		t[s.id] = m.list[choice]
	else
		local dt = s.type == 'text' and '*' or string.format('%s[%s,%s]', dtt[s.type], s.min, s.max)
		t[s.id] = nwcui.prompt(string.format('Enter %s:', string.gsub(s.label, '&', '')), dt, v)
	end
end

local function find8vaEdge(idx, dir, t)
	if not idx:find(dir, 'objType', 'Instrument') then return false end
	local trans = (tonumber(idx:objProp('Trans')) or 0) - t.StaffTranspose
	return transposeLookup[trans] or 0
end

local function drawShift(drawpos1, drawpos2, extendingSection, endOfSection, shiftDir, y, t)
	local x1 = drawpos1:xyAnchor()+t.StartOffset
	local x2 = endOfSection and drawpos2:xyRight()+.5+t.EndOffset or drawpos2:xyAnchor() 
	local tail = shiftDir > 0 and 2 or -2
	local label = t[labelTextLookup[shiftDir]] or ''
	local addParens = extendingSection and t.Courtesy
	local labelPrefix = addParens and '(' or ''
	local labelSuffix = addParens and ')' or ''
	local labelFull = labelPrefix .. label .. labelSuffix
	local w,h,d = nwcdraw.calcTextSize(labelFull)
	local y2 = shiftDir > 0 and y-h+d or y-d
	x2 = math.max(x2, x1+w+1)
	nwcdraw.moveTo(x1, y2)
	if shiftDir > 0 and label:match('^%d+') then
		local part1, part2 = label:match('(%d*)(%D*)')
		part1 = labelPrefix .. (part1 or '')
		nwcdraw.text(part1)
		nwcdraw.moveBy(0, d*.95)
		nwcdraw.text(part2)
		if labelSuffix ~= '' then
			nwcdraw.moveBy(0, -d*.95)
			nwcdraw.text(labelSuffix)
		end
	else
		nwcdraw.text(labelFull)
	end
	if x2 > x1+w+1 or not t.SuppressLine then
		nwcdraw.line(x2, y, x1+w+.25, y)
		if endOfSection then nwcdraw.line(x2, y, x2, y-tail) end
	end
end

local function create_Ottavamatic(t)
	t.Class = 'StaffSig'
end

local function draw_Ottavamatic(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	if not nwcdraw.isDrawing() then return w end
	if user:isHidden() then return end

	local _, my = nwcdraw.getMicrons()
	local penWidth = my*.315
	local drawpos = nwc.drawpos
	local yOffset = user:staffPos()
	local what = t.IncludeRests and 'noteOrRest' or 'note'
	nwcdraw.setFontClass('StaffItalic')
	nwcdraw.setFontSize(5)
	nwcdraw.setPen('dash', penWidth)
	nwcdraw.alignText('bottom', 'left')
	if not priorUser8va:find('prior', 'user', userObjTypeName) then priorUser8va:find('first') end
	if not nextUser8va:find('next', 'user', userObjTypeName) then nextUser8va:find('last') end
	if not drawpos:find('next', what) then return end
	endOfStaff:find('last')
	priorPatch:find(drawpos)
	nextPatch:find(drawpos)
	local priorShift = find8vaEdge(priorPatch, 'prior', t)
	local yPos = priorPatch:staffPos()
	if priorPatch < priorUser8va then priorPatch:find(priorUser8va) end
	repeat
		local nextShift = find8vaEdge(nextPatch, 'next', t)
		local nextPatchYPos = nextPatch:staffPos()
		if not nextShift then nextPatch:find('last') end
		if nextPatch > nextUser8va then nextPatch:find(nextUser8va) end
		if priorShift and (priorShift ~= 0) and (priorPatch < nextUser8va) then
			priorPatch:find('next', what)
			local extendingSection = priorPatch < drawpos
			local endOfSection = true
			priorPatch:find(nextPatch) 
			priorPatch:find('prior', what)
			if not edgeNotePos:find(priorPatch) then
				endOfSection = false
				edgeNotePos:find(endOfStaff)
			end
			drawShift(drawpos, edgeNotePos, extendingSection, endOfSection, priorShift, yPos-yOffset, t)
		end
		yPos = nextPatchYPos
		priorShift = nextShift
	until not (priorShift and (nextPatch < nextUser8va) and priorPatch:find(nextPatch) and drawpos:find(priorPatch) and drawpos:find('next', what))
end

local function transpose_Ottavamatic(t, semitones, notepos, updpatch)
	if updpatch then
		t.StaffTranspose = t.StaffTranspose - semitones
	end
end

return {
	nwcut = { ['Apply'] = 'ClipText' },
	spec = spec_Ottavamatic,
	create = create_Ottavamatic,
	width = draw_Ottavamatic,
	draw = draw_Ottavamatic,
	transpose = transpose_Ottavamatic,
	menu = menu_Ottavamatic,
	menuInit = menuInit_Ottavamatic,
	menuClick = menuClick_Ottavamatic,
}
