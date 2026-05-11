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
package nl.asml.matala.product.tests

import nl.asml.matala.product.ProductStandaloneSetup
import nl.asml.matala.product.generator.ProductGenerator
import nl.asml.matala.testutils.XtextGeneratorTest
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(ProductInjectorProvider)
class ProductGeneratorTest {
    @BeforeAll
    static def void setup() {
        if (!Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().containsKey('ps')) {
            System.out.println("Registering product language");
            ProductStandaloneSetup.doSetup
        }
    }

    private def void testGenerator(String testcase) {
        XtextGeneratorTest.regressionTest(new ProductGenerator(), testcase + '.ps')
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
    def void testIssue371() {
        testGenerator('issue371');
    }
}
