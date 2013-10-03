package com.cowlark.luje;

import java.util.*;

public class OTest
{
	static int result;

	public static void main(String[] argv)
	{
		int[] array = new int[10000];
		for (int i=0; i<array.length; i++)
			array[i] = array[i]*array[i];
	}
}
