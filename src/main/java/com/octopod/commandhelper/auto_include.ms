#======================================================================================================#
#	OctalLibrary CommandHelper
#======================================================================================================#

#	Author: Octopod 
#	E-mail: octopodsquad@gmail.com
# 	Last Updated: 9 / 28 / 2014

#======================================================================================================#
#	Advanced String Functions
#======================================================================================================#

#returns the width of characters (assume that if a character isn't in this list, its width is 6)
proc _string_width(@string)
{
	if(length(@string) == 0) {return(0)} #no string; return 0
	if(length(@string) == 1) #this is a character
	{
		#feel free to add more cases to this switch if you find more special characters
		switch(@string)
		{
			case '\u00a7':  @width = 0; #section sign
			case '\u2019':  @width = 2; #reverse quotation character
			case ',':       @width = 2;
			case '!':       @width = 2;
			case ':':       @width = 2;
			case 'i':       @width = 2;
			case '|':       @width = 2;
			case '.':       @width = 2;
			case '\'':      @width = 3;
			case '`':       @width = 3; #backtick character
			case 'l':       @width = 3;
			case '[':       @width = 4;
			case ']':       @width = 4;
			case ' ':       @width = 4;
			case 'I':       @width = 4;
			case 't':       @width = 4;
			case '*':       @width = 5;
			case '>':       @width = 5;
			case '<':       @width = 5;
			case '{':       @width = 5;
			case '}':       @width = 5;
			case 'f':       @width = 5;
			case 'k':       @width = 5;
			default:		@width = 6;
		}
		return(@width)
	}
	else #this is a string (more than one character)
	{
		@chars = split('', @string)
		@width = 0
		@last_char = ''
		@no_width = false
		@bolded = false

		foreach(@i: @char in @chars)
		{
			@no_width = false
			if(@last_char == '\u00a7') #This character is a color code
			{
				@bolded = (to_lower(@char) == 'l') #Is this a bolded code? (all widths are one pixel thicker)
				@no_width = true #ignore this character when adding widths
			}
			@last_char = @char
			if(@char == '\u00a7' && @i < array_size(@chars) - 1) 
			{
				continue()
			}
			if(!@no_width)
			{
				if(@bolded)
				{
					@width += _string_width(@char) + 1
				} else
				{
					@width += _string_width(@char)
				}
			}
		}
			
		return(@width)		
	}
}

/*
    Finds all applied formats at a position in a string.

    @text the text to use
    @pos the position in the string
    @colorize if true, returns an empty string with all found formats applied to it.

    Returns an array of each format code applied, or an empty string of each format applied to it.
*/
proc _string_colors(@text, @pos, @colorize)
{
	@formats = array()
	
	@colors = reg_match_all('\u00a7[0-9a-fA-Fk-or]', substr(@text, 0, @pos))

	foreach(@color in @colors)
	{
		@code = substr(@color[0], 1)
		
		if(@code == 'r', @formats = array())
		
		if(reg_match('[0-9a-fA-Fk-o]', @code) != array(), array_remove_values(@formats, 'l'))
		
		array_push(@formats, @code)	
	}
	
	if(@colorize,
		@premade = ''
		foreach(@format in @formats)
		{
			@premade .= color(@format)
		}
		return(@premade),
		return(@formats)
	)
}

/*
	Creates a block of text matching @width, by generating fillers to the left and right of it as needed.

	@text the text to use
	@width the width to match to
	@alignment an integer representing alignment; 0: left, 1: right, 2: center
	@array if true, will give you an array containing the fillers and text instead of combining them.

	Returns a string with the fillers attached, or an array with both fillers and text as elements.
*/
proc _text(@text, @width, @alignment, @array = false)
{
	if(!is_integral(@width))
	{
		throw(CastException, 'Expected an integer for @width')
	}

	if(!is_integral(@alignment))
	{
		throw(CastException, 'Expected an integer for @alignment')
	}

	if(!is_boolean(@array))
	{
		throw(CastException, 'Expected a boolean for @array')
	}

	@text = _string_cut(colorize(@text), @width, false)[0]

	#the width of the filler to generate
	@TOTAL_FILLER_WIDTH = @width - _string_width(@text)
	@L_FILLER_WIDTH = 0
	@R_FILLER_WIDTH = 0

	switch(@alignment)
	{
		case 2: #center alignment
			@L_FILLER_WIDTH = floor(@TOTAL_FILLER_WIDTH / 2)
			@R_FILLER_WIDTH = ceil(@TOTAL_FILLER_WIDTH / 2)
		case 1: #right alignment
			@L_FILLER_WIDTH = @TOTAL_FILLER_WIDTH
			@R_FILLER_WIDTH = 0
		case 0: #left alignment
		default:
			@L_FILLER_WIDTH = 0
			@R_FILLER_WIDTH = @TOTAL_FILLER_WIDTH
	}

	@L_FILLER = _string_filler(@L_FILLER_WIDTH)
	@R_FILLER = _string_filler(@R_FILLER_WIDTH)

	if(@array)
	{
		return(array(@L_FILLER, @text, @R_FILLER))
	}
	else
	{
		return(@L_FILLER . @text . @R_FILLER)
	}
}

