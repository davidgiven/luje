package com.cowlark.luje;

public class OTest
{
	static int result;

	public static class TestSuper
	{
		int value()
		{
			return 1;
		}
	}

	public static class TestSub extends TestSuper
	{
		int value()
		{
			return 2;
		}
	}


	public static void main(String[] argv)
	{
		TestSub o = new TestSub();
		result = o.value();
	}
}
