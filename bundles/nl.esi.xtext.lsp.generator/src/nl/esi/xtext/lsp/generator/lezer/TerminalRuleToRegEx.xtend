package nl.esi.xtext.lsp.generator.lezer

import java.util.regex.Pattern
import org.eclipse.xtext.Alternatives
import org.eclipse.xtext.CharacterRange
import org.eclipse.xtext.EOF
import org.eclipse.xtext.Group
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.NegatedToken
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.TerminalRule
import org.eclipse.xtext.UntilToken
import org.eclipse.xtext.Wildcard

class TerminalRuleToRegEx {
    var negationMode = false

    protected new() {
        // Utility that can be sub-classed
    }

    static def boolean matches(String text, TerminalRule rule) {
        val pattern = createPattern(rule)
        return pattern.matcher(text).matches()
    }

    static def Pattern createPattern(TerminalRule rule) {
        return Pattern.compile(rule.createRegEx, Pattern.MULTILINE)
    }

    static def String createRegEx(TerminalRule rule) {
        return new TerminalRuleToRegEx().toRegEx(rule)
    }

    protected dispatch def String toRegEx(RuleCall it) {
        return rule.toRegEx
    }

    protected dispatch def String toRegEx(TerminalRule it) {
        return alternatives.toRegEx
    }

    protected dispatch def String toRegEx(Alternatives it) {
        return if (negationMode) {
            '''«FOR elem : elements»«elem.toRegEx»«ENDFOR»'''
        } else {
            '''(«FOR elem : elements SEPARATOR '|'»«elem.toRegEx»«ENDFOR»)«cardinality»'''
        }
    }

    protected dispatch def String toRegEx(Group it) {
        if (negationMode) {
            throw new UnsupportedOperationException("Negation is not supported for group rules");
        }
        return '''(«FOR elem : elements»«elem.toRegEx»«ENDFOR»)«cardinality»'''
    }

    protected dispatch def String toRegEx(NegatedToken it) {
        try {
            negationMode = true
            return '''[^«terminal.toRegEx»]«cardinality»'''
        } finally {
            negationMode = false
        }
    }

    protected dispatch def String toRegEx(UntilToken it) '''[\\s\\S]«cardinality ?: '*'»«terminal.toRegEx»'''

    protected dispatch def String toRegEx(Wildcard it) '''.«cardinality»'''

    protected dispatch def String toRegEx(CharacterRange it) '''[«left.toRegEx»-«right.toRegEx»]«cardinality»'''

    protected dispatch def String toRegEx(Keyword it) '''«value.escapeKeyword»«cardinality»'''

    protected dispatch def String toRegEx(EOF it) ''''''

    protected def String escapeKeyword(String text) {
        return text
            .replace('\\', '\\\\')
            .replace('.', '\\.')
            .replace('?', '\\?')
            .replace('*', '\\*')
            .replace('+', '\\+')
            .replace('$', '\\$')
            .replace('^', '\\^')
            .replace('|', '\\|')
            .replace('"', '\\"')
            .replace("'", "\\'")
            .replace('(', '\\(')
            .replace(')', '\\)')
            .replace('{', '\\{')
            .replace('}', '\\}')
            .replace('[', '\\[')
            .replace(']', '\\]')
            .replace(' ', '\\p{Space}')
            .replace('\r', '\\r')
            .replace('\n', '\\n')
            .replace('\t', '\\t')
    }
}