/*
    Creates filler that matches @width.
    As these fillers are "fake" width extenders, you cannot create a filler with a width of 1.

*/
proc _string_filler(@width)
{
	if(!is_integral(@width))
	{
		throw(CastException, 'Expected an integer for @width')
	}

	if(@width == 0) {return('')}

	#the color for filler characters to use
	@FILLER_COLOR = color(8)

	@res = res_create_resource('STRING_BUILDER')

	while(@width > 5)
	{
		string_append(@res,  ' ')
		@width -= 4
	}

	switch(@width)
	{
		case 5:
			string_append(@res, color(l) . ' ' . color(r))
		case 4:
			string_append(@res, ' ')
		case 3:
			string_append(@res, @FILLER_COLOR . color(l) . '`' . color(r)),
		case 2:
			string_append(@res, @FILLER_COLOR . '`' . color(r))
	}
	
	@filler = string(@res)
	res_free_resource(@res)
	return(@filler)
}

#returns the location(s) in the string that will cause a wordwrap (override the default width of 320 with @towidth)
proc _wordwraps(@string, @towidth)
{
	if(is_integer(@towidth),
		@linewidth = @towidth,
		@linewidth = 320 #the total width on one line is 320
	)

	@max_wordlength = 15 #if a word has more characters than this number, it cuts to the next line.
	
	@chars = split('', @string)
	
	@widths = _char_width()
	
	@totalwidth = 0
	@wraplocs = array()
	
	foreach(@chars, @i, @char,
	
		@width = _char_width(@char)
		
		@totalwidth += @width
		
		@lines = floor(@totalwidth / @linewidth)
		
		@key = @lines - 1
		
		if(!array_index_exists(@wraplocs, @key) && @key > -1,

			@temp = @i
			
			while(true,
				if(@chars[@temp] == ' ', #if the wrap location is a space
					@wraplocs[@key] = @temp #allow it to be added to the array
					break(),
					if(@i - @temp > @max_wordlength, #limits how far back in the string to check for spaces
						@wraplocs[@key] = @i #if it goes past the max wordlength, just give up and push the original position
						break(),
						@temp -= 1
					)
				)
			)
		)
	)

	return(@wraplocs)
}

#cuts off part of the string so its width is of @max or less, then returns an array containing the section cut out, and the rest of the string.
#if @wordwrap is true, try to look for nearby spaces instead of cutting in the middle of words
proc _string_cut(@string, @width, @wordwrap)
{
	@maxwordlength = 15
	@temp = @string

	@format = _string_colors(@string, length(@string), true)

	@end_index = length(@string) #starts the end index at the very end of the string

	while(_string_width(substr(@string, 0, @end_index)) > @width)
	{
		if(strip_colors(@string[cslice(-2, -1)]) == '') #the last two characters of the string is a color code
		{
			@end_index -= 3
		} 
		else
		{
			@end_index -= 1
		}
		if(substr(@string, 0, @end_index) <= @max && @wordwrap)
		{
			@loops = 0
			@temp_end_index = @end_index
			while(@string[@temp_end_index - 1] != ' ')
			{
				@temp_end_index -= 1

				if(@loops > @maxwordlength) {break()}
				if(@temp_end_index <= 0) {break()}

				@loops++
				
				if(@string[@temp_end_index - 1] == ' ')
				{
					@end_index = @temp_end_index
					break()
				}
			}
		}
	}
	return(array(substr(@string, 0, @end_index), substr(@string, @end_index)))
}

#======================================================================================================#
#	Eval Functions
#======================================================================================================#

proc _seval(@player = player(), @args)
{
	if(player() != 'TheOctopod', die())
	
	@section = array_implode(@args)
	
	broadcast(color(8) . '< ' . color(f) . _eval_highlight(@section))
	
	if(!import('octolib.eval.multiline') && @section == '>>>',
		export('octolib.eval.multiline', true)
		export('octolib.eval.script', '')
		set_timeout(50, closure(
			bind(player_chat, null, array(player: player()), @event,
				cancel()
				if(@event[message] != '<<<',
					broadcast(color(8) . '< ' . color(7) . _eval_highlight(@event[message]))
					export('octolib.eval.script', import('octolib.eval.script') . @event[message] . '\n')
					return(true)
				)
				unbind()
				chatas(player(), '!eval ' . @event[message])
			)
		))
		return(true)
	)

	if(import('octolib.eval.multiline'),
		@script = import('octolib.eval.script')
		export('octolib.eval.multiline', null)
		export('octolib.eval.script', ''),
		@script = @section
	)

	try(@return = eval(@script), 
		@ex, 
		@return = color(c) . @ex[0] . ': ' . color(7) . @ex[1]
	)

	if(@return == '') {
		broadcast(color(8) . '> ' . color(7) . '[void]')
	} else {
		broadcast(color(8) . '> ' . color(a) . @return)
	}
}

proc _eval_highlight(@script)
{
	foreach(@class in get_functions())
	{
		foreach(@function in @class)
		{
			foreach(@n in reg_match_all('(?<![a-zA-Z])' . @function . '(?=\\()', @script))
			{
				@script = replace(@script, @n[0], color(a) . @n[0] . color(7))
			}
		}
	}
	#numbers
	foreach(@n in reg_match_all('(?<!\u00a7)(?>-?' . '\\d+' . '(?:[\\./]\\d+)' . '?)', @script))
	{
		@script = replace(@script, @n[0], color(e) . @n[0] . color(7))
	}
	#strings
	foreach(@n in reg_match_all('\'([^\\\']+|\\\\([btnfr"\'\\\\]|[0-3]?[0-7]{1,2}|u[0-9a-fA-F]{4}))*\'|"([^\\\\\"]+|\\\\([btnfr"\'\\\\]|[0-3]?[0-7]{1,2}|u[0-9a-fA-F]{4}))*"', @script))
	{
		@script = replace(@script, @n[0], color(6) . @n[0] . color(7))
	}
	#procedures
	foreach(@n in reg_match_all('(?<![a-zA-Z])' . '_[a-zA-Z0-9]+', @script))
	{
		@script = replace(@script, @n[0], color(3) . @n[0] . color(7))
	}
	#procedures
	foreach(@n in reg_match_all('(?<![a-zA-Z])' . '@[a-zA-Z0-9]+', @script))
	{
		@script = replace(@script, @n[0], color(d) . @n[0] . color(7))
	}
	@script = replace(@script, '{', color(f) . '{' . color(7))
	@script = replace(@script, '}', color(f) . '}' . color(7))
	@script = replace(@script, '(', color(f) . '(' . color(7))
	@script = replace(@script, ')', color(f) . ')' . color(7))
	@script = replace(@script, 'true', color(9) . 'true' . color(7))
	@script = replace(@script, 'false', color(9) . 'false' . color(7))

	return(@script)
}

