package nl.esi.comma.testspecification.generator

import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.testspecification.testspecification.StepReference
import org.eclipse.emf.common.util.EList
import nl.esi.comma.expressions.expression.ExpressionVector
import java.util.ArrayList
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable

class ExpressionGenerator extends ExpressionsCommaGenerator {
	EList<StepReference> stepRef
	String BlockInputName

	new(EList<StepReference> stepRef, String BlockInputName) {
		this.stepRef = stepRef
		this.BlockInputName = BlockInputName
	}

	override CharSequence getFunctionText(ExpressionFunctionCall e) {
		if (e.getFunctionName().equals("add")) {
		    var lst = this.BlockInputName + "." + exprToComMASyntax(e.getArgs().get(0))
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

    /*override dispatch CharSequence exprToComMASyntax(ExpressionVariable e) {
        return '''«e.getVariable().getName()»'''
    }

    override dispatch CharSequence exprToComMASyntax(ExpressionRecordAccess e) {
        return '''«exprToComMASyntax(e.getRecord())».«e.getField().getName()»'''
    }*/
    
    override dispatch CharSequence exprToComMASyntax(ExpressionVector e) {
        var typ = typeToComMASyntax(e.typeAnnotation.type)
        var lst = new ArrayList<String>()
        for (el : e.elements) {
            var ename = exprToComMASyntax(el).toString
            // System.out.println(" ename: " + ename)
            var prefix = new String
            // commented DB. 11.02.2025. 
            // when referencing is done in the List constructor
            // using the get function which references a previous step output
            // the resolution to step name is done in the get function. see impl above. 
//            if (this.stepRef !== null) {
//                for (sf : this.stepRef) {
//                    // System.out.println(" stepref: " + sf.refStep.name)
//                    for (rd : sf.refData) {
//                        // System.out.println(" rd: " + rd.name)
//                        if (ename.contains(rd.name)) {
//                            prefix = "step_" + sf.refStep.name + ".output."
//                        }
//                    }
//                }
//            }
            lst.add(prefix + exprToComMASyntax(el).toString)
        }
        return "<" + typ + ">[" + lst.join(", ") + "]"
    }

}