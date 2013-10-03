package com.cowlark.luje;

import java.util.*;

public class OTest
{
	static int result;

	public static int many(int a, int b, int c, int d)
	{
		return a+b+c+d;
	}

	public static void main(String[] argv)
	{
		//result = many(1, 2, 3, 4);
		HashMap<Integer, Integer> map = new HashMap<Integer, Integer>();
		for (int i=0; i<1000; i++)
			map.put(i, i);

		result = map.get(55);
	}
}
