package nl.esi.comma.constraints.generator;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

public class StringEditDistance 
{
	private final Pattern SPACE_REG = Pattern.compile("\\s+");
	private int k = 1;
		
	public static int LVdistance(String word1, String word2) {
		int len1 = word1.length();
		int len2 = word2.length();
	 
		// len1+1, len2+1, because finally return dp[len1][len2]
		int[][] dp = new int[len1 + 1][len2 + 1];
	 
		for (int i = 0; i <= len1; i++) {
			dp[i][0] = i;
		}
	 
		for (int j = 0; j <= len2; j++) {
			dp[0][j] = j;
		}
	 
		//iterate though, and check last char
		for (int i = 0; i < len1; i++) {
			char c1 = word1.charAt(i);
			for (int j = 0; j < len2; j++) {
				char c2 = word2.charAt(j);
	 
				//if last two chars equal
				if (c1 == c2) {
					//update dp value for +1 length
					dp[i + 1][j + 1] = dp[i][j];
				} else {
					int replace = dp[i][j] + 1;
					int insert = dp[i][j + 1] + 1;
					int delete = dp[i + 1][j] + 1;
	 
					int min = replace > insert ? insert : replace;
					min = delete > min ? min : delete;
					dp[i + 1][j + 1] = min;
				}
			}
		}
	 
		return dp[len1][len2];
	}
	
	public Map<String, Integer> getProfile(final String string) 
	{
        HashMap<String, Integer> shingles = new HashMap<String, Integer>();
        String string_no_space = SPACE_REG.matcher(string).replaceAll(" ");
        for (int i = 0; i < (string_no_space.length() - k + 1); i++) {
            String shingle = string_no_space.substring(i, i + k);
            Integer old = shingles.get(shingle);
            if (old != null) {
                shingles.put(shingle, old + 1);
            } else {
                shingles.put(shingle, 1);
            }
        }

        return Collections.unmodifiableMap(shingles);
    }
	
	public double similarity(String s1, String s2) {
        if (s1 == null) {
            throw new NullPointerException("s1 must not be null");
        }

        if (s2 == null) {
            throw new NullPointerException("s2 must not be null");
        }

        if (s1.equals(s2)) {
            return 1;
        }

        Map<String, Integer> profile1 = getProfile(s1);
        Map<String, Integer> profile2 = getProfile(s2);


        Set<String> union = new HashSet<String>();
        union.addAll(profile1.keySet());
        union.addAll(profile2.keySet());

        int inter = profile1.keySet().size() + profile2.keySet().size()
                - union.size();

        return 1.0 * inter / union.size();
    }
	
	/**
     * Distance is computed as 1 - similarity.
     * @param s1 The first string to compare.
     * @param s2 The second string to compare.
     * @return 1 - the Jaccard similarity.
     * @throws NullPointerException if s1 or s2 is null.
     */
    public final double distance(final String s1, final String s2, int k_value) {
		this.k = k_value;
        return 1.0 - similarity(s1, s2);
    }
}



/*public static int distance(String s1, String s2, int i, int j) 
{
    if (j == s2.length()) {
        return s1.length() - i;
    }
    if (i == s1.length()) {
        return s2.length() - j;
    }
    if (s1.charAt(i) == s2.charAt(j))
        return distance(s1, s2, i + 1, j + 1);
    
    int rep = distance(s1, s2, i + 1, j + 1) + 1;
    int del = distance(s1, s2, i, j + 1) + 1;
    int ins = distance(s1, s2, i + 1, j) + 1;
    
    return Math.min(del, Math.min(ins, rep));
}*/

/*public static int distance(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    // i == 0
    int [] costs = new int [b.length() + 1];
    for (int j = 0; j < costs.length; j++)
        costs[j] = j;
    for (int i = 1; i <= a.length(); i++) {
        // j == 0; nw = lev(i - 1, j)
        costs[0] = i;
        int nw = i - 1;
        for (int j = 1; j <= b.length(); j++) {
            int cj = Math.min(1 + Math.min(costs[j], costs[j - 1]), a.charAt(i - 1) == b.charAt(j - 1) ? nw : nw + 1);
            nw = costs[j];
            costs[j] = cj;
        }
    }
    return costs[b.length()];
}*/
