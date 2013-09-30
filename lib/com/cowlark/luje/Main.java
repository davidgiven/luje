package com.cowlark.luje;

public class Main
{
	public static double x;

	public static double quadratic(double a, double b, double c)
	{
		return (b*b) - (4*a*c);
	}

	public static void main(String[] argv)
	{
		x = quadratic(1, 2, 3);
	}
}
