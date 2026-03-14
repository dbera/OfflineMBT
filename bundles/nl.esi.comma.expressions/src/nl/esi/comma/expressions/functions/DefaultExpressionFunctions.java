/*
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
package nl.esi.comma.expressions.functions;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.ecore.util.EcoreUtil;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionVector;

/**
 * Standard expression function library. All methods are {@code public static}
 * and are registered via {@link ExpressionFunctionsRegistry#addLibraryFunctions}.
 *
 * Methods use EMF model types ({@link ExpressionVector}, {@link ExpressionMap})
 * directly where possible, avoiding conversion overhead.
 * Commented-out variants show the equivalent List/Map-based implementations
 * The commented-out methods also work but the current implementation is more
 * efficient as it requires less conversion.
 */
public class DefaultExpressionFunctions {

	/** Returns {@code true} if the vector is empty. */
	public static boolean isEmpty(ExpressionVector vector) {
		return vector.getElements().isEmpty();
	}
//	public static boolean isEmpty(Collection<?> collection) {
//		return collection.isEmpty();
//	}

	/** Returns the number of elements in a vector. */
	public static long size(ExpressionVector vector) {
		return vector.getElements().size();
	}
//	public static long size(Collection<?> collection) {
//		return collection.size();
//	}

	/** Returns the number of entries in a map. */
	public static long size(ExpressionMap map) {
		return map.getPairs().size();
	}
//	public static long size(Map<?, ?> map) {
//		return map.size();
//	}

	/** Returns {@code true} if the vector contains an element equal to {@code value}. */
	public static boolean contains(ExpressionVector vector, Expression value) {
		return vector.getElements().stream().anyMatch(e -> EcoreUtil.equals(e, value));
	}
//	public static boolean contains(Collection<?> collection, Object value) {
//		return collection.stream().anyMatch(e -> e != null && e.equals(value));
//	}

	/** Returns the vector with {@code element} appended. */
	public static ExpressionVector add(ExpressionVector vector, Expression element) {
		vector.getElements().add(element);
		return vector;
	}
//	public static List<Object> add(List<Object> list, Object element) {
//		list = new ArrayList<>(list);
//		list.add(element);
//		return list;
//	}

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

	/** Returns {@code true} if the map contains a key equal to {@code key}. */
	public static boolean hasKey(ExpressionMap map, Expression key) {
		return map.getPairs().stream().anyMatch(p -> EcoreUtil.equals(p.getKey(), key));
	}
//	public static boolean hasKey(Map<Object, Object> map, Object key) {
//		return map.keySet().stream().anyMatch(k -> k != null && k.equals(key));
//	}

	/** Removes the entry with key equal to {@code key} and returns the modified map. */
	public static ExpressionMap deleteKey(ExpressionMap map, Expression key) {
		map.getPairs().removeIf(p -> EcoreUtil.equals(p.getKey(), key));
		return map;
	}
//	public static Map<Object, Object> deleteKey(Map<Object, Object> map, Object key) {
//		map.remove(key);
//		return map;
//	}

	/** Returns the element at {@code index}, or {@code null} if out of bounds. */
	public static Expression get(ExpressionVector vector, long index) {
		if (index >= 0 && index < vector.getElements().size()) {
			return vector.getElements().get((int) index);
		}
		return null;
	}
//	public static Object get(List<Object> list, long index) {
//		if (index >= 0 && index < list.size()) {
//			return list.get((int) index);
//		}
//		return null;
//	}

	/** Returns the vector with the element at {@code index} replaced by {@code value}. */
	public static ExpressionVector at(ExpressionVector vector, long index, Expression value) {
		if (index >= 0 && index < vector.getElements().size()) {
			vector.getElements().set((int) index, value);
		}
		return vector;
	}
//	public static List<Object> at(List<Object> list, long index, Object value) {
//		if (index >= 0 && index < list.size()) {
//			list = new ArrayList<>(list);
//			list.set((int) index, value);
//		}
//		return list;
//	}

	/** Converts an integer to its string representation. */
	public static String toString(long value) {
		return Long.toString(value);
	}

	/** Concatenates two vectors by appending all elements of {@code vector2} to {@code vector1}. */
	public static ExpressionVector concat(ExpressionVector vector1, ExpressionVector vector2) {
		vector1.getElements().addAll(EcoreUtil.copyAll(vector2.getElements()));
		return vector1;
	}
//	public static List<Object> concat(List<Object> list1, List<Object> list2) {
//		return Streams.concat(list1.stream(), list2.stream()).toList();
//	}

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
