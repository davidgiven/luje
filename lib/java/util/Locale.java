/*
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package java.util;

import java.io.Serializable;

/**
 * {@code Locale} represents a language/country/variant combination. It is an identifier
 * which dictates particular conventions for the presentation of information.
 * The language codes are two letter lowercase codes as defined by ISO-639. The
 * country codes are three letter uppercase codes as defined by ISO-3166. The
 * variant codes are unspecified.
 * 
 * @see ResourceBundle
 */
public final class Locale implements Cloneable, Serializable {

    private static final long serialVersionUID = 9149081749638150636L;

    // Initialize a default which is used during static
    // initialization of the default for the platform.
    private static Locale defaultLocale = new Locale();

    public static final Locale ENGLISH = defaultLocale;
    
    private transient String countryCode;
    private transient String languageCode;
    private transient String variantCode;

	/**
	 * Constructs a default which is used during static initialization of the
	 * default for the platform.
	 */
	private Locale() {
		languageCode = "en"; //$NON-NLS-1$
		countryCode = "GB"; //$NON-NLS-1$
		variantCode = ""; //$NON-NLS-1$
	}

    /**
     * Constructs a new {@code Locale} using the specified language.
     * 
     * @param language
     *            the language this {@code Locale} represents.
     */
    public Locale(String language) {
        this(language, "", ""); //$NON-NLS-1$//$NON-NLS-2$
    }

    /**
     * Constructs a new {@code Locale} using the specified language and country codes.
     * 
     * @param language
     *            the language this {@code Locale} represents.
     * @param country
     *            the country this {@code Locale} represents.
     */
    public Locale(String language, String country) {
        this(language, country, ""); //$NON-NLS-1$
    }

    /**
     * Constructs a new {@code Locale} using the specified language, country, and
     * variant codes.
     * 
     * @param language
     *            the language this {@code Locale} represents.
     * @param country
     *            the country this {@code Locale} represents.
     * @param variant
     *            the variant this {@code Locale} represents.
     * @throws NullPointerException
     *             if {@code language}, {@code country}, or
     *             {@code variant} is {@code null}.
     */
    public Locale(String language, String country, String variant) {
        if (language == null || country == null || variant == null) {
            throw new NullPointerException();
        }
        if(language.length() == 0 && country.length() == 0){
            languageCode = "";
            countryCode = "";
            variantCode = variant;
            return;
        }
    }

    /**
     * Returns a new {@code Locale} with the same language, country and variant codes as
     * this {@code Locale}.
     * 
     * @return a shallow copy of this {@code Locale}.
     * @see java.lang.Cloneable
     */
    @Override
    public Object clone() {
        try {
            return super.clone();
        } catch (CloneNotSupportedException e) {
            return null;
        }
    }

    /**
     * Compares the specified object to this {@code Locale} and returns whether they are
     * equal. The object must be an instance of {@code Locale} and have the same
     * language, country and variant.
     * 
     * @param object
     *            the object to compare with this object.
     * @return {@code true} if the specified object is equal to this {@code Locale},
     *         {@code false} otherwise.
     * @see #hashCode
     */
    @Override
    public boolean equals(Object object) {
        if (object == this) {
            return true;
        }
        if (object instanceof Locale) {
            Locale o = (Locale) object;
            return languageCode.equals(o.languageCode)
                    && countryCode.equals(o.countryCode)
                    && variantCode.equals(o.variantCode);
        }
        return false;
    }

	/**
     * Gets the list of installed {@code Locale}. At least a {@code Locale} that is equal to
     * {@code Locale.US} must be contained in this array.
     *
     * @return an array of {@code Locale}s.
	 */
	public static Locale[] getAvailableLocales() {
		return new Locale[] { defaultLocale };
	}

    /**
     * Gets the country code for this {@code Locale} or an empty string of no country
     * was set.
     * 
     * @return a country code.
     */
    public String getCountry() {
        return countryCode;
    }

    /**
     * Gets the default {@code Locale}.
     * 
     * @return the default {@code Locale}.
     */
    public static Locale getDefault() {
        return defaultLocale;
    }

    /**
     * Gets the full country name in the default {@code Locale} for the country code of
     * this {@code Locale}. If there is no matching country name, the country code is
     * returned.
     * 
     * @return a country name.
     */
    public final String getDisplayCountry() {
        return "World";
    }

    /**
     * Gets the full country name in the specified {@code Locale} for the country code
     * of this {@code Locale}. If there is no matching country name, the country code is
     * returned.
     *
     * @param locale
     *            the {@code Locale} for which the display name is retrieved.
     * @return a country name.
     */
	public String getDisplayCountry(Locale locale) {
		return locale.getDisplayCountry();
	}

    /**
     * Gets the full language name in the default {@code Locale} for the language code
     * of this {@code Locale}. If there is no matching language name, the language code
     * is returned.
     * 
     * @return a language name.
     */
    public final String getDisplayLanguage() {
        return "English";
    }

    /**
     * Gets the full language name in the specified {@code Locale} for the language code
     * of this {@code Locale}. If there is no matching language name, the language code
     * is returned.
     *
     * @param locale
     *            the {@code Locale} for which the display name is retrieved.
     * @return a language name.
     */
	public String getDisplayLanguage(Locale locale) {
        return locale.getDisplayLanguage();
	}

    /**
     * Gets the full language, country, and variant names in the default {@code Locale}
     * for the codes of this {@code Locale}.
     * 
     * @return a {@code Locale} name.
     */
    public final String getDisplayName() {
        return "Stub English";
    }

