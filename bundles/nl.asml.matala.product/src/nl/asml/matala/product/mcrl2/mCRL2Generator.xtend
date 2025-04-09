package nl.asml.matala.product.mcrl2

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import nl.asml.matala.product.product.ActionType
import nl.asml.matala.product.product.Block
import nl.asml.matala.product.product.Product
import nl.asml.matala.product.product.RefConstraint
import nl.asml.matala.product.product.SymbConstraint
import nl.asml.matala.product.product.UpdateOutVar
import nl.asml.matala.product.product.VarRef
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBulkData
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionUnary
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.Field
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.types.generator.TypesZ3Generator
import nl.esi.comma.types.types.RecordField
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypesModel
import nl.esi.comma.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import nl.asml.matala.product.product.Update
class mCRL2Generator extends AbstractGenerator {

    override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
        var prod = resource.allContents.head
        if(prod instanceof Product) {
            if (prod.specification !== null) {
                generateSpec(prod,resource,fsa)
            }
        }
    }

    def generateSpec(Product prod, Resource resource, IFileSystemAccess2 fsa) {
		var mcrl2 = new mCRL2
		
		for(b : prod.specification.blocks) {
			var Block block = null
			// if it works make it recursive
			if (b.block !== null) {
				block = b.block
			}
			if (b.refBlock !== null) {
				block = b.refBlock.system
			}
			// parse each block to derive places and transitions
			mcrl2 = populateSpec(mcrl2, block)		
		}
		
		mcrl2.display()
		
        var name = prod.specification.name
		
        val dirPath = 'mCRL2//' + name + '//'
        val modelFile = name + '_mcrl2.json'
        val typesFile = name + '_types.json'

		fsa.generateFile(dirPath + modelFile, mcrl2.toMcrl2())
		
		for(imp : prod.imports) {
            // Assumption: At most one
            val typeResource = EcoreUtil2.getResource(resource, imp.importURI)
            var typeInst = typeResource.allContents.head
            if(typeInst instanceof TypesModel) {
                var txt = (new TypesGenerator).generateJSON(typeInst) 
                fsa.generateFile(dirPath + typesFile, txt)
            }
        }
		
		var cpn2mcrl2 = new Cpn2mcrl2Generator()
		
		fsa.generateFile(dirPath + 'cpn2mcrl2.py', cpn2mcrl2.generateCpn2mcrl2(modelFile, typesFile))
		fsa.generateFile(dirPath + 'translator.py', cpn2mcrl2.generateTranslator())
		fsa.generateFile(dirPath + 'properties.json', cpn2mcrl2.generateProperties())
		fsa.generateFile(dirPath + 'to_check.json', cpn2mcrl2.generateToCheck())
	}
	
	def mCRL2 populateSpec(mCRL2 mcrl2, Block block) {	
		var map_output_input = new HashMap<String, List<String>>
		
		for(invar : block.invars) {
			mcrl2.places.add(new Place(block.name, invar.name, PType.IN, invar.type.type))
		}

		for(outvar : block.outvars) {
			mcrl2.places.add(new Place(block.name, outvar.name, PType.OUT, outvar.type.type))
		}

		for(localvar : block.localvars) {
			mcrl2.places.add(new Place(block.name, localvar.name, PType.LOCAL, localvar.type.type))
		}
		
		val (String) => String var_func = [s|s]
					
		for(act : block.initActions) {
			val expr = mCRL2Helper.initAction(act, var_func, "").split("=",2)
			mcrl2.add_to_init_place_expression_map(
				expr.get(0),
				expr.get(1)
			)
		}
		
		// populate transitions
		for(f : block.functions) {
			System.out.println(" Function-name: " + f.name)
			for(update : f.updates) 
			{
				System.out.println("  > case: " + update.name)
				var tname = f.name + "_" + update.name
				var tr = new Transition(block.name, block.name+"_"+tname)
				mcrl2.transitions.add(tr)
				var input_var_list = new HashMap<String,TypeDecl> // ArrayList<String>
				for(v : update.fnInp) 
				{
					System.out.println("	> in-var-name: " + block.name + "_"+ v.ref.name)
					input_var_list.put(v.ref.name, v.ref.type.type)
					mcrl2.add_input_arc(tr.name, v.ref.name)
					mcrl2.add_expression(tr.name, v.ref.name, v.ref.name, PType.IN, getConstraintTxt(v))
				}
				if(update.guard!==null) {
					val (String) => String fn_mcrl2 = [s|s + '_col(b)']
					System.out.println("	> guard: " + mCRL2Helper.expression(update.guard, fn_mcrl2))
					mcrl2.add_guard_expression(tr.name, mCRL2Helper.expression(update.guard, fn_mcrl2))
				}
				if(update.updateOutputVar!==null) 
				{
					var isActionsPresent = false
					for(outvar : update.updateOutputVar) 
					{
						var actTxtmCRL2 = ''
						
						isActionsPresent = false
						if(outvar.act !== null) 
						{
							isActionsPresent = true // flag true: actions are present!
							for(a : outvar.act.actions) 
							{ 
								val (String) => String fn_mcrl2 = [s|s + '_col(b)']
								System.out.println("	> act(mCRL2): " + mCRL2Helper.action(a, fn_mcrl2,""))
								actTxtmCRL2 += mCRL2Helper.action(a, fn_mcrl2,"")
							}
						}
						for(v : outvar.fnOut) 
						{
							// logic for parsing output variables to Petri net places, arcs and their expressions
							var place = new String
							if(isActionsPresent)
								place = parseOutVariablesWithActions(block, map_output_input, 
										v, tr, mcrl2, actTxtmCRL2, f.name+"_"+update.name, input_var_list)
							
						}
					}
				}
			}
		}
		return mcrl2
	}
	
	def getConstraintTxt(VarRef v) {
		var constraints = new ArrayList<Constraint>
		if(v.dataConstraints !== null) {
			for(c : v.dataConstraints.constr) {
				val (String) => String fn = [s|s]
				constraints.add(new Constraint(c.name, mCRL2Helper.expression(c.symbExpr, fn)))
			}
		}
		return constraints
	}
	
	def parseOutVariablesWithActions(Block block, HashMap<String, List<String>> map_output_input, 
									VarRef v, Transition tr, mCRL2 mcrl2, String expr, String executeFnName, 
									Map<String,TypeDecl> input_var_list) 
	{
		System.out.println("	> out-var-name: " + block.name+"_"+v.ref.name)
		var vtype = v.ref.type.type.name
		var place = new String
		
		mcrl2.add_output_arc(tr.name, v.ref.name)
		place = v.ref.name
		/* 23.01.24 */
		if(v.ref.type.type instanceof SimpleTypeDecl) {
			mcrl2.add_expression(
				tr.name, 
				v.ref.name, 
				expr, 
				PType.OUT, 
				getConstraintTxt(v)
			)
		} else {
			mcrl2.add_expression(
				tr.name, 
				v.ref.name, 
				expr, 
				PType.OUT, 
				getConstraintTxt(v)
			)
		}
		
		return place
	}

}

