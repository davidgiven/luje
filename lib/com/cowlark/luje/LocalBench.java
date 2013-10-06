package com.cowlark.luje;

public class LocalBench
{
	public static long TIME = 2000;
	public static long STEP = 10000;

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
