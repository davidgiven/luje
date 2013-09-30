package java.lang;

public abstract class Class<T extends Object>
{
	public native boolean isInstance(Object o);
	public native boolean isPrimitive();
	public native boolean isArray();
	public native Class<?> getSuperclass();
	public native Class<?> getComponentType();
	public native Class<?> getArrayType();
	private Class<?> _arrayType;
	public native String getName();
	
	public final boolean desiredAssertionStatus()
	{
		return true;
	}
}
