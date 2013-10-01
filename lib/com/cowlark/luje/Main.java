package com.cowlark.luje;

public class Main
{
	public static double intresult;
	public static double longresult;
	public static double doubleresult;

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
		long resultTime = System.currentTimeMillis() - startTime;
		return (i*2.0/resultTime/1000);
	}

	public static void benchmark()
	{
		intresult = intbenchmark(1000000000);
		longresult = longbenchmark(1000000000);
		doubleresult = doublebenchmark(1000000000);
	}

	public static void main(String[] argv)
	{
		benchmark();
		//System.out.println(""+intresult);
	}
}
