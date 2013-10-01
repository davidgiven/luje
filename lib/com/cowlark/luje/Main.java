package com.cowlark.luje;

public class Main
{
	public static double intmark;
	public static double longmark;
	public static double doublemark;

	public static double intresult; // expected: 1
	public static double longresult; // expected: 1
	public static double doubleresult; // expected: 1.999999971621986E8

	public static double intbenchmark(int cnt){
		int intResult = 1;
		int i = 1;
		long startTime = System.currentTimeMillis();
		while (i < cnt){
			intResult -= i++;
			intResult += i++;
			intResult *= i++;
			intResult /= i++;
		}
		intresult = intResult;
		long resultTime = System.currentTimeMillis() - startTime;
		return (i*2.0/resultTime/1000);
	}

   public static double longbenchmark(int cnt){
		long longResult = 1;
		long i = 1;
		long startTime = System.currentTimeMillis();
		while (i < cnt){
			longResult -= i++;
			longResult += i++;
			longResult *= i++;
			longResult /= i++;
		}
		longresult = longResult;
		long resultTime = System.currentTimeMillis() - startTime;
		return (i*2.0/resultTime/1000);
	}

	public static double doublebenchmark(int cnt){            
		double doubleResult = 1;
		double i = 1;
		long startTime = System.currentTimeMillis();
		while (i < cnt){
			doubleResult -= i++;
			doubleResult += i++;
			doubleResult *= i++;
			doubleResult /= i++;
		}
		doubleresult = doubleResult;
		long resultTime = System.currentTimeMillis() - startTime;
		return (i*2.0/resultTime/1000);
	}

	public static void benchmark()
	{
		intmark = intbenchmark(1000000000);
		longmark = longbenchmark(1000000000);
		doublemark = doublebenchmark(1000000000);
	}

	public static void main(String[] argv)
	{
		benchmark();
		//System.out.println(intresult + " " + longresult + " " + doubleresult);
	}
}
