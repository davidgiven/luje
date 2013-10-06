/* The Computer Language Benchmarks Game
   http://shootout.alioth.debian.org/
   contributed by Stefan Krause
   slightly modified by Chad Whipkey
*/

package com.cowlark.luje;

import java.io.IOException;
import java.io.PrintStream;

class Mandelbrot {

   public static void main(String[] args) throws Exception {
       new MandelbrotImpl(4096).compute();
   }

   public static class MandelbrotImpl {
       private static final int BUFFER_SIZE = 8192;

       public MandelbrotImpl(int size) {
         this.size = size;
         fac = 2.0 / size;
         out = System.out;
         shift = size % 8 == 0 ? 0 : (8- size % 8);
      }
      final int size;
      final PrintStream out;
      final byte [] buf = new byte[BUFFER_SIZE];
      int bufLen = 0;
      final double fac;
      final int shift;

      public void compute() throws IOException
      {
         //out.print("P4\n"+size+" "+size+"\n");
		 long startTime = System.currentTimeMillis();
         for (int y = 0; y<size; y++)
            computeRow(y);
		 long endTime = System.currentTimeMillis();
		 System.out.println("total time: "+(endTime-startTime));
         //out.write( buf, 0, bufLen);
         //out.close();
      }

      private void computeRow(int y) throws IOException
      {
         int bits = 0;

         final double Ci = (y*fac - 1.0);
          final byte[] bufLocal = buf;
          for (int x = 0; x<size;x++) {
            double Zr = 0.0;
            double Zi = 0.0;
            double Cr = (x*fac - 1.5);
            int i = 50;
            double ZrN = 0;
            double ZiN = 0;
            do {
               Zi = 2.0 * Zr * Zi + Ci;
               Zr = ZrN - ZiN + Cr;
               ZiN = Zi * Zi;
               ZrN = Zr * Zr;
            } while (!(ZiN + ZrN > 4.0) && --i > 0);

            bits = bits << 1;
            if (i == 0) bits++;

            if (x%8 == 7) {
                bufLocal[bufLen++] = (byte) bits;
                if ( bufLen == BUFFER_SIZE) {
                    //out.write(bufLocal, 0, BUFFER_SIZE);
                    bufLen = 0;
                }
               bits = 0;
            }
         }
         if (shift!=0) {
            bits = bits << shift;
            bufLocal[bufLen++] = (byte) bits;
            if ( bufLen == BUFFER_SIZE) {
                //out.write(bufLocal, 0, BUFFER_SIZE);
                bufLen = 0;
            }
         }
      }
   }
}
