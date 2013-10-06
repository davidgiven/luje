package com.cowlark.luje;

import java.util.*;
import java.io.*;

public class OTest
{
	static Object result;

	public static void main(String[] argv)
	{
		try
		{
			throw new IOException();
		}
		catch (IOException e)
		{
			System.out.println("caught!");
		}
	}
}