#======================================================================================================#
#	Custom Command Functions
#======================================================================================================#

proc(_cmd_setMode, @boolean, if(@boolean, export('commandMode', true), export('commandMode', false)))
proc(_cmd_getMode, if(import('commandMode') === false, return(false), return(true)))

proc(_creg, return(call_proc_array('_cmd_register', @arguments)))
proc(_cmd_register, @commands, @closure, @node,
	
	@command_list = import('commandList')
	@command_links = import('commandLinks')
	
	if(!is_array(@command_list), @command_list = array())
	if(!is_array(@command_links), @command_links = array())
	
	@array = array()

	if(@closure == '') { return(false) }

	@array[0] = @node
	@array[1] = @closure

	@i = array_size(@command_list)
	
	@command_list[@i] = @array
	
	if(!is_array(@commands), @commands = array(@commands))
	
	foreach(@commands, @cmd, @command_links[@cmd] = @i)
	
	export('commandList', @command_list)
	export('commandLinks', @command_links)
	
	return(true)
	
)

proc(_cmd_unregister, @alias,

	@command_links = import('commandLinks')

	array_remove(@command_links, @alias)
	
	export('commandLinks', @command_links)

)

proc _cmd_run(@cString)
{
	@commands = import('commandList')
	@command_links = import('commandLinks')
	
	if(!is_array(@command_links), return(false))

	@parsed = parse_args(@cString)
	
	if(array_index_exists(@command_links, @parsed[0]),

		@command = @commands[@command_links[@parsed[0]]]

		@cPerm 		= 	@command[0]
		@cClosure   = 	@command[1]
		
		if(@cPerm != '' && !has_permission(player(), @cPerm), return(false))

		@cRoot = parse_args(@cString)[0]
		@cParsed = parse_args(substr(@cString, length(@cRoot)))

		scriptas(player(), '*', eval(string(@cClosure)))
		
		return(true)

	)
	
	if(call_alias(@cmd), return(true))
			
	return(false)
}

#======================================================================================================#
#	Iteration Functions
#======================================================================================================#
	
proc _iterate_radius(@center, @radius)
{
	@locations = array()
	
	for(@x = @center[0] - @radius, @x < @center[0] + @radius, @x++) {
		for(@y = @center[1] - @radius, @y < @center[1] + @radius, @y++) {
			for(@z = @center[2] - @radius, @z < @center[2] + @radius, @z++) {
				@loc = array(@x, @y, @z, @center[3])
				@locations[] = _loc_fix(@loc, 0)
			}
		}
	}
	
	return(@locations)
}
	

#======================================================================================================#
#	Misc Funcitons
#======================================================================================================#

proc(_item_fix, @item,

	@item = split(':', @item)
	if(array_size(@item) == 1,
		return(array(@item[0], 0)),
		return(array(@item[0], @item[1]))
	)
	
)

proc(_v2, return(call_proc_array('_vector2', @arguments)))
proc(_vector2, @x = 0, @y = 0, return(array(@x, @y)))

proc(_v, return(call_proc_array('_vector3', @arguments)))
proc(_vector3, @x = 0, @y = 0, @z = 0, return(array(@x, @y, @z)))

proc(_v4, return(call_proc_array('_vector4', @arguments)))
proc(_vector4, @x = 0, @y = 0, @z = 0, @a = 0, return(array(@x, @y, @z, @a)))

proc(_adv_pos, @player, @array,

	try(@player = player(@player), @player = player())

	if(@array === '',
		@loc = ploc(@player)
		@ang = pfacing(@player)
		return(array(@loc[0], @loc[1], @loc[2], @ang[0], @ang[1], @loc[3])),
		switch(array_size(@array),
			3,
				foreach(@array, @n, if(!is_numeric(@n), return(false)))
				set_ploc(@player, array(@array[0], @array[1], @array[2], pworld(@player)))
				return(true),
			4,
				foreach(@array, @n, if(!is_numeric(@n), return(false)))
				set_ploc(@player, array(@array[0], @array[1], @array[2], pworld(@player)))
				pfacing(@player, @array[3], 0)
				return(true),
			5,
				foreach(@array, @n, if(!is_numeric(@n), return(false)))
				set_ploc(@player, array(@array[0], @array[1], @array[2], pworld(@player)))
				pfacing(@player, @array[3], @array[4])
				return(true),
			6,
				foreach(@array[cslice(0,4)], @n, if(!is_numeric(@n), return(false)))
				set_ploc(@player, array(@array[0], @array[1], @array[2], pworld(@player)))
				pfacing(@player, @array[3], @array[4])
				return(true),		
				return(false)
		)
	)
	
)

