package com.cowlark.luje;

public class Main
{
	public static double x;

	public static double quadratic(double a, double b, double c)
	{
		return Math.sqrt((b*b) - (4*a*c));
	}

	public static void main(String[] argv)
	{
		for (double d = 0; d<100; d+=.5)
			x += quadratic(d, 1, 2);
	}
}
