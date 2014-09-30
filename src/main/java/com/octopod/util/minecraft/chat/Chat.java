package com.octopod.util.minecraft.chat;

import org.json.simple.JSONValue;

import java.util.*;

/**
 * Last Updated: 2.15.2014
 * Chat that provide tools relating to MC's chat and Chat Libraries.
 * @author Octopod
 */
public class Chat
{
	/**
	 * Map of all specific character widths other than 6, which most of the characters have.
	 */
    final private static Map<Character, Integer> widths = new HashMap<>();

    static
	{
        widths.put('*', 5);
        widths.put('>', 5);
        widths.put('<', 5);
        widths.put(',', 2);
        widths.put('!', 2);
        widths.put('{', 5);
        widths.put('}', 5);
        widths.put(')', 5);
        widths.put('(', 5);
        widths.put('\u00a7', 0); //section sign; Minecraft's color code symbol.
        widths.put('[', 4);
        widths.put(']', 4);
        widths.put(':', 2);
        widths.put('\'', 3);
        widths.put('|', 2);
        widths.put('.', 2);
        widths.put('\u2019', 2); //filler character; Reverse quotation mark.
        widths.put('`', 3); //old filler character; Width change since 1.7
        widths.put(' ', 4);
        widths.put('f', 5);
        widths.put('k', 5);
        widths.put('I', 4);
        widths.put('t', 4);
        widths.put('l', 3);
        widths.put('i', 2);
    }

	/**
	 * Returns the width of the inserted character, according to Minecraft's default chat font (in pixels)
	 * Most characters are 6 pixels wide.
	 *
	 * @param character The text to use for calculation.
	 * @return The width of the text inserted. (in pixels)
	 */
	static public int width(char character)
	{
		if(widths.containsKey(character))
			return widths.get(character);
		return 6;
	}

	/**
	 * Returns the width of the text inserted into the function.
	 * Note that bolded characters are 1 pixel wider than normal.
	 * @param text The text to use for calculation.
	 * @return The width of the text inserted. (in pixels)
	 */
	static public int width(String text)
	{
		int width = 0;
		boolean noWidth;
		boolean bolded = false;
		char lastChar = ' ';

		for(char character:text.toCharArray())
		{
			noWidth = false;
			if(lastChar == '\u00a7')
			{
				bolded = Character.toString(character).toLowerCase().equals("l");
				noWidth = true;
			}
			lastChar = character;
			if(!noWidth)
			{
				width += width(character);
				if(bolded) width += 1;
			}
		}

		return width;
	}

    public static String toJson(List<ChatElement> elements)
	{
        Map<Object, Object> json = new HashMap<>();
        json.put("text", "");
        json.put("extra", elements);
        return JSONValue.toJSONString(json);
    }

	public static void send(ChatReciever target, ChatBuilder... builders)
	{
		for(ChatBuilder builder: builders)
		{
			target.sendJsonMessage(builder.toJSONString());
		}
	}

	public static void send(ChatReciever target, String json)
	{
		target.sendJsonMessage(json);
    }

	public static ChatBuilder[] makeBuilders(int lines)
	{
		ChatBuilder[] builders = new ChatBuilder[lines];
		for(int i = 0; i < lines; i++)
		{
			builders[i] = new ChatBuilder();
		}
		return builders;
	}

	public static String colorize(String message)
	{
		return colorize(message, '&');
	}

	public static String colorize(String message, char replace)
	{
		return message.replace(replace, '\u00A7');
	}

	/**
	 * Converts a ChatBuilder object to Minecraft legacy chat string.
	 * Obviously, hover and click events won't carry over.
	 * @param builder The ChatBuilder object to convert
	 * @return The legacy chat string.
	 */

	public static String toLegacyString(ChatBuilder builder)
	{
		return toLegacyString(builder.toElementList());
	}

    public static String toLegacyString(ChatElement... elements)
	{
		StringBuilder sb = new StringBuilder();

		for(ChatElement e: elements) {
			sb.append(e.getColor());
			for(ChatFormat format: e.getFormats()) {
				sb.append(format);
			}
			sb.append(e.getText());
		}

		return sb.toString();
    }

