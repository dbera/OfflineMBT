package nl.esi.xtext.lsp.generator.lezer

import com.google.common.collect.Iterables
import java.util.ArrayList
import java.util.List
import java.util.Set
import java.util.regex.Pattern
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.AbstractRule
import org.eclipse.xtext.EnumRule
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.TerminalRule
import org.eclipse.xtext.xtext.generator.AbstractExternalFolderAwareFragment

import static extension org.eclipse.xtext.GrammarUtil.*

class LezerGrammarFragment extends AbstractExternalFolderAwareFragment {
    @Accessors
    var String fileName

    override generate() {
        if (fileName === null) {
            fileName = grammarName.toLowerCase + '.grammar'
        }

        outputLocation.generateFile(fileName, generateLezerGrammar());
        outputLocation.generateFile(fileName + ".d.ts", generateLezerGrammarTS());
        outputLocation.generateFile('index.ts', generateIndexTS());
    }

    def protected String getGrammarName() {
        return grammar.simpleName
    }

    def protected List<AbstractRule> getAllHiddenTokens() {
        val grammars = Iterables.concat(#[grammar], grammar.allUsedGrammars)
        return grammars.filter[definesHiddenTokens].flatMap[hiddenTokens].toList
    }

    def protected Set<String> getUsedTerminalRuleNames() {
        return grammar.allParserRules.flatMap[containedRuleCalls.map[rule]].filter(TerminalRule).map[name].toSet
    }

    def protected List<LezerKeyword> allLezerKeywords() {
        val keywords = newLinkedHashMap
        for (rule : grammar.allRules.reject(TerminalRule)) {
            rule.eAllContents.filter(Keyword).forEach [ kw |
                keywords.computeIfAbsent(kw.value)[newLinkedHashSet] += rule
            ]
        }
        val terminalNames = (usedTerminalRuleNames + allHiddenTokens.map[name]).toSet
        val terminals = grammar.allTerminalRules.filter[terminalNames.contains(name)].uniqueBy[name]

        val lezerKeywords = new ArrayList(keywords.size)
        keywords.forEach [ keyword, rules |
            val terminalName = terminals.findFirst[terminal | keyword.isAmbigousTo(terminal)]?.name
            lezerKeywords += new LezerKeyword(keyword, terminalName, getHighlightTag(keyword, rules))
        ]
        return lezerKeywords
    }

    def protected boolean isAmbigousTo(String keyword, TerminalRule terminal) {
        var regEx = TerminalRuleToRegEx.createRegEx(terminal)
        if (!regEx.startsWith('^')) {
            // We always search from the start of the terminal and the keyword 
            // is ambiguous when it(s start)(partially) matches the terminal
            regEx = '^' + regEx
        }
        val pattern = Pattern.compile(regEx)
        val matcher = pattern.matcher(keyword)
        return matcher.find || matcher.hitEnd
    }

    def protected String getHighlightTag(String keyword, AbstractRule... rules) {
        val highlightTags = rules.map[highlightTag].filterNull.toSet
        if (highlightTags.size == 1) {
            return highlightTags.head
        } else if (rules.forall[EnumRule.isInstance(it)]) {
            return 'literal'
        }
        return switch (it: keyword) {
        	case null: null
            case '(',
            case ')': 'paren'
            case '[',
            case ']': 'squareBracket'
            case '{',
            case '}': 'brace'
            case 'import',
            case 'export': 'moduleKeyword'
            case 'super': 'atom'
            case 'this',
            case 'self': 'self'
            case 'null': 'null'
            case matches('(?i)(true|false)'): 'bool'
            case matches('\\w+(-\\w+)*'): 'definitionKeyword'
        }
    }

    def protected String getHighlightTag(AbstractRule rule) {
        val highlightTag = rule.annotations.map[name].findFirst[startsWith('Lezer')]?.substring(5)?.toFirstLower
        if (!highlightTag.isNullOrEmpty) {
        	return highlightTag
        } else if (rule instanceof TerminalRule) {
        	// Supporting default 'org.eclipse.xtext.common.Terminals' rules
        	return switch (rule.name) {
        		case 'ID': 'variableName' 
        		case 'INT': 'integer' 
        		case 'STRING': 'string' 
        		case 'ML_COMMENT': 'blockComment' 
        		case 'SL_COMMENT': 'lineComment'
        		case 'ANY_OTHER': 'invalid'
        	}
        }
    }

    def protected generateLezerGrammar() {
        val keywords = allLezerKeywords
        val highlightTag2keywords = keywords.groupBy[highlightTag ?: 'other']
        val rules = highlightTag2keywords.keySet.map[toFirstUpper] + usedTerminalRuleNames

        return '''
            @detectDelim
            @skip { «FOR token : allHiddenTokens SEPARATOR ' | '»«token.name»«ENDFOR» }
            
            @top «grammarName» {(
              «rules.join(' | ')»
            )*}
            
            «FOR entry : highlightTag2keywords.entrySet»
                «entry.key.toFirstUpper» {
                    «entry.value.join(' | ')[toRef]»
                }

            «ENDFOR»
            «FOR terminalName : keywords.map[terminalName].filterNull.toSet»
                kw«terminalName»<kw> { @specialize[@name={kw}]<«terminalName», kw> }
            «ENDFOR»
            
            @tokens {
              «FOR terminal : grammar.allTerminalRules.uniqueBy[name]»
                  «TerminalRuleToLezer.createLezerToken(terminal)»
              «ENDFOR»
            }
        '''
    }

    def protected generateLezerGrammarTS() '''
        import {LRParser} from "@lezer/lr"
        
        export declare const parser: LRParser
    '''

    def protected generateIndexTS() {
        val keywords = allLezerKeywords
        val highlightTag2keywords = keywords.groupBy[highlightTag]
        highlightTag2keywords.remove(null)
        val terminals = grammar.allTerminalRules.uniqueBy[name]

        return '''
            import {parser} from "./«fileName»"
            import {LRLanguage, LanguageSupport} from "@codemirror/language"
            import {styleTags, tags as t} from "@lezer/highlight"
            
            export const «grammarName»Language = LRLanguage.define({
              parser: parser.configure({
                props: [
                  styleTags({
                    «FOR entry : highlightTag2keywords.entrySet»
                        «IF entry.value.exists[terminalName !== null]»
                            "«entry.value.filter[terminalName !== null].join(' ')[keyword]»": t.«entry.key»,
                        «ENDIF»
                        «IF entry.value.exists[terminalName === null]»
                            «entry.key.toFirstUpper»: t.«entry.key»,
                        «ENDIF»
                    «ENDFOR»
                    «FOR terminal : terminals.reject[highlightTag === null]»
                        «terminal.name»: t.«terminal.highlightTag»,
                    «ENDFOR»
                  })
                ]
              })
            })
            
            export function «grammarName.toFirstLower»() {
              return new LanguageSupport(«grammarName»Language)
            }
        '''
    }

    static def <T, V> List<T> uniqueBy(Iterable<T> source, (T)=>V attr) {
        val history = newHashSet
        return source.filter[history.add(attr.apply(it))].toList
    }

    @Data
    protected static class LezerKeyword {
        val String keyword
        val String terminalName
        val String highlightTag
        
        def String toRef() {
            return terminalName === null ? '''"«keyword»"''' : '''kw«terminalName»<"«keyword»">'''
        }
    }
}
