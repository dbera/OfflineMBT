/**
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
package nl.asml.matala.doc.design

import java.io.InputStream
import java.nio.file.Files
import java.nio.file.Path
import java.util.Set
import java.util.jar.Manifest
import java.util.regex.Pattern
import java.util.stream.Collectors
import java.util.stream.Stream
import org.eclipse.xtend.lib.annotations.Accessors

class GenerateGrammarsDiagram {
    static val TERMINALS_GRAMMAR = new Grammar => [
        bundle = 'org.eclipse.xtext.common'
        name = 'org.eclipse.xtext.common.Terminals'
    ]

    static val GRAMMAR_PATTERN = Pattern.compile('''^grammar\s+((\w+\.)*\w+)\s+with\s+((\w+\.)*\w+)''')
    static val GENERATE_PATTERN = Pattern.compile('''^generate\s+(\w+)\s+"([^"]+)"''')
    static val IMPORT_PATTERN = Pattern.compile('''^import\s+"([^"]+)"\s+as\s+(\w+)''')
    static val FILE_EXTENSIONS_PATTERN = Pattern.compile('''^\s*fileExtensions\s+=\s+"([^"]+)"''')

    def static void main(String[] args) {
        if (args.size != 2) {
            System.err.println('Expected two arguments: [bundles_directory] [output-file]')
            System.exit(1)
        }
        val bundlesDir = Path.of(args.get(0)).toRealPath()
        val outputFile = Path.of(args.get(1))
        println('''Generate diagram: «bundlesDir» => «outputFile»''')

        val xtextFiles = Files.find(bundlesDir, Integer.MAX_VALUE, [$0.toString.endsWith('.xtext')]).toIterable
        val grammars = xtextFiles.map[createGrammar(bundlesDir)].filterNull.toList
        grammars += TERMINALS_GRAMMAR
        // Reduce grammar dependencies
        grammars.forEach[
            bundleUses.removeAll(getParentGrammar(grammars)?.bundle)
            grammarUses.removeAll(getParentGrammars(grammars).map[uri])
        ]
        grammars.sortInplace[a, b |
            return switch (a) {
                case a.getParentGrammars(grammars).contains(b): 1
                case b.getParentGrammars(grammars).contains(a): -1
                default: 0
            }
        ]
        Files.createDirectories(outputFile.parent)
        Files.write(outputFile, #[grammars.generatePlantUml])

        println(grammars.join('\n')['''<inputFile>${project.build.directory}/meta-models/«bundle»/model/generated/«simpleName».ecore</inputFile>'''])
    }

    def static String generatePlantUml(Iterable<Grammar> grammars) '''
        skinparam Arrow {
            Color Black
            Thickness 0.6
        }
        skinparam artifact {
            BackgroundColor #white/business
            BorderColor Black
            BorderThickness 1
        }
        skinparam package {
            FontStyle Plain
            BorderColor LightSlateGray
            BorderThickness 1
        }
        skinparam RoundCorner 8

        'Declaring bundles and grammars
        «FOR g : grammars»
        package «g.bundle» {
            artifact «g.simpleName» as «g.name»«IF !g.fileExtensions.nullOrEmpty» <<«g.fileExtensions»>>«ENDIF»
        }
        «ENDFOR»

        'Declaring bundle and grammar dependencies
        «FOR g : grammars»
            «IF !g.parent.isNullOrEmpty»«g.name» -up-|> «g.parent»«ENDIF»
            «FOR use : g.grammarUses.map[uri | grammars.findFirst[gr | gr.uri == uri]].filterNull»
            «g.name» -up-> «use.name»
            «ENDFOR»
            «FOR use : g.bundleUses.map[bundle | grammars.findFirst[gr | gr.bundle == bundle]].filterNull»
            «g.bundle» .up.> «use.bundle»
            «ENDFOR»
        «ENDFOR»
    '''

    def static Grammar createGrammar(Path xtextFile, Path bundlesDir) {
        if (xtextFile.contains(Path.of('target')) || xtextFile.contains(Path.of('bin'))) {
            return null
        }
        val fileName = com.google.common.io.Files.getNameWithoutExtension(xtextFile.fileName.toString)
        val xtextLines = Files.lines(xtextFile).toIterable
        val mwe2Lines = Files.lines(xtextFile.resolveSibling('''Generate«fileName».mwe2''')).toIterable
        val bundlePath = xtextFile.getName(bundlesDir.nameCount)
        val manifest = new Manifest(bundlesDir.resolve(bundlePath).resolve('META-INF/MANIFEST.MF').read)
        val requiredBundles = manifest.mainAttributes.getValue('Require-Bundle')

        return new Grammar => [
            bundle = bundlePath.toString
            name = xtextLines.matchAndReturn(GRAMMAR_PATTERN, '$1').head
            parent = xtextLines.matchAndReturn(GRAMMAR_PATTERN, '$3').head
            uri = xtextLines.matchAndReturn(GENERATE_PATTERN, '$2').head
            grammarUses += xtextLines.matchAndReturn(IMPORT_PATTERN, '$1')
            bundleUses += requiredBundles.split(',').map[split(';').head]
            fileExtensions = mwe2Lines.matchAndReturn(FILE_EXTENSIONS_PATTERN, '$1').head
        ]
    }

    @Accessors
    static class Grammar {
        val Set<String> grammarUses = newLinkedHashSet
        val Set<String> bundleUses = newLinkedHashSet

        var String bundle
        var String name
        var String parent
        var String uri
        var String fileExtensions

        def String getSimpleName() {
            val prefix = bundle + '.'
            return name.startsWith(prefix) ? name.substring(prefix.length) : name
        }

        def Set<Grammar> getParentGrammars(Iterable<Grammar> grammars) {
            val parents = newLinkedHashSet
            var parent = this.getParentGrammar(grammars)
            while (parent !== null) {
                parents += parent
                parent = parent.getParentGrammar(grammars)
            }
            return parents
        }

        def Grammar getParentGrammar(Iterable<Grammar> grammars) {
            return grammars.findFirst[g | g.name == this.parent]
        }
    }

    def static <T> Iterable<T> toIterable(Stream<T> stream) {
        return stream.collect(Collectors.toList)
    }

    def static InputStream read(Path path) {
        return path.fileSystem.provider.newInputStream(path)
    }

    def static Iterable<String> matchAndReturn(Iterable<String> lines, Pattern pattern, String replacement) {
        return lines.filter[l | pattern.matcher(l).find].map[l | pattern.matcher(l).replaceFirst(replacement)]
    }
}