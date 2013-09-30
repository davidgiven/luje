package java.lang;

import java.io.IOException;

public class Object
{
	public native int hashCode();
	
	public native Class<? extends Object> getClass();
	
    public native boolean equals(Object object);
    
	public String toString()
	{
		return "[" + hashCode() + "]";
	}
	
    protected Object clone() throws CloneNotSupportedException
	{
		throw new CloneNotSupportedException();
	}
    
}