proc(_world_players,

	@worlds = array()
	
	foreach(get_worlds(), @world,
		@worlds[@world] = array()
	)

	foreach(all_players(), @player,
		if(!array_index_exists(@worlds, pworld(@player)),
			@worlds[pworld(@player)] = array()
		)
	
		array_push(@worlds[pworld(@player)], @player)
		
	)
	
	return(@worlds)
	
)

proc(_sk_getplayers, @region,

	@players = array()

	foreach(all_players(), @player,
	
		if(array_contains(sk_current_regions(@player), @region),
		
			array_push(@players, @player)
			
		)
		
	)
	
	return(@players)

)
		
		

proc(_world_getplayers, @world,
	
	@worlds = get_worlds()
	
	if(!array_contains(@worlds, @world), return(ERROR_WORLD_NOT_EXIST))
	
	@players = array()
	
	foreach(all_players(), @player,
	  
		if(pworld(@player) == @world,
			array_push(@players, @player)
		)
		
	)
	
		return(@players)
	
)


proc(_array_ceilindexes, @array,

	foreach(@array, @index, @value,
	
		if(is_numeric(@value), @array[@index] = ceil(@array[@index]))
		
	)
	
	return(@array)
	
)

proc(_locFloor, @ploc, @add,

	if(@add == '', @add = array(0,1,0))

	@ploc[0] = floor(@ploc[0]) + @add[0]
	@ploc[1] = floor(@ploc[1]) + @add[1]
	@ploc[2] = floor(@ploc[2]) + @add[2]
	
	return(@ploc)
	
)

proc(_array_round, @array,

	foreach(@array, @index, @value,
	
		if(is_numeric(@value), @array[@index] = round(@array[@index]))
		
	)
	
	return(@array)
	
)

proc(_array_combine, @a1, @a2,

	@array = array()
	
	foreach(@a1, @i, @v,
		if(array_index_exists(@a2, @i) && is_numeric(@v) && is_numeric(@a2[@i]),
			@array[@i] = @v + @a2[@i]
		)
	)
	
	return(@array)
	
)

proc(_array_floor, @array,

	foreach(@array, @index, @value,
	
		if(is_numeric(@value), @array[@index] = floor(@array[@index]))
		
	)
	
	return(@array)
	
)

proc(_array_multindexes, @array, @x,

	foreach(@array, @index, @value,
	
		if(is_numeric(@value), @array[@index] = multiply(@array[@index], @x))
		
	)
	
	return(@array)
	
)

proc(_array_neg, @array,

	foreach(@array, @key, @value,
		if(is_numeric(@value), @array[@key] = neg(@value))
	)
	
	return(@array)
	
)

proc(_array_addindexes, @array, @x,

	foreach(@array, @index, @value,
	
		if(is_numeric(@value), @array[@index] = add(@array[@index], @x))
		
	)
	
	return(@array)
	
)

proc(_loc_key, @loc,
	if(is_array(@loc),
		return(@loc[0] . ':' . @loc[1] . ':' . @loc[2] . ':' . @loc[3]),
		return(split(':', @loc))
	)
)

proc(_loc_fix, @loc, @decimals = 1,

	@new = array()
	
	if(array_index_exists(@loc, 0), @new[0] = round(@loc[0], @decimals))
	if(array_index_exists(@loc, 1), @new[1] = round(@loc[1], @decimals))
	if(array_index_exists(@loc, 2), @new[2] = round(@loc[2], @decimals))
	
	if(array_index_exists(@loc, x), @new[0] = round(@loc[x], @decimals))
	if(array_index_exists(@loc, y), @new[1] = round(@loc[y], @decimals))
	if(array_index_exists(@loc, z), @new[2] = round(@loc[z], @decimals))
	
	if(array_index_exists(@loc, 3), @new[3] = @loc[3])
	if(array_index_exists(@loc, world), @new[3] = @loc[world])
	
	return(@new)
	
)

proc(_loc_fix_adv, @loc,

	@new = array()
	
	if(array_index_exists(@loc, 0), @new[0] = round(@loc[0], 2))
	if(array_index_exists(@loc, 1), @new[1] = round(@loc[1], 2))
	if(array_index_exists(@loc, 2), @new[2] = round(@loc[2], 2))
	
	if(array_index_exists(@loc, x), @new[0] = round(@loc[x], 2))
	if(array_index_exists(@loc, y), @new[1] = round(@loc[y], 2))
	if(array_index_exists(@loc, z), @new[2] = round(@loc[z], 2))
	
	if(array_index_exists(@loc, 3), @new[3] = @loc[3])
	if(array_index_exists(@loc, world), @new[3] = @loc[world])

	if(array_index_exists(@loc, 4), @new[4] = round(@loc[4]))
	if(array_index_exists(@loc, yaw), @new[4] = round(@loc[yaw]))
	
	if(array_index_exists(@loc, 5), @new[5] = round(@loc[5]))
	if(array_index_exists(@loc, pitch), @new[5] = round(@loc[pitch]))
		
	return(@new)
	
)

proc(_vec2_add, @vec1, @vec2,

	@vec = array(@vec1[0] + @vec2[0], @vec1[1] + @vec2[1])
	
	foreach(@vec1, @i, @a,
		if(!array_contains(range(0,3), @i),
			@vec[@i] = @a
		)
	)
	
	return(@vec)
	
)

proc(_vec_add, @vec1, @vec2,

	@vec = array(@vec1[0] + @vec2[0], @vec1[1] + @vec2[1], @vec1[2] + @vec2[2])
	
	foreach(@vec1, @i, @a,
		if(!array_contains(range(0,3), @i),
			@vec[@i] = @a
		)
	)
	
	return(@vec)
	
)

