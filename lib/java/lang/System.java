package java.lang;

import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.PrintStream;

public class System
{
	public static PrintStream out = new PrintStream(new FileOutputStream(FileDescriptor.out));
	public static PrintStream err = new PrintStream(new FileOutputStream(FileDescriptor.err));
	
	public static String getProperty(String key)
	{
		return "";
	}
	
	public static String getProperty(String key, String defaultValue)
	{
		return defaultValue;
	}

	/**
     * Copies the number of {@code length} elements of the Array {@code src}
     * starting at the offset {@code srcPos} into the Array {@code dest} at
     * the position {@code destPos}.
     *
     * @param src
     *            the source array to copy the content.
     * @param srcPos
     *            the starting index of the content in {@code src}.
     * @param dest
     *            the destination array to copy the data into.
     * @param destPos
     *            the starting index for the copied content in {@code dest}.
     * @param length
     *            the number of elements of the {@code array1} content they have
     *            to be copied.
     */
    public static void arraycopy(Object src, int srcPos, Object dest, int destPos,
            int length) {
        // sending getClass() to both arguments will check for null
        Class<?> type1 = src.getClass();
        Class<?> type2 = dest.getClass();
        if (!type1.isArray() || !type2.isArray()) {
            throw new ArrayStoreException();
        }
        Class<?> componentType1 = type1.getComponentType();
        Class<?> componentType2 = type2.getComponentType();
        if (!componentType1.isPrimitive()) {
            if (componentType2.isPrimitive()) {
                throw new ArrayStoreException();
            }
        } else {
            if (componentType2 != componentType1) {
                throw new ArrayStoreException();
            }
		}
		arraycopyImpl(src, srcPos, dest, destPos, length);
    }

    public static native void arraycopyImpl(Object src, int srcPos, Object dest, int destPos,
            int length);

	public static native long currentTimeMillis();
	
	public static native void gc();

	public static native void log(String s);
}
