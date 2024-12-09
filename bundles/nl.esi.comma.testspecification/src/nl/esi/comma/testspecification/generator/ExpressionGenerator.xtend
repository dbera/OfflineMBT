package nl.esi.comma.testspecification.generator

import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.testspecification.testspecification.StepReference
import org.eclipse.emf.common.util.EList

class ExpressionGenerator extends ExpressionsCommaGenerator {
	EList<StepReference> stepRef
	String stepName

	new(EList<StepReference> stepRef, String stepName) {
		this.stepRef = stepRef
		this.stepName = stepName
	}

	override CharSequence getFunctionText(ExpressionFunctionCall e) {
		if (e.getFunctionName().equals("add")) {
		    var lst = this.stepName + "." + exprToComMASyntax(e.getArgs().get(0))
            var idx = exprToComMASyntax(e.getArgs().get(1));
            var prefix = ""
            for (sf : this.stepRef) {
                for (rd : sf.refData) {
                    if (idx.toString.contains(rd.name)) {
                        prefix = "step_" + sf.refStep.name + ".output."
                    }
                }
            }
			return String.format("add(%s,%s)", lst, prefix+idx)
		} else if (e.getFunctionName().equals("size")) {
			return String.format("size(%s)", exprToComMASyntax(e.getArgs().get(0)))
		} else if (e.getFunctionName().equals("isEmpty")) {
			return String.format("isEmpty(%s)", exprToComMASyntax(e.getArgs().get(0)))
		} else if (e.getFunctionName().equals("contains")) {
			return String.format("contains(%s,%s)", exprToComMASyntax(e.getArgs().get(1)), exprToComMASyntax(e.getArgs().get(0)))
		} else if (e.getFunctionName().equals("abs")) {
			return String.format("abs(%s)", exprToComMASyntax(e.getArgs().get(0)))
		} else if (e.getFunctionName().equals("asReal")) {
			return String.format("asReal(%s)", exprToComMASyntax(e.getArgs().get(0)))
		} else if (e.getFunctionName().equals("hasKey")) {
			var map = exprToComMASyntax(e.getArgs().get(0));
			var key = exprToComMASyntax(e.getArgs().get(1));
			return String.format("hasKey(%s,%s)", key, map);
		} else if (e.getFunctionName().equals("get")) { 
			var lst = exprToComMASyntax(e.getArgs().get(0));
			var idx = exprToComMASyntax(e.getArgs().get(1));
			var prefix = ""
			for (sf : this.stepRef) {
				for (rd : sf.refData) {
					if (lst.toString.contains(rd.name)) {
						prefix = "step_" + sf.refStep.name + ".output."
					}
				}
			}
			return String.format("get(%s%s,%s)", prefix, lst, idx); // Changed
		} else if (e.getFunctionName().equals("deleteKey")) {
			var map = exprToComMASyntax(e.getArgs().get(0));
			var key = exprToComMASyntax(e.getArgs().get(1));
			return String.format("deleteKey(%s,%s)", map, key);
		}
	}
}