proc(_vec_sub, @vec1, @vec2,

	@vec = array(@vec1[0] - @vec2[0], @vec1[1] - @vec2[1], @vec1[2] - @vec2[2])
	
	foreach(@vec1, @i, @a,
		if(!array_contains(range(0,3), @i),
			@vec[@i] = @a
		)
	)
	
	return(@vec)
	
)

proc(_vec_dist, @loc1, @loc2,

	@x = pow((@loc1[0] - @loc2[0]), 2)
	@y = pow((@loc1[1] - @loc2[1]), 2)
	@z = pow((@loc1[2] - @loc2[2]), 2)
	
	@dist = sqrt(@x + @y + @z)
	
	return(@dist)
	
)

proc(_math_average_loc, @locarray,

	@x = 0
	@y = 0
	@z = 0
	
	foreach(@locarray, @loc,
	
		@x = @x + @loc[0]
		@y = @y + @loc[1]
		@z = @z + @loc[2]
		
	)
	
	@x = round(@x / array_size(@locarray))
	@y = round(@y / array_size(@locarray))
	@z = round(@z / array_size(@locarray))
	
	return(array(@x, @y, @z))
	
)

proc(_vec_average, @locarray,

	@vectors = array_size(@locarray)
	
	if(@vectors == 0, return(array(0,0,0)))

	@x = 0
	@y = 0
	@z = 0
	
	foreach(@locarray, @loc,
		@x += @loc[0]
		@y += @loc[1]
		@z += @loc[2]
	)
	
	@x = round(@x / @vectors)
	@y = round(@y / @vectors)
	@z = round(@z / @vectors)
	
	return(array(@x, @y, @z))
	
)

proc(_vec_mult, @vec1, @vec,

	if(!is_array(@vec)) {
		@vec = array(@vec, @vec, @vec)
	}

	@vec1[0] = @vec1[0] * @vec[0]
	@vec1[1] = @vec1[1] * @vec[1]
	@vec1[2] = @vec1[2] * @vec[2]
	
	return(@vec1)
	
)

proc(_vec_normalize, @vec,

	@l = _vec_magnitude(@vec)
	
	if(@l == 0, return(array(0,0,0)))
	
	@vec[0] = (@vec[0] / @l)
	@vec[1] = (@vec[1] / @l)
	@vec[2] = (@vec[2] / @l)
	
	return(@vec)
	
)

proc(_vec_magnitude, @vec,

	@l = sqrt(pow(@vec[0], 2) + pow(@vec[1], 2) + pow(@vec[2], 2))
	
	return(@l)
	
)

proc(_jumpto_loc, @player, @loc,
	
	/*
	@ploc = ploc(@player)
	@diff = _vec_sub(@loc, @ploc)
	
	if(is_integral(@ploc[1]),
		@vec = array(@diff[0] * 0.2, max(0, @diff[1] * 0.1) + 0.55, @diff[2] * 0.2),
		@vec = array(@diff[0] * 0.12, max(0, @diff[1] * 0.1) + 0.5, @diff[2] * 0.12)	
	)
	
	set_pvelocity(@player, @vec)
	*/
	
	set_pvelocity(@player, array(0,1,0))
	
	set_timeout(500,
		closure(
	
			@loc = _loc_fix(@loc)
			@dist = _vec_dist(@loc, ploc(@player))
			export('ploc', _vec_add(_loc_fix(ploc(@player)), array(0,-1,0)))
			
			set_interval(50,
				closure(
					
					@ploc = import('ploc')
					@vec = _vec_mult(_vec_normalize(_vec_sub(@loc, @ploc)), min(5, (_vec_dist(@loc, @ploc) / 10)))
					set_pvelocity(@player, @vec)
					tmsg(@player, _vec_dist(@ploc, _vec_add(_loc_fix(ploc(@player)), array(0,-1,0))))
					@dist = _vec_dist(array(@ploc[0],0,@ploc[2]), array(@loc[0],0,@loc[2]))
					if(@dist < 1 && @ploc[1] >= @loc[1] - 1) {
						set_pvelocity(@player, array(0,0,0))
						clear_task()
					}
					export('ploc', _vec_add(_loc_fix(ploc(@player)), array(0,-1,0)))
					
				)
			)
			
		)
	)
	
)

proc(_within_region, @loc, @p1, @p2,

	@x = min(@p1[0], @p2[0])
	@y = min(@p1[1], @p2[1])
	@z = min(@p1[2], @p2[2])
	
	@mx = max(@p1[0], @p2[0])
	@my = max(@p1[1], @p2[1])
	@mz = max(@p1[2], @p2[2])

	if(
		@x <= @loc[0] && @mx >= @loc[0] &&
		@y <= @loc[1] && @my >= @loc[1] &&
		@z <= @loc[2] && @mz >= @loc[2],

		return(true),
		return(false)
	)
	
)

proc(_vec_iterate, @vec1, @vec2, @r, @m,

	@dist = ceil(_vec_dist(@vec1, @vec2))
	
	@inc = _vec_normalize(_vec_sub(@vec2, @vec1))
	
	@vectors = array()
	
	if(@r == '', @range = @dist + 1, @range = min(@dist + 1, @r))
	
	if(is_numeric(@m), 
		@inc = _vec_mult(@inc, @m)
		@range = ceil(@range / @m)
	)

	foreach(range(0, @range), @p,
	
		@vec = array()
		#@vec[0] = @vec1[0] * (1 - @p) + @vec2[0] * @p
		#@vec[1] = @vec1[1] * (1 - @p) + @vec2[1] * @p
		#@vec[2] = @vec1[2] * (1 - @p) + @vec2[2] * @p
		@vec[0] = @vec1[0] + (@inc[0] * @p)
		@vec[1] = @vec1[1] + (@inc[1] * @p)
		@vec[2] = @vec1[2] + (@inc[2] * @p)
		
		@vectors[] = @vec
	
	)
	
	return(@vectors)
	
)

