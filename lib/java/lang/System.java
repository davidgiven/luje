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
            arraycopy((Object[]) src, srcPos, (Object[]) dest, destPos, length);
        } else {
            if (componentType2 != componentType1) {
                throw new ArrayStoreException();
            }
            if (componentType1 == Integer.TYPE) {
                arraycopy((int[]) src, srcPos, (int[]) dest, destPos, length);
            } else if (componentType1 == Byte.TYPE) {
                arraycopy((byte[]) src, srcPos, (byte[]) dest, destPos, length);
            } else if (componentType1 == Long.TYPE) {
                arraycopy((long[]) src, srcPos, (long[]) dest, destPos, length);
            } else if (componentType1 == Short.TYPE) {
                arraycopy((short[]) src, srcPos, (short[]) dest, destPos, length);
            } else if (componentType1 == Character.TYPE) {
                arraycopy((char[]) src, srcPos, (char[]) dest, destPos, length);
            } else if (componentType1 == Boolean.TYPE) {
                arraycopy((boolean[]) src, srcPos, (boolean[]) dest, destPos, length);
            } else if (componentType1 == Double.TYPE) {
                arraycopy((double[]) src, srcPos, (double[]) dest, destPos, length);
            } else if (componentType1 == Float.TYPE) {
                arraycopy((float[]) src, srcPos, (float[]) dest, destPos, length);
            }
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(int[] A1, int offset1, int[] A2, int offset2, int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(byte[] A1, int offset1, byte[] A2, int offset2, int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(short[] A1, int offset1, short[] A2, int offset2, int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(long[] A1, int offset1, long[] A2, int offset2, int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(char[] A1, int offset1, char[] A2, int offset2, int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(boolean[] A1, int offset1, boolean[] A2, int offset2,
            int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(double[] A1, int offset1, double[] A2, int offset2, int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

    /**
     * Copies the contents of <code>A1</code> starting at offset
     * <code>offset1</code> into <code>A2</code> starting at offset
     * <code>offset2</code> for <code>length</code> elements.
     * 
     * @param A1 the array to copy out of
     * @param offset1 the starting index in array1
     * @param A2 the array to copy into
     * @param offset2 the starting index in array2
     * @param length the number of elements in the array to copy
     */
    private static void arraycopy(float[] A1, int offset1, float[] A2, int offset2, int length) {
        if (offset1 >= 0 && offset2 >= 0 && length >= 0 && length <= A1.length - offset1
                && length <= A2.length - offset2) {
            // Check if this is a forward or backwards arraycopy
            if (A1 != A2 || offset1 > offset2 || offset1 + length <= offset2) {
                for (int i = 0; i < length; ++i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            } else {
                for (int i = length - 1; i >= 0; --i) {
                    A2[offset2 + i] = A1[offset1 + i];
                }
            }
        } else {
            throw new ArrayIndexOutOfBoundsException();
        }
    }

	public static native long currentTimeMillis();
	
}
