/* cowjac © 2012 David Given
 * This file is licensed under the Simplified BSD license. Please see
 * COPYING.cowjac for the full text.
 */

package com.cowlark.luje.harmony;

import java.util.Locale;

public class UCharacter
{
	public static String toLowerCase(Locale locale, String s)
	{
		char[] chars = s.toCharArray();
		for (int i = 0; i < chars.length; i++)
			chars[i] = Character.toLowerCase(chars[i]);
		return new String(chars);
	}
}