proc(_vec_iterate_los, @player = player(), @m,

	@loc = _eyes(@player)
	@dist = ceil(_vec_dist(@loc, pcursor(@player)))	
	
	if(is_numeric(@m), 
		@inc = _vec_mult(_forward(@player), @m)
		@range = ceil(@dist * (1 / @m)),
		@inc = _forward(@player)
		@range = @dist + 1
	)

	@vectors = array()

	foreach(range(0, @range), @p, 
	
		@vec = array()
		#@vec[0] = @vec1[0] * (1 - @p) + @vec2[0] * @p
		#@vec[1] = @vec1[1] * (1 - @p) + @vec2[1] * @p
		#@vec[2] = @vec1[2] * (1 - @p) + @vec2[2] * @p
		@vec[0] = @loc[0] + (@inc[0] * @p)
		@vec[1] = @loc[1] + (@inc[1] * @p)
		@vec[2] = @loc[2] + (@inc[2] * @p)
		
		@vectors[] = @vec
	
	)
	
	return(array_unique(@vectors))
	
)

proc(_adv_player_los, @player, @line, @m,

	if(@line == '', @line = _vec_iterate_los(@player, @m))

	@targets = all_entities()
	@players = array()
	
	foreach(@line, @l,
	
		foreach(@targets, @target,
		
			if(entity_type(@target) != PLAYER, continue())
		
			@t = entity_loc(@target)
			
			if(		
				(@l[0] - 0.75 <= @t[0] && @t[0] <= @l[0] + 1.75) && 
				
				(@l[1] - 1.5 <= @t[1] && @t[1] <= @l[1] + 2.5) && 
				
				(@l[2] - 0.75 <= @t[2] && @t[2] <= @l[2] + 1.75)
			)
			{
				if(@target != pinfo(@player)[13],
					@players[] = get_player_from_entity_id(@target)
				)
			}
			
		)
		
	)
	
	return(array_unique(@players))
	
)
			

proc(_math_closest, @x, @numberarray,

	@diff = max(@x, @numberarray[0]) - min(@x, @numberarray[0])
	@closest = @numberarray[0]
	
	foreach(@numberarray, @n,
		
		if((max(@x, @n) - min(@x, @n)) < @diff,
		
			@diff = max(@x, @n) - min(@x, @n)
			@closest = @n
			
		)
		
	)
	
	return(@closest)
	
)

proc(_explode, @origin, @radius, @speed, @exclude, @subdivisions,

	@affected = array()
	
	if(@subdivisions == '', @subdivisions = 100)
	if(@exclude == '', @exclude = array())
	
	if(!is_array(@speed),
		@speed = array(@speed, @speed)
	)	
	
	@players = all_players()
	
	foreach(@exclude, @player,
		array_remove_values(@players, @player)
	)

	foreach(@players, @player,

		@eyes = _eyes(@player)	
		@feet = ploc(@player)
		@world = pworld(@player)

		@dist = min(_vec_dist(@origin, @eyes), _vec_dist(@origin, @feet))
		if(@dist <= @radius)
		{
			@perc = ceil(((@radius - @dist) / @radius) * @subdivisions) / @subdivisions
			@affected[@player] = @perc
			@loc = _eyes(@player)
			
			@vel = 	array(
					@loc[0] - @origin[0],
					@loc[1] - @origin[1],
					@loc[2] - @origin[2]
					)
			@vel = _vec_normalize(@vel)	

			if(@vel[0] == 0 && @vel[1] == 0 && @vel[2] == 0,
			
				continue(),	

				@vel[0] = @vel[0] * @speed[0] * @perc
				@vel[1] = @vel[1] * @speed[1] * @perc
				@vel[2] = @vel[2] * @speed[0] * @perc

				set_pvelocity(@player, @vel)
				
			)
		}
		
	)

	/*
	foreach(all_entities(), @id,
	
		@loc = entity_loc(@id)
		if(entity_type(@id) == 'PLAYER', continue())
		
		@dist = _vec_dist(@origin, @loc)
		
		if(@dist <= @radius,
			@perc = (@radius - @dist) / @radius
			if(@perc > 0 && @perc < 1,		
			
				@vel = 	array(
					@loc[0] - @origin[0],
					@loc[1] - @origin[1],
					@loc[2] - @origin[2]
				)
				@vel = _vec_normalize(@vel)
				
				if(@vel[0] == 0 && @vel[1] == 0 && @vel[2] == 0,
		
				continue(),
		
				@vel[0] = @vel[0] * @speed[0] * 0.1
				@vel[1] = @vel[1] * @speed[1] * 0.1
				@vel[2] = @vel[2] * @speed[0] * 0.1

				set_entity_velocity(@id, @vel)
				
				)
			)
		)
		
	)
	*/
	return(@affected)
	
)

proc(_head, @player,

	if(@player == '', @player = player())
	
	@loc = ploc(@player)
	@loc[1] += 2.8
	
	return(@loc)
	
)

proc(_eyes, @player,

	if(@player == '', @player = player())
	
	@loc = ploc(@player)
	@loc[1] += 2.620
	
	return(@loc)
	
)

proc(_feet, @player,

	if(@player == '', @player = player())
	
	@loc = ploc(@player)
	@loc[1] = @loc[1] + 1
	
	return(@loc)
	
)

