/* Luje
 * © 2013 David Given
 * This file is redistributable under the terms of the
 * New BSD License. Please see the COPYING file in the
 * project root for the full text.
 */

package com.cowlark.luje;

public class LocalBench
{
	public static int TIME = 2000;
	public static int STEP = 10000;

	public static void intBenchmark()
	{
		long startTime = System.currentTimeMillis();
		long elapsed;
		int iterations = 0;

		int result = 1;
		int count = 1;

		for (;;)
		{
			elapsed = System.currentTimeMillis() - startTime;
			if (elapsed > TIME)
				break;

			for (int i=0; i<STEP; i++)
			{
				result -= count++;
				result += count++;
				result *= count++;
				result /= count++;
			}

			iterations += STEP;
		}

		double speed = (double)iterations / (double)elapsed;
		System.out.println("integer: "+speed+" ("+iterations+" iterations)");
	}

	public static void longBenchmark()
	{
		long startTime = System.currentTimeMillis();
		long elapsed;
		int iterations = 0;

		long result = 1;
		long count = 1;

		for (;;)
		{
			elapsed = System.currentTimeMillis() - startTime;
			if (elapsed > TIME)
				break;

			for (int i=0; i<STEP; i++)
			{
				result -= count++;
				result += count++;
				result *= count++;
				result /= count++;
			}

			iterations += STEP;
		}

		double speed = (double)iterations / (double)elapsed;
		System.out.println("long: "+speed+" ("+iterations+" iterations)");
	}

	public static void floatBenchmark()
	{
		long startTime = System.currentTimeMillis();
		long elapsed;
		int iterations = 0;

		float result = 1;
		float count = 1;

		for (;;)
		{
			elapsed = System.currentTimeMillis() - startTime;
			if (elapsed > TIME)
				break;

			for (int i=0; i<STEP; i++)
			{
				result -= count++;
				result += count++;
				result *= count++;
				result /= count++;
			}

			iterations += STEP;
		}

		double speed = (double)iterations / (double)elapsed;
		System.out.println("float: "+speed+" ("+iterations+" iterations)");
	}

	public static void doubleBenchmark()
	{
		long startTime = System.currentTimeMillis();
		long elapsed;
		int iterations = 0;

		double result = 1;
		double count = 1;

		for (;;)
		{
			elapsed = System.currentTimeMillis() - startTime;
			if (elapsed > TIME)
				break;

			for (int i=0; i<STEP; i++)
			{
				result -= count++;
				result += count++;
				result *= count++;
				result /= count++;
			}

			iterations += STEP;
		}

		double speed = (double)iterations / (double)elapsed;
		System.out.println("double: "+speed+" ("+iterations+" iterations)");
	}

	public static void main(String[] argv)
	{
		intBenchmark();
		longBenchmark();
		floatBenchmark();
		doubleBenchmark();
	}
}
