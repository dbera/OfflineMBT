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
package nl.esi.comma.abstracttestspecification.tests

import nl.asml.matala.product.ProductStandaloneSetup
import nl.asml.matala.testutils.XtextGeneratorTest
import nl.esi.comma.abstracttestspecification.AbstractTestspecificationStandaloneSetup
import nl.esi.comma.abstracttestspecification.generator.to.concrete.FromAbstractToConcrete
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(AbstractTestspecificationInjectorProvider)
class FromAbstractToConcreteTest {
    @BeforeAll
    static def void setup() {
        if (!Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().containsKey('ps')) {
            System.out.println("Registering product language");
            ProductStandaloneSetup.doSetup
        }
        if (!Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().containsKey('atspec')) {
            System.out.println("Registering abstract TSPEC language");
            AbstractTestspecificationStandaloneSetup.doSetup
        }
    }

    private def void testGenerator(String testcase) {
        XtextGeneratorTest.regressionTest(new FromAbstractToConcrete(), testcase + '.atspec')
    }

    @Test
    def void testPrinter() {
        testGenerator('printer');
    }

    @Test
    def void testImaging() {
        testGenerator('imaging');
    }

    @Test
    def void testIssue249() {
        testGenerator('issue249');
    }

    @Test
    def void testIssue299() {
        testGenerator('issue299');
    }

    @Test
    def void testIssue367() {
        testGenerator('issue367');
    }

    @Test
    def void testIssue379() {
        testGenerator('issue379');
    }
}