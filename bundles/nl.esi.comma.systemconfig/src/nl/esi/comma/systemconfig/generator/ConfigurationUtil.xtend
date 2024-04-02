package nl.esi.comma.systemconfig.generator

import nl.esi.comma.systemconfig.configuration.FeatureDefinition
import java.util.List
import java.util.ArrayList
import java.util.HashSet
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import java.util.HashMap
import javax.xml.crypto.dsig.keyinfo.KeyValue
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.EnumTypeDecl

class ConfigurationUtil {
	
	// old grammar with boolean feature types
	def static _getFeatureTag(List<FeatureDefinition> configRes, String tag) {
		for (features : configRes) {
			for (fea : features.features) {
				if (tag.equals(fea.name)){
					return true
				}
			}
		}
		return false
	}
	
	// for the new grammar using enumerated features
	def static getFeatureTag(List<FeatureDefinition> configRes, String tag, List<TypeDecl> featureTypes) {
        for(elm : featureTypes) {
            if(elm instanceof EnumTypeDecl) { // All configuration features are enumerated types
                if(tag.equals(elm.name)) return true
                for(lit : elm.literals)
                    if(lit.name.equals(tag)) return true
            }
        }
	    /*var tagMap = new HashMap<String,String>
	    for(features : configRes) { // for each configuration file
	        for(config: features.configurations) { // for each defined system configuration
	           tagMap = new HashMap<String,String>
	           for(f : config.FList) {
	               if(f.exp instanceof ExpressionEnumLiteral) 
	               {
	                   var enumExpr = f.exp as ExpressionEnumLiteral
	                   tagMap.put(enumExpr.type.name, enumExpr.literal.name)
	               }
	           }
	           if(tagMap.containsKey(tag)) return true
	           if(tagMap.containsValue(tag)) return true
	        }
	    }*/
	    return false
	}

    // for the new grammar using enumerated features	
    // TODO When there is no match, for now it says ALL CONFIGURATIONS. Change this to throw an error.
	def static getProducts(List<FeatureDefinition> configRes, List<String> tags) {
	    var products = new ArrayList<String>
	    if(tags.size > 0) {
	        for(features : configRes) { // for each configuration file
	            for(config : features.configurations) { // for each defined system configuration
	                var feaMap = new HashMap<String,List<String>>
	                for(f : config.FList) {
                        if(f.exp instanceof ExpressionEnumLiteral) 
                        {
                            var enumExpr = f.exp as ExpressionEnumLiteral
                            var lst = new ArrayList<String>
                            lst.add(enumExpr.literal.name)
                            if(!feaMap.containsKey(enumExpr.type.name)) 
                                feaMap.put(enumExpr.type.name, lst)
                            else feaMap.get(enumExpr.type.name).addAll(lst)
                        }
	                }
	                // check if all tags are present in configuration, if so add config.name
	                var keyvalset = new HashSet<String>
	                keyvalset.addAll(feaMap.keySet)
	                for(v : feaMap.values) keyvalset.addAll(v)
	                //println("DEBUG Selected: " + keyvalset + "  CONFIG  " + config.name)
	                //println("DEBUG Tags: " + tags)
	                if(keyvalset.containsAll(tags)) {
                        products.add(config.name)
                    }
	            }
	        }
	    }
	    //println("Added " + products)
	    return products
	}
	
	def static _getProducts(List<FeatureDefinition> configRes, List<String> tags) {
		var products = new ArrayList<String>
		if (tags.size > 0) {
			for (features : configRes) {
				for (config : features.configurations) {
					var feaList = new ArrayList<String>
					for (fea : config.featureList) {
						feaList.add(fea.name)
					}
					if (feaList.containsAll(tags)) {
						products.add(config.name)
					}
				}
			}
		}
		return products
	}
}