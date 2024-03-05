package nl.esi.comma.expressions.generator.poosl

/*
 * Type that indicates the scope of a ComMA variable
 * GLOBAL: variables defined in state machines and data/generic constraints variable blocks
 * TRANSITION: variables that are parameters of events
 * QUANTIFIER: variables that are iterators in quantifiers
 */
enum CommaScope {
	GLOBAL,
	TRANSITION,
	QUANTIFIER
}