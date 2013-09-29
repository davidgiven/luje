package com.cowlark.luje;

public class Main
{
	public static int i, j;

	public static int increment(int i)
	{
		return i+1;
	}

	public static void main(String[] argv)
	{
		i = increment(i) + j;
	}
}