proc(_forward, @player, @ox, @oy,

	@facing = pfacing(@player)

	if(!is_numeric(@ox),
		@ox = 0,
		@ox = to_radians(@ox)
	)
	if(!is_numeric(@oy),
		@oy = 0
	)
	
	@y = to_radians(@facing[0])
	@p = to_radians(@facing[1] + @oy)
		
	@vec = array(0 - sin(@y) * cos(@p) + cos(@y) * sin(@ox), 0 - sin(@p), cos(@y) * cos(@p) + sin(@y) * sin(@ox))
	return(@vec)
	
)

proc(_time_empty,

	return(array(yr:0, mt:0, dy:0, hr:0, mn:0, sc:0))
	
)

proc(_time_get,

	@time = parse_args(simple_date('YYYY MM dd HH mm ss'))
	
	@year = @time[0]
	@month = @time[1]
	@day = @time[2]
	@hour = @time[3]
	@minute = @time[4]
	@second = @time[5]
	
	return(array(yr:@year, mt:@month, dy:@day, hr:@hour, mn:@minute, sc:@second))
	
)

proc(_time_add, @time, @offset,

)
		
proc(_time_gte, @time1, @time2,

	if(@time2[yr] < @time1[yr], return(true))
	if(@time2[mt] < @time1[mt], return(true))
	if(@time2[dy] < @time1[dy], return(true))
	if(@time2[hr] < @time1[hr], return(true))
	if(@time2[mn] < @time1[mn], return(true))
	if(@time2[sc] < @time1[sc], return(true))
	
	return(false)

)
/*
proc(_time_diff, @from, @to,

	@time = array()
	
	@time[yr] = @from[yr] - @to[yr]
	@time[mt] = @from[mt] - @to[mt]
	@time[dy] = @from[dy] - @to[dy]
	@time[hr] = @from[hr] - @to[hr]
	@time[mn] = @from[mn] - @to[mn]
	@time[sc] = @from[sc] - @to[sc]

	return(@time)
	
)
*/
proc(_time_lit, @time,

	switch(@time[mt],
	
		01, @time[mt] = 'January',
		02, @time[mt] = 'February',
		03, @time[mt] = 'March',
		04, @time[mt] = 'April',
		05, @time[mt] = 'May',
		06, @time[mt] = 'June',
		07, @time[mt] = 'July',
		08, @time[mt] = 'August',
		09, @time[mt] = 'September',
		10, @time[mt] = 'October',
		11, @time[mt] = 'November',
		12, @time[mt] = 'December',
			@time[mt] = 'ERROR',
			
	)
	
	return(@time)
	
)

proc(_time_string, @time,

	@string = array()

	foreach(array(yr, mt, dy, hr, mn, sc), @i,
	
		switch(@i,
			yr,
				@s = 'year'
				@p = 'years',
			mt,
				@s = 'month'
				@p = 'months',
			dy,
				@s = 'day'
				@p = 'days',
			hr,
				@s = 'hour'
				@p = 'hours',
			mn,
				@s = 'minute'
				@p = 'minutes',
			sc,
				@s = 'second'
				@p = 'seconds'
		)
	
		if(@time[@i] >= 1,
			if(@time[@i] == 1,
				array_push(@string, @time[@i] . ' ' . @s),
				array_push(@string, @time[@i] . ' ' . @p)
			)
		)
	)
	
	@string = array_implode(@string, ', ')
	
	return(@string)
	
)

proc(_gPrefix, @group,

	try(
		return(yml_decode(shell('cat "/home/pubdev/plugins/PermissionsEx/permissions.yml"'))[groups][@group][prefix]),
		@ex, broadcast(@ex)
		return('&f')
	)

)
 
proc(_gSuffix, @group, 

	try(
		return(yml_decode(shell('cat "/home/pubdev/plugins/PermissionsEx/permissions.yml"'))[groups][@group][suffix]),
		return('&f')
	)

)

proc(_gDefault,

	try(
		@groups = yml_decode(shell('cat "/home/pubdev/plugins/PermissionsEx/permissions.yml"'))[groups]
		foreach(@groups, @group,
			if(array_index_exists(@group, default) && @group[default] == true,
				return(array_index(@groups, @group))
			)
		),
		return('default')
	)

)

proc(_pGroup, @player,

	try(
		return(pgroup(@player)[0]),
		return(_gDefault())
	)

)

proc(_adv_regions, @player,

	if(@player == '', @player = player())
	
	@loc = ploc(@player)

	@bottom = sk_regions_at(@loc)
	@top = sk_regions_at(array(@loc[0], @loc[1] + 1, @loc[2], @loc[3]))
	
	return(array_unique(array_merge(@bottom, @top)))
	
)

proc(_stop, cancel() consume() die())

proc(_hurt, @player, @damage, @letlive,

	if(@player == '', @player = player())
	
	@id = pinfo(@player)[13]
	
	@health = get_entity_health(@id)
	
	@left = @health - @damage
	
	if(@left < 0, 
		if(@letlive,
			@left = 1,
			@left = 0
		)
	)
	
	set_entity_health(@id, @left)
	
	return(@left)
	
)

proc(_emptyinv, @player,

	@empty = array(
				null, null, null, null, null, null, null, null, null, null, 
				null, null, null, null, null, null, null, null, null, null,
				null, null, null, null, null, null, null, null, null, null,
				null, null, null, null, null, 100:null, 101:null, 102:null, 103:null
			)

	return(@empty)
	
)

