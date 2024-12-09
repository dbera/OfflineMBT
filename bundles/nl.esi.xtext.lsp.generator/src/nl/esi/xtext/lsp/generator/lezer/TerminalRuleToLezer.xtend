package nl.esi.xtext.lsp.generator.lezer

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

import static extension org.eclipse.xtext.EcoreUtil2.getContainerOfType

class TerminalRuleToLezer {
    var negationMode = false
    var regExMode = false

    protected new() {
        // Utility that can be sub-classed
    }

    static def String createLezerToken(TerminalRule rule) {
        return new TerminalRuleToLezer().toLezerToken(rule)
    }

    protected dispatch def String toLezerToken(RuleCall it) {
        if (explicitlyCalled && rule instanceof TerminalRule) {
            return (rule as TerminalRule).alternatives.toLezerToken
        } else {
            return rule.name
        }
    }

    protected dispatch def String toLezerToken(TerminalRule it) '''«name» { «alternatives.toLezerToken» }'''

    protected dispatch def String toLezerToken(Alternatives it) {
        return if (negationMode) {
            '''«FOR elem : elements»«elem.toLezerToken»«ENDFOR»'''
        } else {
            '''(«FOR elem : elements SEPARATOR '|'»«elem.toLezerToken»«ENDFOR»)«cardinality»'''
        }
    }

    protected dispatch def String toLezerToken(Group it) {
        if (negationMode) {
            throw new UnsupportedOperationException("Negation is not supported for group rules");
        }
        return '''(«FOR elem : elements SEPARATOR ' '»«elem.toLezerToken»«ENDFOR»)«cardinality»'''
    }

    protected dispatch def String toLezerToken(NegatedToken it) {
        try {
            negationMode = true
            return '''![«terminal.toLezerToken»]«cardinality»'''
        } finally {
            negationMode = false
        }
    }


    protected dispatch def String toLezerToken(UntilToken it) {
        val rulePrefix = getContainerOfType(TerminalRule).name
        if (terminal instanceof Keyword && (terminal as Keyword).value == '*/') {
            return '''
                «rulePrefix»_MID ) }
                «rulePrefix»_MID { ( ![*] «rulePrefix»_MID | "*" «rulePrefix»_END ) }
                «rulePrefix»_END { ( "/" | "*" «rulePrefix»_END | ![/*] «rulePrefix»_MID '''
        }
        throw new UnsupportedOperationException("Until is not supported yet");
    }

    protected dispatch def String toLezerToken(Wildcard it) '''_«cardinality»'''

    protected dispatch def String toLezerToken(CharacterRange it) {
        try {
            regExMode = true
            return '''$[«left.toLezerToken»-«right.toLezerToken»]«cardinality»'''
        } finally {
            regExMode = false
        }
    }

    protected dispatch def String toLezerToken(Keyword it) '''«value.escapeKeyword»«cardinality»'''

    protected dispatch def String toLezerToken(EOF it) '''@eof'''

    protected def String escapeKeyword(String text) {
        var escapedText = text
            .replace('\\', '\\\\')
            .replace('\r', '\\r')
            .replace('\n', '\\n')
            .replace('\t', '\\u0009')
            .replace(' ', '\\u0020')

        if (regExMode || negationMode) {
            escapedText = escapedText
                .replace(']', '\\]')
        } else if (!escapedText.contains('"')) {
            escapedText = '"' + escapedText + '"'
        } else if (!escapedText.contains("'")) {
            escapedText = "'" + escapedText + "'"
        } else {
            // Keyword containing " and ', escape "
            escapedText = '"' + escapedText.replace('"', '\\"') + '"'
        }

        return escapedText
    }
}
