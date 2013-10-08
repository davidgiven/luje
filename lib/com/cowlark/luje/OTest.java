package com.cowlark.luje;

import java.util.*;
import java.io.*;

public class OTest
{
	public static long STEP = 20000*5000;

	public static abstract class Benchmark
	{
		public abstract void iterate();
	};

	public static class Benchmark1 extends Benchmark
	{
		public void iterate()
		{
		}
	}

	public static class Benchmark2 extends Benchmark
	{
		public void iterate()
		{
		}
	}

	public static class Benchmark3 extends Benchmark
	{
		public void iterate()
		{
		}
	}

	public static void bench(Benchmark b)
	{
		for (int i=0; i<STEP; i++)
			b.iterate();
	}

	public static void main(String[] argv)
	{
		Benchmark b1 = new Benchmark1();
		Benchmark b2 = new Benchmark2();
		Benchmark b3 = new Benchmark3();
		b1.iterate();
		b2.iterate();
		b3.iterate();

		bench(b1);
		bench(b2);
		bench(b3);
	}
}

