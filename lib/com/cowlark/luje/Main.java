package com.cowlark.luje;

/**
 * Created with IntelliJ IDEA.
 * User: dg
 * Date: 17/08/13
 * Time: 20:15
 * To change this template use File | Settings | File Templates.
 */
public class Main
{
	public static int i = 1;

	public static int inc(int a, long b, int c)
	{
		return a+1;
	}

	public static void main(String[] args)
	{
		long q = inc(i, 1, 2);
		i = (int) q;
	}

	public static void main()
	{
	}
}
