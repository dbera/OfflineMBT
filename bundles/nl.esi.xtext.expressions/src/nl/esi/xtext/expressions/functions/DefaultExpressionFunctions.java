/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.functions;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.ecore.util.EcoreUtil;

import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionMap;
import nl.esi.xtext.expressions.expression.ExpressionVector;

/**
 * Standard expression function library. All methods are {@code public static}
 * and are registered via {@link ExpressionFunctionsRegistry#addLibraryFunctions}.
 *
 * Methods use EMF model types ({@link ExpressionVector}, {@link ExpressionMap})
 * directly where possible, avoiding conversion overhead. The pure Java equivalents
 * using standard collection types are documented in the Javadoc of each method.
 */
public class DefaultExpressionFunctions {

	/**
	 * Returns {@code true} if the vector is empty.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static boolean isEmpty(Collection&lt;?&gt; collection) {
	 *     return collection.isEmpty();
	 * }
	 * </pre>
	 */
	public static boolean isEmpty(ExpressionVector vector) {
		return vector.getElements().isEmpty();
	}

	/**
	 * Returns the number of elements in a vector.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static long size(Collection&lt;?&gt; collection) {
	 *     return collection.size();
	 * }
	 * </pre>
	 */
	public static long size(ExpressionVector vector) {
		return vector.getElements().size();
	}

	/**
	 * Returns the number of entries in a map.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static long size(Map&lt;?, ?&gt; map) {
	 *     return map.size();
	 * }
	 * </pre>
	 */
	public static long size(ExpressionMap map) {
		return map.getPairs().size();
	}

	/**
	 * Returns {@code true} if the vector contains an element equal to {@code value}.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static boolean contains(Collection&lt;?&gt; collection, Object value) {
	 *     return collection.stream().anyMatch(e -&gt; e != null &amp;&amp; e.equals(value));
	 * }
	 * </pre>
	 */
	public static boolean contains(ExpressionVector vector, Expression value) {
		return vector.getElements().stream().anyMatch(e -> EcoreUtil.equals(e, value));
	}

	/**
	 * Returns the vector with {@code element} appended.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static List&lt;Object&gt; add(List&lt;Object&gt; list, Object element) {
	 *     list = new ArrayList&lt;&gt;(list);
	 *     list.add(element);
	 *     return list;
	 * }
	 * </pre>
	 */
	public static ExpressionVector add(ExpressionVector vector, Expression element) {
		vector.getElements().add(element);
		return vector;
	}

	/** Converts an integer to a real (BigDecimal). */
	public static BigDecimal asReal(long value) {
		return new BigDecimal(value);
	}

	/** Returns the absolute value of an integer. */
	public static long abs(long value) {
		return Math.abs(value);
	}

	/** Returns the absolute value of a real number. */
	public static BigDecimal abs(BigDecimal value) {
		return value.abs();
	}

	/**
	 * Returns {@code true} if the map contains a key equal to {@code key}.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static boolean hasKey(Map&lt;Object, Object&gt; map, Object key) {
	 *     return map.keySet().stream().anyMatch(k -&gt; k != null &amp;&amp; k.equals(key));
	 * }
	 * </pre>
	 */
	public static boolean hasKey(ExpressionMap map, Expression key) {
		return map.getPairs().stream().anyMatch(p -> EcoreUtil.equals(p.getKey(), key));
	}

	/**
	 * Removes the entry with key equal to {@code key} and returns the modified map.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static Map&lt;Object, Object&gt; deleteKey(Map&lt;Object, Object&gt; map, Object key) {
	 *     map.remove(key);
	 *     return map;
	 * }
	 * </pre>
	 */
	public static ExpressionMap deleteKey(ExpressionMap map, Expression key) {
		map.getPairs().removeIf(p -> EcoreUtil.equals(p.getKey(), key));
		return map;
	}

	/**
	 * Returns the value of the map entry at {@code index}, or throws {@link IndexOutOfBoundsException}.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static Object get(Map&lt;Object, Object&gt; map, long index) {
	 *     return new ArrayList&lt;&gt;(map.values()).get((int) index);
	 * }
	 * </pre>
	 */
	public static Expression get(ExpressionMap map, long index) throws IndexOutOfBoundsException {
		return map.getPairs().get((int) index).getValue();
	}
	
	/**
	 * Returns the element at {@code index}, or Index out of bounds.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static Object get(List&lt;Object&gt; list, long index) {
	 *     if (index &gt;= 0 &amp;&amp; index &lt; list.size()) {
	 *         return list.get((int) index);
	 *     }
	 *     return null;
	 * }
	 * </pre>
	 */
	public static Expression get(ExpressionVector vector, long index) throws IndexOutOfBoundsException {
		return vector.getElements().get((int) index);
	}

	/**
	 * Returns the vector with the element at {@code index} replaced, or {@link IndexOutOfBoundsException}.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static List&lt;Object&gt; at(List&lt;Object&gt; list, long index, Object value) {
	 *     if (index &gt;= 0 &amp;&amp; index &lt; list.size()) {
	 *         list = new ArrayList&lt;&gt;(list);
	 *         list.set((int) index, value);
	 *     }
	 *     return list;
	 * }
	 * </pre>
	 */
	public static ExpressionVector at(ExpressionVector vector, long index, Expression value) throws IndexOutOfBoundsException {
		vector.getElements().set((int) index, value);
		return vector;
	}

	/**
	 * Returns the vector with the element at {@code index} replaced, or {@link IndexOutOfBoundsException}.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static List&lt;Object&gt; set(List&lt;Object&gt; list, long index, Object value) {
	 *     if (index &gt;= 0 &amp;&amp; index &lt; list.size()) {
	 *         list = new ArrayList&lt;&gt;(list);
	 *         list.set((int) index, value);
	 *     }
	 *     return list;
	 * }
	 * </pre>
	 */
	public static ExpressionVector set(ExpressionVector vector, long index, Expression value) throws IndexOutOfBoundsException {
		vector.getElements().set((int) index, value);
		return vector;
	}

	/** Converts an integer to its string representation. */
	public static String toString(long value) {
		return Long.toString(value);
	}

	/**
	 * Concatenates two vectors by appending all elements of {@code vector2} to {@code vector1}.
	 * <p>This is the optimized EMF implementation of the following pure Java equivalent:</p>
	 * <pre>
	 * public static List&lt;Object&gt; concat(List&lt;Object&gt; list1, List&lt;Object&gt; list2) {
	 *     return Streams.concat(list1.stream(), list2.stream()).toList();
	 * }
	 * </pre>
	 */
	public static ExpressionVector concat(ExpressionVector vector1, ExpressionVector vector2) {
		vector1.getElements().addAll(EcoreUtil.copyAll(vector2.getElements()));
		return vector1;
	}

	/** Creates an integer range {@code [0, end)}. */
	public static List<Long> range(long end) {
		return createIntRange(0, end, 1);
	}

	/** Creates an integer range {@code [start, end)}. */
	public static List<Long> range(long start, long end) {
		return createIntRange(start, end, 1);
	}

	/** Creates an integer range {@code [start, end)} with the given step. */
	public static List<Long> range(long start, long end, long step) {
		if (step == 0) throw new IllegalArgumentException("Step cannot be zero");
		return createIntRange(start, end, step);
	}

	private static List<Long> createIntRange(long start, long end, long step) {
		var result = new ArrayList<Long>();
		if (step > 0) {
			for (long i = start; i < end; i += step) result.add(i);
		} else {
			for (long i = start; i > end; i += step) result.add(i);
		}
		return result;
	}
}