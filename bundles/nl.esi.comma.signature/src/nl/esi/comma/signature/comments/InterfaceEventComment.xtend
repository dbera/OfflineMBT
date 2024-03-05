package nl.esi.comma.signature.comments

import java.util.HashMap
import java.util.Map
import java.util.regex.Matcher
import java.util.regex.Pattern
import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import static extension nl.esi.comma.types.utilities.TypeUtilities.*

class InterfaceEventComment {
	
	String commentString 
	
	InterfaceEvent event = null
	
	boolean valid = true
	
	String errorDescription = ""
	
	String eventComment = ""
	String returnComment = ""
	
	Map<String, String> paramComments = new HashMap<String, String>
	
	final String paramRegex = "^\\\\param\\s+\\w|\\s\\\\param\\s+\\w"
	final String returnRegex = "^\\\\return\\s|\\s\\\\return\\s|^\\\\return$|\\s\\\\return$"
	final String wordRegex = "\\w+"
	
	final Pattern paramPattern = Pattern.compile(paramRegex)
	final Pattern returnPattern = Pattern.compile(returnRegex)
	final Pattern wordPattern = Pattern.compile(wordRegex)
	
	new(InterfaceEvent event, String commentString){
		this.commentString = commentString
		this.event = event
		if(commentString !== null){
			parse()
			validate()
		}
	}
	
	def isValid() {
		valid
	}
	
	def getEventComment() {
		eventComment
	}
	
	def getReturnComment() {
		returnComment
	}
	
	def getCPPComments(){
		
		var result = eventComment.replace("\n", "\n    ") + "\n"
		for(p : event.parameters){
			result += "    \\param arg" + (event.parameters.indexOf(p) + 1).toString + " " + getCommentForParam(p.name).replace("\n", "\n    ")
			result += "\n"
		}
		
		if(event instanceof Command){
			if( ! event.type.isVoid){
				result += "    \\return " + returnComment.replace("\n", "\n    ")}
		}
		
		result
	}
		
	def getCommentForParam(String paramName){
		var String result = paramComments.get(paramName)
		if(result === null) {
			result = ""
		}
		result
	}
	
	def getErrorMessage(){
		errorDescription
	}
	
	def private validate(){
		if(commentString === null) {
			return
		}
		errorDescription = ""
		if(eventComment.contains("\\return") ||
		   paramComments.filter(p1, p2| p2.contains("\\return")).size > 0 ||
		   returnComment.contains("\\return")
		){
			errorDescription = "Improper nesting of comment tags" + "\n"
		}
		
		for(p : event.parameters){
			if(!paramComments.containsKey(p.name)){
				errorDescription += "Missing comment for parameter " + p.name + "\n"
			}
		}
		
		for(p : paramComments.keySet.toList){
			if(event.parameters.filter(pp | pp.name.equals(p)).size == 0){
				errorDescription += "Commented parameter with name " + p + " is not among event parameters" + "\n"
			}
		}
		
		if(event instanceof Command){
			if( ! event.type.isVoid) {
				if(returnComment == "") errorDescription += "Missing comment for return of the command \n"
			}
			else{
				if(returnComment !== "") errorDescription += "return comment is present for command of type void \n"
			}
		}
		else{
			if(returnComment !== "") errorDescription += "return comment is not applicable \n"
		}
		
		if(!errorDescription.equals("")){
			valid = false
		}
	}
	
	def private void parseParam(String str){
		//str starts with the word that is the param name
		var Matcher wm = wordPattern.matcher(str)
		wm.find()
		val paramName = str.substring(0, wm.end)
		if(wm.end == str.length){
			return
		}
		var docStr = str.substring(wm.end)
		var Matcher pm = paramPattern.matcher(docStr)
		if(pm.find){
			val comment = docStr.substring(0, pm.start).trim
			paramComments.put(paramName, comment)
			parseParam(docStr.substring(pm.end-1))
		}else{//check for \return
			var Matcher rm = returnPattern.matcher(docStr)
			if(rm.find){
				val comment = docStr.substring(0, rm.start).trim
				paramComments.put(paramName, comment)
				parseReturn(docStr.substring(rm.end-1))
			}else{
				val comment = docStr.trim
				paramComments.put(paramName, comment)
			}
		}
	}
	
	def private parseReturn(String str){
		returnComment = str.trim
	}
	
	def private parse(){
		var docStr = commentString
		var Matcher pm = paramPattern.matcher(docStr)
		if(pm.find()){
			val int i = pm.start()
			if(i > 0){
				eventComment = docStr.substring(0, i).trim
			}
			//The event comment has been obtained
			//Start processing the parameters
			//Cut the beginning of the comment until the word that is the name of the parameter
			docStr = docStr.substring(pm.end - 1)
			parseParam(docStr)
			
		}else{ //no parameters according to the pattern
			//check for return doc
			var Matcher rm = returnPattern.matcher(docStr)
			if(rm.find()){
				val int i = rm.start()
				if(i > 0){
					eventComment = docStr.substring(0, i).trim
				}
				//The event comment has been obtained
				//Start processing the return
				docStr = docStr.substring(rm.end-1)
				parseReturn(docStr)
			}else{//no parameters and no return
				eventComment = docStr.trim
			}
		}
	}
}