	public static String toLegacyString(List<ChatElement> elements)
	{
		StringBuilder sb = new StringBuilder();

		for(ChatElement e: elements) {
			sb.append(e.getColor());
			for(ChatFormat format: e.getFormats()) {
				sb.append(format);
			}
			sb.append(e.getText());
		}

		return sb.toString();
	}

	public static ChatBuilder fromLegacy(String message) {return fromLegacy(message, '\u00A7');}

	/**
	 * Converts Minecraft legacy chat to a ChatBuilder object.
	 * @param message The legacy chat string to convert
	 * @return A new ChatBuilder object.
	 */

	public static ChatBuilder fromLegacy(String message, char colorCode) {

		ChatBuilder cb = new ChatBuilder();

		StringBuilder text = new StringBuilder();
		boolean nextIsColorCode = false;
		ChatColor lastColor = ChatColor.WHITE;
		List<ChatFormat> formats = new ArrayList<>();

		for(char c: message.toCharArray()) {

			if(c == colorCode) {
				nextIsColorCode = true;
				continue;
			}

			if(nextIsColorCode) {
				nextIsColorCode = false;
				ChatColor color = ChatColor.fromChar(c);
				ChatFormat format = ChatFormat.fromChar(c);
				if(color != null && format == null) { //This is a color
					//Push new element
					if(!text.toString().equals("")) {
						cb.append(text.toString()).color(lastColor).format(formats.toArray(new ChatFormat[formats.size()]));
					}
					//Reset variables
					text = new StringBuilder();
					lastColor = color;
					formats = new ArrayList<>();
				} else if (color == null && format != null) { //This is a format
					formats.add(format);
				}
				continue;
			}

			text.append(c);

		}

		cb.append(text.toString()).color(lastColor).format(formats.toArray(new ChatFormat[formats.size()]));

		return cb;
	}

	public static ChatBuilder join(ChatBuilder builder, ChatElement glue) {return join(builder, glue, glue);}
	public static ChatBuilder join(ChatBuilder builder, ChatElement glue, ChatElement lastGlue)
	{
		ChatBuilder newBuilder = new ChatBuilder();
		List<ChatElement> elements = builder.toElementList();
		if(elements.size() > 0) {
			newBuilder.append(elements.get(0));
			for(int i = 1; i < elements.size(); i++) {
				if(i == (elements.size() - 1)) {
					newBuilder.append(lastGlue);
				} else {
					newBuilder.append(glue);
				}
				newBuilder.append(elements.get(i));
			}
		}

		return newBuilder;
	}

	/*
	@SuppressWarnings("deprecation")
	public static String itemtoJSON(ItemStack item) {

		Map<String, Object> toJSONString = new HashMap<String, Object>();
		Map<String, Object> meta = new HashMap<String, Object>();
		Map<String, Object> display = new HashMap<String, Object>();

		toJSONString.put("id", item.getTypeId());
		toJSONString.put("Damage", (int)item.getData().getData());
		toJSONString.put("Count", item.getAmount());

		try{
			display.put("Name", item.getItemMeta().getDisplayName());
			meta.put("display", display);
		} catch (NullPointerException e) {}

		toJSONString.put("tag", meta);

		return JSONValue.toJSONString(toJSONString);

	}
	*/

	private static interface BlockRenderer <T>
	{
		public T render(String left, String text, String right);
	}

	private static BlockRenderer<String> BLOCK_RENDERER_STRING = new BlockRenderer<String>()
	{
		@Override
		public String render(String left, String text, String right)
		{
			return left + text + right;
		}
	};

	private static BlockRenderer<ChatBuilder> BLOCK_RENDERER_CHAT = new BlockRenderer<ChatBuilder>()
	{
		@Override
		public ChatBuilder render(String left, String text, String right)
		{
			return new ChatBuilder().append
			(
				new ChatElement(left),
				new ChatElement(text),
				new ChatElement(right)
			);
		}
	};

	private static interface FillerRenderer <T>
	{
		public T render(String filler);
	}

	private static FillerRenderer<String> FILLER_RENDERER_STRING = new FillerRenderer<String>()
	{
		@Override
		public String render(String filler)
		{
			return filler;
		}
	};

	private static FillerRenderer<ChatElement> FILLER_RENDERER_CHAT = new FillerRenderer<ChatElement>()
	{
		@Override
		public ChatElement render(String filler)
		{
			return new ChatElement(filler);
		}
	};

