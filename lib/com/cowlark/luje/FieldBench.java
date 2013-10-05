package com.cowlark.luje;

public class FieldBench
{
	public static long TIME = 2000;
	public static long STEP = 1000;

	public static abstract class Benchmark
	{
		public abstract void iterate();
	};

	public static class IntBenchmark extends Benchmark
	{
		private int result = 1;
		private int count = 1;

		public void iterate()
		{
			result -= count++;
			result += count++;
			result *= count++;
			result /= count++;
		}
	}

	public static class LongBenchmark extends Benchmark
	{
		private long result = 1;
		private long count = 1;

		public void iterate()
		{
			result -= count++;
			result += count++;
			result *= count++;
			result /= count++;
		}
	}

	public static class FloatBenchmark extends Benchmark
	{
		private float result = 1;
		private float count = 1;

		public void iterate()
		{
			result -= count++;
			result += count++;
			result *= count++;
			result /= count++;
		}
	}

	public static class DoubleBenchmark extends Benchmark
	{
		private double result = 1;
		private double count = 1;

		public void iterate()
		{
			result -= count++;
			result += count++;
			result *= count++;
			result /= count++;
		}
	}

	public static void bench(Benchmark b, String name)
	{
		long startTime = System.currentTimeMillis();
		long elapsed;
		int iterations = 0;
		for (;;)
		{
			elapsed = System.currentTimeMillis() - startTime;
			if (elapsed > TIME)
				break;

			for (int i=0; i<STEP; i++)
				b.iterate();
			iterations += STEP;
		}

		double speed = (double)iterations / (double)elapsed;
		System.out.println(name+": "+speed+" ("+iterations+" iterations)");
	}

	public static void main(String[] argv)
	{
		bench(new IntBenchmark(), "integer");
		bench(new LongBenchmark(), "long");
		bench(new FloatBenchmark(), "float");
		bench(new DoubleBenchmark(), "double");
	}
}
