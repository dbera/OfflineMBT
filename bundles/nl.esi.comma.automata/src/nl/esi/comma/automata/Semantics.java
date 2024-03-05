package nl.esi.comma.automata;

import java.util.ArrayList;
import java.util.List;

public class Semantics {
	
	/********************************/
	/////////////COEXISTENCE//////////
	/********************************/	
	// A and B (and C..) (do not) occur together
	public List<String> getCoExistence(List<Character> lst, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();
		if(lst.size() == 2) {
			if(!negation) str.add(getCoExistenceInst(lst.get(0), lst.get(1)));
			else str.add(getNotCoExistenceInst(lst.get(0), lst.get(1)));
		}
		else if(lst.size() > 2) {
			for(int i = 0 ; i < lst.size(); i++) {
				for(int j = 0; j < lst.size(); j++) {
					if(i != j) {
						if(!negation) str.add(getCoExistenceInst(lst.get(i), lst.get(j)));
						else str.add(getNotCoExistenceInst(lst.get(i), lst.get(j)));
					}
				}
			}
		} else { System.out.println("EXCEPTION: Constraint has only one action! "); }
		return str;
	}
	
	String getCoExistenceInst(Character a, Character b) {
		return "[^"+a+""+b+"]*(("+a+".*"+b+".*)|("+b+".*"+a+".*))*[^"+a+""+b+"]*";
	}
	
	String getNotCoExistenceInst(Character a, Character b) {
		return "[^"+a+""+b+"]*(("+a+"[^"+b+"]*)|("+b+"[^"+a+"]*))?";
	}