	/**
	 * Creates a block of text with a variable width. Useful for aligning text into columns on multiple lines.
	 * @param text The string to insert
	 * @param toWidth The width to fit the text to in pixels. (Will cut the text if toWidth is shorter than it)
	 * @param alignment Which way to align the text. (0: left, 1: right, 2: center)
	 * @param fillerChar The primary character to use for filling. Usually a space.
	 * @param precise Whether or not to use filler characters to perfectly match the width (this will create artifacts in the filler)
	 * @param renderer The interface that this method will use to build the return object.
	 * @return The text fitted to toWidth.
	 */
    static private <T> T block(String text, int toWidth, ChatAlignment alignment, char fillerChar, boolean precise, BlockRenderer<T> renderer)
	{
        String cutText = cut(text, toWidth) + ChatFormat.RESET;

        //The total width (in pixels) needed to fill
        final int totalFillerWidth = toWidth - width(cutText);

        int lFillerWidth, rFillerWidth;

        switch(alignment) {
        	case LEFT:
        	default:
				lFillerWidth = 0;
        		rFillerWidth = totalFillerWidth;
        		break;
        	case RIGHT:
        		lFillerWidth = totalFillerWidth;
				rFillerWidth = 0;
        		break;
        	case CENTER: //Cuts the total width to fill in half
        		lFillerWidth = (int)Math.floor(totalFillerWidth / 2.0);
        		rFillerWidth = (int)Math.ceil(totalFillerWidth / 2.0);
				break;
			case CENTER_CEILING:
				lFillerWidth = (int)Math.ceil(totalFillerWidth / 2.0);
				rFillerWidth = (int)Math.floor(totalFillerWidth / 2.0);
                break;
        }

       return renderer.render(filler(lFillerWidth, precise, fillerChar, FILLER_RENDERER_STRING), cutText, filler(rFillerWidth, precise, fillerChar, FILLER_RENDERER_STRING));
    }

    static public String blockString(String text, int toWidth, ChatAlignment alignment)
	{
    	return blockString(text, toWidth, alignment, ' ', true);
    }

    static public String blockString(String text, int toWidth, ChatAlignment alignment, char fillerChar, boolean precise)
	{
        return block(text, toWidth, alignment, fillerChar, precise, BLOCK_RENDERER_STRING);
    }

	static public ChatBuilder block(String text, int toWidth, ChatAlignment alignment)
	{
		return block(text, toWidth, alignment, ' ', true);
	}

	static public ChatBuilder block(String text, int toWidth, ChatAlignment alignment, char fillerChar, boolean precise)
	{
		return block(text, toWidth, alignment, fillerChar, precise, BLOCK_RENDERER_CHAT);
	}

    static public ChatBuilder block(ChatElement element, int toWidth, ChatAlignment alignment)
	{
    	return block(element, toWidth, alignment, ' ', true);
    }

    static public ChatBuilder block(ChatElement element, int toWidth, ChatAlignment alignment, char fillerChar, boolean precise)
	{
        return block(toLegacyString(element), toWidth, alignment, fillerChar, precise, BLOCK_RENDERER_CHAT);
    }

    final static ChatColor FILLER_COLOR = ChatColor.DARK_GRAY;

    public final static String FILLER_2PX_RAW = FILLER_COLOR + "\u2019";
	public final static ChatElement FILLER_2PX = new ChatElement(FILLER_2PX_RAW);

