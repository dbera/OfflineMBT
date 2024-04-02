/*
 * (C) Copyright 2018 TNO-ESI.
 */
package nl.esi.comma.scenarios.generator.specflow

import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.validation.ExpressionValidator
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.types.types.EnumElement
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.Field
import org.eclipse.emf.common.util.EList
import nl.esi.comma.types.types.VectorTypeDecl
import nl.esi.comma.expressions.expression.ExpressionVector
import java.util.ArrayList

class EventOutputToString {
    
    static var expressionValidator = new ExpressionValidator();
    
    static def String OuputDataToString(Expression e){
        var type = expressionValidator.typeOf(e)
        switch(type){
            SimpleTypeDecl : generateTypeString(type, e)
            EnumTypeDecl : generateTypeString(type, (e as ExpressionEnumLiteral).literal)
            VectorTypeDecl : generateTypeString(type, (e as ExpressionVector).elements)
        }
    }
    
    static def ArrayList<String> OuputDataToStringList(ExpressionRecord e){
        var strList = new ArrayList<String>()
        var type = expressionValidator.typeOf(e)
        if (type instanceof RecordTypeDecl){
            strList.addAll(generateTypeStringList(type, (e as ExpressionRecord).fields))
        }
        return strList
    }
    
    def static dispatch String generateTypeString(SimpleTypeDecl type, Expression e){
        if(type.equals(null)) return ""
        var typeStr =
        "[Start of Arg >\n"
        switch(e){
            ExpressionConstantInt : typeStr += "    ["+type.name+"] => ["+e.value+"]\n"
            ExpressionConstantBool : typeStr += "    ["+type.name+"] => ["+e.value+"]\n"
            ExpressionConstantReal : typeStr += "    ["+type.name+"] => ["+e.value+"]\n"
            ExpressionAny : typeStr += "    ANY\n"
            ExpressionConstantString : typeStr += "    ["+type.name+"] => ["+e.value+"]\n"
        }
        typeStr += "   > End of Arg]"
        return typeStr
    }
    
    def static dispatch String generateTypeString(EnumTypeDecl type, EnumElement value){
        if(type.equals(null)) return ""
        var typeStr =
        "[Start of Arg >\n"
        typeStr += "    Enum ["+type.name+"] => ["+value.name+"]\n"
        typeStr += "   > End of Arg]"
        return typeStr
    }
    
    def static ArrayList<String> generateTypeStringList(RecordTypeDecl type, EList<Field> value){
        if(type.equals(null)) return null
        var typeStr = new ArrayList<String>
        typeStr.add("[Start of Arg >\n    $$$ Record ["+type.name+"] $$$ ]")
        for(field : value){
            if (field.exp instanceof ExpressionRecord){
                typeStr.addAll(OuputDataToStringList(field.exp as ExpressionRecord))
            } else {
                typeStr.add(OuputDataToString(field.exp))
            }
        }
        typeStr.add("[$$$ End of Record ["+type.name+"] $$$\n   > End of Arg]")
        return typeStr
    }
    
    def static dispatch String generateTypeString(VectorTypeDecl type, EList<Expression> value){
        if(type.equals(null)) return ""
        var typeStr =
        "[Start of Arg >\n"
        typeStr += "    Vec["+type.name+"] => [\n"
        for(e : value){
            if (e instanceof ExpressionVector){
                typeStr += "    " + generateVectorString(e) + "\n"
            }
            if (e instanceof ExpressionConstantInt){
                typeStr += "    [int] => ["+ e.value +"]\n"
            }
        }
        typeStr += "    ]\n"
        typeStr += "   > End of Arg]"
        return typeStr
    }
    
    def static String generateVectorString(ExpressionVector e){
        var typeStr =
        "Vec[pixels] => [\n"
        for (ele : e.elements){
            if (ele instanceof ExpressionVector){
                typeStr += "    " + generateVectorString(ele) + "\n"
            } 
            
            if (ele instanceof ExpressionConstantInt){
                typeStr += "    [int] => ["+ ele.value +"]\n"
            }
        }
        typeStr += "    ]"
        return typeStr
    }

}