	/*******************************/
	/////////////SUCCESSION//////////
	/*******************************/	
	// A (or | and C..) occurs if and only if (not) followed by B (or | and D..) 
	public List<String> getSuccession(List<Character> lstA, RelationType RTA, List<Character> lstB, RelationType RTB, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();

		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) str.add(getSuccessionInst(getStringOR(lstA), getStringOR(lstB)));
				else str.add(getNotSuccessionInst(getStringOR(lstA), getStringOR(lstB)));
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) str.add(getSuccessionInst(getStringOR(lstA), bStr));
					else str.add(getNotSuccessionInst(getStringOR(lstA), bStr));
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) str.add(getSuccessionInst(aStr, getStringOR(lstB)));
					else str.add(getNotSuccessionInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) str.add(getSuccessionInst(aStr, bStr));
						else str.add(getNotSuccessionInst(aStr, bStr));
					}
				}
			}
		}
		return str;	
	}
	
	String getSuccessionInst(String a, String b) {
		return "[^"+a+""+b+"]*("+a+".*"+b+")*[^"+a+""+b+"]*";
	}	
	public String getNotSuccessionInst(String a, String b) {
		return "[^"+a+"]*("+a+"[^"+b+"]*)*[^"+a+""+b+"]*";
	}

	/*******************************/
	/////////CHAIN SUCCESSION///////
	/*******************************/	
	// A (or | and C..) occurs if and only if (not) immediately followed by B (or | and D..) 
	public List<String> getChainSuccession(List<Character> lstA, RelationType RTA, List<Character> lstB, RelationType RTB, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();

		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) str.add(getChainSuccessionInst(getStringOR(lstA), getStringOR(lstB)));
				else str.add(getNotChainSuccessionInst(getStringOR(lstA), getStringOR(lstB)));
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) str.add(getChainSuccessionInst(getStringOR(lstA), bStr));
					else str.add(getNotChainSuccessionInst(getStringOR(lstA), bStr));
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) str.add(getChainSuccessionInst(aStr, getStringOR(lstB)));
					else str.add(getNotChainSuccessionInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) str.add(getChainSuccessionInst(aStr, bStr));
						else str.add(getNotChainSuccessionInst(aStr, bStr));
					}
				}
			}
		}
		return str;			
	}
	
	String getChainSuccessionInst(String a, String b) {
		return "[^"+a+""+b+"]*("+a+""+b+"[^"+a+""+b+"]*)*[^"+a+""+b+"]*";
	}	
	String getNotChainSuccessionInst(String a, String b) {
		return "[^"+a+"]*("+a+""+a+"*[^"+a+""+b+"][^"+a+"]*)*([^"+a+"]*|"+a+")";
	}	

	/****************************/
	/////////ALT SUCCESSION///////
	/****************************/	
	// A occurs if and only if followed by B with no A and B (C, D�) in between
	public List<String> getAlternateSuccession(List<Character> lstA, RelationType RTA, 
											   List<Character> lstB, RelationType RTB, 
											   List<Character> lstC, RelationType RTC,
											   boolean negation) {
		ArrayList<String> str = new ArrayList<String>();
		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) { 
					if(RTC.equals(RelationType.AND)) str.add(getAlternateSuccessionInst(getStringOR(lstA), getStringOR(lstB), getStringSequence(lstC)));
					else str.add(getAlternateSuccessionInst(getStringOR(lstA), getStringOR(lstB), getStringOR(lstC)));
				} else {
					if(RTC.equals(RelationType.AND)) str.add(getNotAlternateSuccessionInst(getStringOR(lstA), getStringOR(lstB), getStringSequence(lstC)));
					else str.add(getNotAlternateSuccessionInst(getStringOR(lstA), getStringOR(lstB), getStringOR(lstC)));
				}
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) {
						if(RTC.equals(RelationType.AND)) str.add(getAlternateSuccessionInst(getStringOR(lstA), bStr, getStringSequence(lstC)));
						else str.add(getAlternateSuccessionInst(getStringOR(lstA), bStr, getStringOR(lstC)));
					} else {
						if(RTC.equals(RelationType.AND)) str.add(getNotAlternateSuccessionInst(getStringOR(lstA), bStr, getStringSequence(lstC)));
						else str.add(getNotAlternateSuccessionInst(getStringOR(lstA), bStr, getStringOR(lstC)));
					}
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) {
						if(RTC.equals(RelationType.AND)) str.add(getAlternateSuccessionInst(aStr, getStringOR(lstB), getStringSequence(lstC)));
						else str.add(getAlternateSuccessionInst(aStr, getStringOR(lstB), getStringOR(lstC)));
					} else {
						if(RTC.equals(RelationType.AND)) str.add(getNotAlternateSuccessionInst(aStr, getStringOR(lstB), getStringSequence(lstC)));
						else str.add(getNotAlternateSuccessionInst(aStr, getStringOR(lstB), getStringOR(lstC)));
					}
					//else str.add(getNotChainSuccessionInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) {
							if(RTC.equals(RelationType.AND)) str.add(getAlternateSuccessionInst(aStr, bStr, getStringSequence(lstC)));
							else str.add(getAlternateSuccessionInst(aStr, bStr, getStringOR(lstC)));
						} else {
							if(RTC.equals(RelationType.AND)) str.add(getNotAlternateSuccessionInst(aStr, bStr, getStringSequence(lstC)));
							else str.add(getNotAlternateSuccessionInst(aStr, bStr, getStringOR(lstC)));
						}
						//else str.add(getNotChainSuccessionInst(aStr, bStr));
					}
				}
			}
		}		
		return str;
	}
		
	String getAlternateSuccessionInst(String a, String b, String c) {
		return "[^"+a+""+b+"]*("+a+"[^"+a+""+b+c+"]*"+b+"[^"+a+""+b+"]*)*[^"+a+""+b+"]*";
	}
	String getNotAlternateSuccessionInst(String a, String b, String c) {
		return "[^"+a+""+b+"]*("+a+"["+c+"]*"+b+"[^"+a+""+b+"]*)*[^"+a+""+b+"]*";
	}
	
	/***********************/
	/////////RESPONSE///////
	/***********************/
	// If A (OR|AND C..) occurs then B (OR|AND D...) eventually follows
	public List<String> getResponse(List<Character> lstA, RelationType RTA, List<Character> lstB, RelationType RTB, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();

		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) str.add(getResponseInst(getStringOR(lstA), getStringOR(lstB)));
				else str.add(getNotResponseInst(getStringOR(lstA), getStringOR(lstB)));
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) str.add(getResponseInst(getStringOR(lstA), bStr));
					else str.add(getNotResponseInst(getStringOR(lstA), bStr));
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) str.add(getResponseInst(aStr, getStringOR(lstB)));
					else str.add(getNotResponseInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) str.add(getResponseInst(aStr, bStr));
						else str.add(getNotResponseInst(aStr, bStr));
					}
				}
			}
		}
		return str;	
	}	
	
	String getResponseInst(String a, String b) {
		return "[^"+a+"]*("+a+".*"+b+")*[^"+a+"]*";
	}	
	String getNotResponseInst(String a, String b) {
		return "[^"+a+"]*("+a+"[^"+b+"]*"+")*";
	}
	
	/************************/
	/////////PRECEDENCE///////
	/************************/
	// Whenever B (OR|AND D...) occurs then A (OR|AND C...) should (not) have occurred before
	public List<String> getPrecedence(List<Character> lstA, RelationType RTA, List<Character> lstB, RelationType RTB, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();

		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) str.add(getPrecedenceInst(getStringOR(lstA), getStringOR(lstB)));
				else str.add(getNotPrecedenceInst(getStringOR(lstA), getStringOR(lstB)));
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) str.add(getPrecedenceInst(getStringOR(lstA), bStr));
					else str.add(getNotPrecedenceInst(getStringOR(lstA), bStr));
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) str.add(getPrecedenceInst(aStr, getStringOR(lstB)));
					else str.add(getNotPrecedenceInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) str.add(getPrecedenceInst(aStr, bStr));
						else str.add(getNotPrecedenceInst(aStr, bStr));
					}
				}
			}
		}
		return str;	
	}	
	String getPrecedenceInst(String a, String b) {
		return "[^"+b+"]*("+a+".*"+b+")*[^"+b+"]*";
	}
	String getNotPrecedenceInst(String a, String b) {
		return "("+"[^"+a+"]*"+b+")*[^"+b+"]*";
	}
	
	/****************************/
	/////////CHAIN RESPONSE///////
	/****************************/	
	// If A (OR|AND C..) occurs then B (OR|AND D...) (does not) immediately follow
	public List<String> getChainResponse(List<Character> lstA, RelationType RTA, List<Character> lstB, RelationType RTB, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();

		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) str.add(getChainResponseInst(getStringOR(lstA), getStringOR(lstB)));
				else str.add(getNotChainResponseInst(getStringOR(lstA), getStringOR(lstB)));
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) str.add(getChainResponseInst(getStringOR(lstA), bStr));
					else str.add(getNotChainResponseInst(getStringOR(lstA), bStr));
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) str.add(getChainResponseInst(aStr, getStringOR(lstB)));
					else str.add(getNotChainResponseInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) str.add(getChainResponseInst(aStr, bStr));
						else str.add(getNotChainResponseInst(aStr, bStr));
					}
				}
			}
		}
		return str;	
	}
	
	String getChainResponseInst(String a, String b) {
		return "[^"+a+"]*("+a+b+"[^"+a+"]*)*[^"+a+"]*";
	}
	String getNotChainResponseInst(String a, String b) {
		return "[^"+a+"]*("+a+"[^"+a+b+"]+"+"[^"+a+"]*"+")*[^"+a+"]*";
	}
	
	/*****************************/
	/////////CHAIN PRECEDENCE///////
	/*****************************/
	// Whenever B (OR|AND D...) occurs then A (OR|AND C..) must (not) immediately precede it
	public List<String> getChainPrecedence(List<Character> lstA, RelationType RTA, List<Character> lstB, RelationType RTB, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();

		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) str.add(getChainPrecedenceInst(getStringOR(lstA), getStringOR(lstB)));
				else str.add(getNotChainPrecedenceInst(getStringOR(lstA), getStringOR(lstB)));
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) str.add(getChainPrecedenceInst(getStringOR(lstA), bStr));
					else str.add(getNotChainPrecedenceInst(getStringOR(lstA), bStr));
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) str.add(getChainPrecedenceInst(aStr, getStringOR(lstB)));
					else str.add(getNotChainPrecedenceInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) str.add(getChainPrecedenceInst(aStr, bStr));
						else str.add(getNotChainPrecedenceInst(aStr, bStr));
					}
				}
			}
		}
		return str;	
	}
	
	String getChainPrecedenceInst(String a, String b) {
		return "[^"+b+"]*("+a+b+"[^"+b+"]*)*[^"+b+"]*";
	}
	String getNotChainPrecedenceInst(String a, String b) {
		return "[^"+b+"]*("+"[^"+a+"]"+b+")*[^"+b+"]*";
	}
	
	/*********************************/
	/////////ALTERNATE RESPONSE///////
	/********************************/
	// If A (OR|AND X...) occurs then B (OR|AND Y...) must follow with no (only) A (OR|AND X...) and C (OR|AND Z...) in between
	public List<String> getAlternateResponse(List<Character> lstA, RelationType RTA, 
											   List<Character> lstB, RelationType RTB, 
											   List<Character> lstC, RelationType RTC,
											   boolean negation) {
		ArrayList<String> str = new ArrayList<String>();
		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) { 
					if(RTC.equals(RelationType.AND)) str.add(getAlternateResponseInst(getStringOR(lstA), getStringOR(lstB), getStringSequence(lstC)));
					else str.add(getAlternateResponseInst(getStringOR(lstA), getStringOR(lstB), getStringOR(lstC)));
				} else {
					if(RTC.equals(RelationType.AND)) str.add(getNotAlternateResponseInst(getStringOR(lstA), getStringOR(lstB), getStringSequence(lstC)));
					else str.add(getNotAlternateResponseInst(getStringOR(lstA), getStringOR(lstB), getStringOR(lstC)));
				}
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) {
						if(RTC.equals(RelationType.AND)) str.add(getAlternateResponseInst(getStringOR(lstA), bStr, getStringSequence(lstC)));
						else str.add(getAlternateResponseInst(getStringOR(lstA), bStr, getStringOR(lstC)));
					} else {
						if(RTC.equals(RelationType.AND)) str.add(getNotAlternateResponseInst(getStringOR(lstA), bStr, getStringSequence(lstC)));
						else str.add(getNotAlternateResponseInst(getStringOR(lstA), bStr, getStringOR(lstC)));
					}
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) {
						if(RTC.equals(RelationType.AND)) str.add(getAlternateResponseInst(aStr, getStringOR(lstB), getStringSequence(lstC)));
						else str.add(getAlternateResponseInst(aStr, getStringOR(lstB), getStringOR(lstC)));
					} else {
						if(RTC.equals(RelationType.AND)) str.add(getNotAlternateResponseInst(aStr, getStringOR(lstB), getStringSequence(lstC)));
						else str.add(getNotAlternateResponseInst(aStr, getStringOR(lstB), getStringOR(lstC)));
					}
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) {
							if(RTC.equals(RelationType.AND)) str.add(getAlternateResponseInst(aStr, bStr, getStringSequence(lstC)));
							else str.add(getAlternateResponseInst(aStr, bStr, getStringOR(lstC)));
						} else {
							if(RTC.equals(RelationType.AND)) str.add(getNotAlternateResponseInst(aStr, bStr, getStringSequence(lstC)));
							else str.add(getNotAlternateResponseInst(aStr, bStr, getStringOR(lstC)));
						}
					}
				}
			}
		}		
		return str;
	}	
	
	String getAlternateResponseInst(String a, String b, String c) {
		return "[^"+a+"]*("+a+"[^"+a+c+"]*"+b+"[^"+a+"]*)*[^"+a+"]*";
	}
	String getNotAlternateResponseInst(String a, String b, String c) {
		return "[^"+a+"]*("+a+"["+c+"]*"+b+"[^"+a+"]*)*[^"+a+"]*";
		// return "[^"+a+"]*("+a+"["+c+"]*"+b+"[^"+a+"]*)*";
	}
	/***********************************/
	/////////ALTERNATE PRECEDENCE///////
	/**********************************/
	// Whenever B (OR|AND Y...) occurs then A (OR|AND X...) must have occurred before with no B (OR|AND Y...) and C (OR|AND Z...) in between
	public List<String> getAlternatePrecedence(List<Character> lstA, RelationType RTA, 
											   List<Character> lstB, RelationType RTB, 
											   List<Character> lstC, RelationType RTC,
											   boolean negation) {
		ArrayList<String> str = new ArrayList<String>();
		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) { 
					if(RTC.equals(RelationType.AND)) str.add(getAlternatePrecedenceInst(getStringOR(lstA), getStringOR(lstB), getStringSequence(lstC)));
					else str.add(getAlternatePrecedenceInst(getStringOR(lstA), getStringOR(lstB), getStringOR(lstC)));
				} else {
					if(RTC.equals(RelationType.AND)) str.add(getNotAlternatePrecedenceInst(getStringOR(lstA), getStringOR(lstB), getStringSequence(lstC)));
					else str.add(getNotAlternatePrecedenceInst(getStringOR(lstA), getStringOR(lstB), getStringOR(lstC)));
				}
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) {
						if(RTC.equals(RelationType.AND)) str.add(getAlternatePrecedenceInst(getStringOR(lstA), bStr, getStringSequence(lstC)));
						else str.add(getAlternatePrecedenceInst(getStringOR(lstA), bStr, getStringOR(lstC)));
					} else {
						if(RTC.equals(RelationType.AND)) str.add(getNotAlternatePrecedenceInst(getStringOR(lstA), bStr, getStringSequence(lstC)));
						else str.add(getNotAlternatePrecedenceInst(getStringOR(lstA), bStr, getStringOR(lstC)));
					}
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) {
						if(RTC.equals(RelationType.AND)) str.add(getAlternatePrecedenceInst(aStr, getStringOR(lstB), getStringSequence(lstC)));
						else str.add(getAlternatePrecedenceInst(aStr, getStringOR(lstB), getStringOR(lstC)));
					} else {
						if(RTC.equals(RelationType.AND)) str.add(getNotAlternatePrecedenceInst(aStr, getStringOR(lstB), getStringSequence(lstC)));
						else str.add(getNotAlternatePrecedenceInst(aStr, getStringOR(lstB), getStringOR(lstC)));
					}
					//else str.add(getNotChainSuccessionInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) {
							if(RTC.equals(RelationType.AND)) str.add(getAlternatePrecedenceInst(aStr, bStr, getStringSequence(lstC)));
							else str.add(getAlternatePrecedenceInst(aStr, bStr, getStringOR(lstC)));
						} else {
							if(RTC.equals(RelationType.AND)) str.add(getNotAlternatePrecedenceInst(aStr, bStr, getStringSequence(lstC)));
							else str.add(getNotAlternatePrecedenceInst(aStr, bStr, getStringOR(lstC)));
						}
						//else str.add(getNotChainSuccessionInst(aStr, bStr));
					}
				}
			}
		}		
		return str;		
	}
	
	String getAlternatePrecedenceInst(String a, String b, String c) {
		return "[^"+b+"]*("+a+"[^"+b+c+"]*"+b+"[^"+b+"]*)*[^"+b+"]*";
	}
	String getNotAlternatePrecedenceInst(String a, String b, String c) {
		return "[^"+b+"]*("+a+"["+c+"]*"+b+"[^"+b+"]*)*[^"+b+"]*";
	}
	
	/***********************************/
	/////////RESPONDED EXISTENCE////////
	/**********************************/
	// If A (OR|And C..) occurs then B (OR|AND D...) occurs as well
	public List<String> getRespondedExistence(List<Character> lstA, RelationType RTA, List<Character> lstB, RelationType RTB, boolean negation) {
		ArrayList<String> str = new ArrayList<String>();

		if(RTA.equals(RelationType.OR)) {
			if(RTB.equals(RelationType.OR)) {
				// generate or strings for A and B
				if(!negation) str.add(getRespondedExistenceInst(getStringOR(lstA), getStringOR(lstB)));
				//else str.add(getNotRespondedExistenceInst(getStringOR(lstA), getStringOR(lstB)));
			} else { // RTB = RelationType.AND //
				// generate or string for A and generate for each elm of B
				for(Character b : lstB) {
					String bStr = new String();
					bStr+=b;
					if(!negation) str.add(getRespondedExistenceInst(getStringOR(lstA), bStr));
					//else str.add(getNotRespondedExistenceInst(getStringOR(lstA), bStr));
				}
			}
		} else { // RTA = RelationType.AND //	
			if(RTB.equals(RelationType.OR)) {
				// generate for each elm of A and generate or string for B
				for(Character a : lstA) {
					String aStr = new String();
					aStr+=a;
					if(!negation) str.add(getRespondedExistenceInst(aStr, getStringOR(lstB)));
					//else str.add(getNotRespondedExistenceInst(aStr, getStringOR(lstB)));
				}
			} else { // RTB = RelationType.AND //
				// generate for each elm of A and each elm of B
				for(Character a : lstA) {
					for(Character b : lstB) {
						String aStr = new String();
						aStr+=a;
						String bStr = new String();
						bStr+=b;
						if(!negation) str.add(getRespondedExistenceInst(aStr, bStr));
						//else str.add(getNotRespondedExistenceInst(aStr, bStr));
					}
				}
			}
		}
		return str;	
	}	
	
	String getRespondedExistenceInst(String a, String b) {
		return "[^"+a+"]*(("+a+".*"+b+".*)|("+b+".*"+a+".*))*[^"+a+"]*";
	}
	

	/***********************************/
	/////////ATLEAST N Times////////
	/**********************************/
	public List<String> getAtLeast(List<Character> lstA, int n) {
		ArrayList<String> str = new ArrayList<String>();
		for(Character a : lstA)
			str.add("[^"+a+"]*(("+a+")[^"+a+"]*){"+n+"}.*"); 
		return str;
	}	
	/***********************************/
	/////////ATMOST N Times////////
	/**********************************/
	public List<String> getAtMost(List<Character> lstA, int n) {
		ArrayList<String> str = new ArrayList<String>();
		for(Character a : lstA)
			str.add("[^"+a+"]*(("+a+")"+"?[^"+a+"]*"+"){"+n+"}");
		return str;
	}
	
	/***********************************/
	/////////EXACTLY N TIMES////////
	/**********************************/
	// A occurs exactly n times (consecutively)
	public List<String> getExactOccurence(List<Character> lstA, int n, boolean consecutive) {
		ArrayList<String> str = new ArrayList<String>();
		for(Character a : lstA)
			if(consecutive)	str.add("[^"+a+"]*("+a+"{"+n+"}[^"+a+"]*)");
			else str.add("[^"+a+"]*("+a+"[^"+a+"]*){"+n+"}");
		return str;
	}
	// OLD Formulation (Participation): "[^"+a+"]*("+a+"[^"+a+"]*)+[^"+a+"]*";
		
	/***********************************/
			///////// INIT ////////
	/**********************************/
	public List<String> getInit(List<Character> lstA) {
		ArrayList<String> str = new ArrayList<String>();
		str.add(""+getStringOR(lstA)+".*");
		return str;
	}
	
	/***********************************/
			///////// END ////////
	/**********************************/
	public List<String> getEnd(List<Character> lstA) {
		ArrayList<String> str = new ArrayList<String>();
		str.add(".*"+getStringOR(lstA)+"");
		return str;
	}
	
	/***********************************/
	///////// Simple Choice ////////
	/**********************************/
	public List<String> getSimpleChoice(List<Character> lstA) {
		ArrayList<String> str = new ArrayList<String>();
		str.add(".*["+getStringSequence(lstA)+"].*");
		return str;
	}

	/***********************************/
	///////// Exclusive Choice ////////
	/**********************************/
	public List<String> getExclusiveChoice(List<Character> lstA, List<Character> lstB) {
		ArrayList<String> str = new ArrayList<String>();
		str.add("([^"+getStringOR(lstB)+"]*"+getStringOR(lstA)+"[^"+getStringOR(lstB)+"]*)|([^"+getStringOR(lstA)+"]*"+getStringOR(lstB)+"[^"+getStringOR(lstA)+"]*)");
		return str;
	}
	
	/*************************************************************/
	///////////////////// HELPER FUNCTIONS ///////////////////////
	/*************************************************************/
	String getStringSequence(List<Character> lst) {
		String str = new String();
		for(Character elm : lst) {
			str+=elm;
		}
		return str;
	}
	
	String getStringOR(List<Character> lst) {
		String str = new String();
		if(lst.size()==1) str+=lst.get(0);
		if(lst.size()>1) str = "(";
		if(lst.size()>1) {
			for(int i =0; i<lst.size(); i++) {
				str += lst.get(i);
				if(i!=lst.size()-1) str+="|";
			}
		}
		if(lst.size()>1) str += ")";
		return str;
	}
}