	/**
	 * Creates a filler for use in Minecraft's chat. It's a more raw function used to align text.
	 * @param width The width of the filler (in pixels)
	 * @param precise Whether or not to use filler characters to perfectly match the width (this will create artifacts in the filler)
	 * @param customFiller The character to use primarily during the filler (should be a space most of the time)
	 * @return The filler as a string.
	 */
    static public <T> T filler(int width, boolean precise, char customFiller, FillerRenderer<T> renderer)
	{
		if(width < 0) throw new IllegalArgumentException("Filler width cannot be less than 0!");
		if(width == 0) return renderer.render("");
		if(width == 1) throw new IllegalArgumentException("A filler cannot be a pixel wide");
		if(width == 2) return renderer.render(FILLER_2PX_RAW);

    	final int customFillerWidth = width(customFiller);
        StringBuilder filler = new StringBuilder();

        while(width > customFillerWidth + 1){
            filler.append(customFiller);
            width -= customFillerWidth;
        }

        switch(width){
            case 6:
                if(customFillerWidth == 6) {filler.append(customFiller); break;}
            case 5:
                if(customFillerWidth == 5) {filler.append(customFiller); break;}
				// Use a bolded space (4px + 1px)
                filler.append(ChatFormat.BOLD).append(' ').append(ChatFormat.RESET);
                break;
            case 4:
                if(customFillerWidth == 4) {filler.append(customFiller); break;}
				// Use a space (4px)
                filler.append(" ");
                break;
            case 3:
                if(customFillerWidth == 3) {filler.append(customFiller); break;}
                if(!precise) break;
				// Use the bolded 2px filler (2px + 1px)
                filler.append(FILLER_COLOR).append(ChatFormat.BOLD).append(FILLER_2PX_RAW).append(ChatFormat.RESET);
                break;
            case 2:
                if(customFillerWidth == 2) {filler.append(customFiller); break;}
                if(!precise) break;
				// Use the 2px filler
                filler.append(FILLER_COLOR).append(FILLER_2PX_RAW).append(ChatFormat.RESET);
                break;
        }

        return renderer.render(filler.toString());
    }

    static public ChatElement filler(int width)
	{
    	return filler(width, true, ' ');
    }

    static public ChatElement filler(int width, boolean precise, char emptyFiller)
	{
    	return filler(width, precise, emptyFiller, FILLER_RENDERER_CHAT);
    }

    static public String cut(String text, int width)
	{
    	return cut(text, width, false, 0);
    }

	/**
	 * Returns the truncated version of text to be of toWidth or less.
	 * The text will be returned unmodified if toWidth is wider than the width of the text.
	 * TODO: Make this function return a list of strings instead of just the first one
	 * @param text The text to use for calculation.
	 * @return The width of the text inserted. (in pixels)
	 */
	static public String cut(String text, int width, boolean wrap, int wrap_threshold)
	{
    	int start = 0;
    	int end = text.length();

    	while(width(text.substring(start, end)) > width)
		{
    		end--;
			if(width(text.substring(start, end)) <= width && wrap)
			{
				int lookbehind = 0; //Amount of characters looked at behind the end index
				int temp_end = end; //Temporary end marker
				while(text.charAt(temp_end - 1) != ' ')
				{
					temp_end--;

					if(lookbehind > wrap_threshold) break;
					if(temp_end <= 0) break;

					lookbehind++;

					if(text.charAt(temp_end - 1) == ' ')
					{
						end = temp_end;
						break;
					}
				}
			}
    	}

    	return text.substring(start, end);
    }

	public static String toJSONString(ChatBuilder builder)
	{
		List<ChatElement> elements = builder.toElementList();

		Map<String, Object> json = new HashMap<>();
		json.put("text", "");
		json.put("extra", elements);

		return JSONValue.toJSONString(json);
	}

	@SuppressWarnings({ "unchecked", "rawtypes" })
	public static String toJSONString(ChatElement element)
	{
		if
		(
			element.getColor() == ChatColor.WHITE &&
			element.getFormats().length == 0 &&
			element.getClick() == null &&
			element.getHover() == null
		)
		{
			return JSONValue.toJSONString(element.getText());
		}

		String text = element.getText();
		boolean translate = element.getTranslate();
		List<String> with = element.getTranslateWith();

		Map<String, Object> json = new HashMap();

		if(translate) {
			json.put("translate", text);
			if(with.size() > 0)
				json.put("with", with);
		} else {
			json.put("text", text);
		}

		if(element.getClick() != null)
		{
			Map click = new HashMap();
			click.put("action", element.getClick().name().toLowerCase());
			click.put("value", element.getClickValue());
			json.put("clickEvent", click);
		}

		if(element.getClick() != null)
		{
			Map hover = new HashMap();
			hover.put("action", element.getHover().name().toLowerCase());
			hover.put("value", element.getHoverValue());
			json.put("hoverEvent", hover);
		}

		for(ChatFormat format: element.getFormats())
		{
			json.put(format.name().toLowerCase(), true);
		}

		if(element.getColor() != ChatColor.WHITE)
		{
			json.put("color", element.getColor().name().toLowerCase());
		}

		return JSONValue.toJSONString(json);
	}
}