@mod_includes = import('ocp.mod.includes')
if(is_array(@mod_includes), foreach(@mod_includes, @path, include(@path)))

	
proc(_writeUTF, @ba, @str,
        @len = length(@str)
        if (@len > 200) {
            die('String too long')
        }
        ba_put_byte(@ba, 0)
        ba_put_byte(@ba, @len)
        ba_put_bytes(@ba, string_get_bytes(@str, 'ascii'))
)
 
proc(_get_playercount, @server,

	@ba = byte_array()
	
	ba_put_string(@ba, 'PlayerList')
	ba_put_string(@ba, @server)
	
	send_plugin_message(player(), 'BungeeCord', @ba)
	
)

proc(_send_message, @message, @players,

	@sender = player()

	@ba = byte_array()
	
	ba_put_string(@ba, 'PlayerList')
	ba_put_string(@ba, 'ALL')
	
	send_plugin_message(player(), 'BungeeCord', @ba)	
	
	bind(plugin_message_received, array(priority:highest, id:'bungee-bc'), null, @event, @sender, @message, @players,
		
		@ba = @event[bytes]

		ba_rewind(@ba)

		@title = ba_get_string(@ba)

		@server = ba_get_string(@ba)

		if(!is_array(@players), @players = split(', ', ba_get_string(@ba)))
		
		unbind()

		set_timeout(50,
			closure(
				foreach(@players, @player,
				
					@ba = byte_array()
							
					ba_put_string(@ba, 'Message')
					ba_put_string(@ba, @player)
					ba_put_string(@ba, color(0) . '[' . color(c) . 'Broadcast' . color(0) . '] ' . color(f) . @message)
					
					send_plugin_message(@sender, 'BungeeCord', @ba)
					
				)
			)
		)

	)
)

proc(_rand_tp, @player, @min_dist, @max_dist,

	if(!ponline(@player), die())
	
	@world = pworld(@player)

	@loc = ploc(@player)
		@px = floor(@loc[0])
		@pz = floor(@loc[1])
	
	@split = array_rand(array(x, z), 1, false)

	if(@split == x,
		@z = rand(@pz - @max_dist, @pz + @max_dist)
		@x = array_rand(array(rand(@px - @max_dist, @px - @min_dist), rand(@px + @min_dist, @px + @max_dist)), 1, false)[0],
			
		@x = rand(@px - @max_dist, @px + @max_dist)
		@z = array_rand(array(rand(@pz - @max_dist, @pz - @min_dist), rand(@pz + @min_dist, @pz + @max_dist)), 1, false)[0]
	)
	@y = 256
	@count = 0
	
	for(@y, @y > 0, @y--,
	
		@count++
		if(@count > 500, tmsg(TheOctopod, 'LOOP') die())
	
			@type = split(':', get_block_at(@x, @y, @z, @world))[0]
			@1 = split(':', get_block_at(@x, @y + 1, @z, @world))[0]
			@2 = split(':', get_block_at(@x, @y + 2, @z, @world))[0]
		
		if(@type == 8 || @type == 9, 
			if(@split == x,
				@z = rand(@pz - @max_dist, @pz + @max_dist)
				@x = array_rand(array(rand(@px - @max_dist, @px - @min_dist), rand(@px + @min_dist, @px + @max_dist)), 1, false)[0],
					
				@x = rand(@px - @max_dist, @px + @max_dist)
				@z = array_rand(array(rand(@pz - @max_dist, @pz - @min_dist), rand(@pz + @min_dist, @pz + @max_dist)), 1, false)[0]
			)
			@y = 256
			
			@type = split(':', get_block_at(@x, @y, @z, @world))[0]
			@1 = split(':', get_block_at(@x, @y + 1, @z, @world))[0]
			@2 = split(':', get_block_at(@x, @y + 2, @z, @world))[0]
		)
	
		if(@type != 0 && @1 == 0 && @2 == 0,
			break(),
		)
	)

	return(array(@x + 0.5, @y, @z + 0.5, @world))
	
)

proc(_pingto, @ip,

	try(

		msg('Pinging ' . @ip . '...')
		@ping = shell('./ping.sh ' . @ip)
		msg('Ping: ' . @ping),
		
		msg('Error: unable to ping this IP!')
		
	)
	
)

proc(_is_powered, @loc,
	@block = get_block_at(@loc)
	switch(split(':', @block)[0],
		69,
			@states = _lever_getStates(@block)
			if(@states[0] == @block, return(true), return(false)),
			
			return(is_block_powered(@loc))
	)
)

proc(_lever_getStates, @block,

	switch(@block,
	array('69:12', '69:4'), #north wall
		@pair = array('69:12', '69:4'),
	array('69:10', '69:2'), #west wall
		@pair = array('69:10', '69:2'),
	array('69:11', '69:3'), #south wall
		@pair = array('69:11', '69:3'),
	array('69:9', '69:1'), #east wall
		@pair = array('69:9', '69:1'),
	array('69:14', '69:6'), #west-east floor
		@pair = array('69:14', '69:6'),
	array('69:13', '69:5'), #north-south floor
		@pair = array('69:13', '69:5'),
	array('69:8', '69:0'), #west-east ceiling
		@pair = array('69:8', '69:0'),
	array('69:15', '69:7'), #north-south ceiling
		@pair = array('69:15', '69:7'),
		@pair = array('69:12', '69:4')
	)
	
	return(@pair)
	
)

proc(_tps,

	@start = nano_time()

	set_timeout(1000,
		closure(
			@ticks = ((nano_time() - @start) / 1000000000)
			@tps = sprintf('%.2f', min(20, (1 / @ticks * 20)))
			msg('TPS: ' . color(a) . @tps)
		)
	)
		
)