    /**
     * Gets the full language, country, and variant names in the specified
     * Locale for the codes of this {@code Locale}.
     * 
     * @param locale
     *            the {@code Locale} for which the display name is retrieved.
     * @return a {@code Locale} name.
     */
    public String getDisplayName(Locale locale) {
        return locale.getDisplayName();
    }

    /**
     * Gets the full variant name in the default {@code Locale} for the variant code of
     * this {@code Locale}. If there is no matching variant name, the variant code is
     * returned.
     * 
     * @return a variant name.
     */
    public final String getDisplayVariant() {
        return "";
    }

    /**
     * Gets the full variant name in the specified {@code Locale} for the variant code
     * of this {@code Locale}. If there is no matching variant name, the variant code is
     * returned.
     *
     * @param locale
     *            the {@code Locale} for which the display name is retrieved.
     * @return a variant name.
     */
	public String getDisplayVariant(Locale locale) {
        return locale.getDisplayVariant();
	}

    /**
     * Gets the three letter ISO country code which corresponds to the country
     * code for this {@code Locale}.
     *
     * @return a three letter ISO language code.
     * @throws MissingResourceException
     *                if there is no matching three letter ISO country code.
     */
	public String getISO3Country() throws MissingResourceException {
        return "GBR";
	}

    /**
     * Gets the three letter ISO language code which corresponds to the language
     * code for this {@code Locale}.
     *
     * @return a three letter ISO language code.
     * @throws MissingResourceException
     *                if there is no matching three letter ISO language code.
     */
	public String getISO3Language() throws MissingResourceException {
        return "ENG";
	}

    /**
     * Gets the list of two letter ISO country codes which can be used as the
     * country code for a {@code Locale}.
     * 
     * @return an array of strings.
     */
    public static String[] getISOCountries() {
        return new String[] { "GBR" };
    }

    /**
     * Gets the list of two letter ISO language codes which can be used as the
     * language code for a {@code Locale}.
     *
     * @return an array of strings.
     */
	public static String[] getISOLanguages() {
        return new String[] { "ENG" };
	}

    /**
     * Gets the language code for this {@code Locale} or the empty string of no language
     * was set.
     * 
     * @return a language code.
     */
    public String getLanguage() {
        return languageCode;
    }

    /**
     * Gets the variant code for this {@code Locale} or an empty {@code String} of no variant
     * was set.
     * 
     * @return a variant code.
     */
    public String getVariant() {
        return variantCode;
    }

    /**
     * Returns an integer hash code for the receiver. Objects which are equal
     * return the same value for this method.
     * 
     * @return the receiver's hash.
     * @see #equals
     */
    @Override
    public synchronized int hashCode() {
        return countryCode.hashCode() + languageCode.hashCode()
                + variantCode.hashCode();
    }

    /**
     * Sets the default {@code Locale} to the specified {@code Locale}.
     * 
     * @param locale
     *            the new default {@code Locale}.
     * @throws SecurityException
     *                if there is a {@code SecurityManager} in place which does not allow this
     *                operation.
     */
    public synchronized static void setDefault(Locale locale) {
    	defaultLocale = locale;
    }

    /**
     * Returns the string representation of this {@code Locale}. It consists of the
     * language followed by the country and at the end the variant. They are
     * separated by underscores. If the language is missing the string begins
     * with an underscore. If the country is missing there are 2 underscores
     * between the language and the variant. the variant alone canot be defined
     * without a language and/or a country (in this case this method would
     * return the empty string).
     *
     * Examples: "en", "en_US", "_US", "en__POSIX", "en_US_POSIX"
     *
     * @return the string representation of this {@code Locale}.
     */
    @Override
    public final String toString() {
        StringBuilder result = new StringBuilder();
        result.append(languageCode);
        if (countryCode.length() > 0) {
            result.append('_');
            result.append(countryCode);
        }
        if (variantCode.length() > 0 && result.length() > 0) {
            if (0 == countryCode.length()) {
                result.append("__"); //$NON-NLS-1$
            } else {
                result.append('_');
            }
            result.append(variantCode);
        }
        return result.toString();
    }

//    private static final ObjectStreamField[] serialPersistentFields = {
//            new ObjectStreamField("country", String.class), //$NON-NLS-1$
//            new ObjectStreamField("hashcode", Integer.TYPE), //$NON-NLS-1$
//            new ObjectStreamField("language", String.class), //$NON-NLS-1$
//            new ObjectStreamField("variant", String.class) }; //$NON-NLS-1$
//
//    private void writeObject(ObjectOutputStream stream) throws IOException {
//        ObjectOutputStream.PutField fields = stream.putFields();
//        fields.put("country", countryCode); //$NON-NLS-1$
//        fields.put("hashcode", -1); //$NON-NLS-1$
//        fields.put("language", languageCode); //$NON-NLS-1$
//        fields.put("variant", variantCode); //$NON-NLS-1$
//        stream.writeFields();
//    }
//
//    private void readObject(ObjectInputStream stream) throws IOException,
//            ClassNotFoundException {
//        ObjectInputStream.GetField fields = stream.readFields();
//        countryCode = (String) fields.get("country", ""); //$NON-NLS-1$//$NON-NLS-2$
//        languageCode = (String) fields.get("language", ""); //$NON-NLS-1$//$NON-NLS-2$
//        variantCode = (String) fields.get("variant", ""); //$NON-NLS-1$//$NON-NLS-2$
//    }
}
