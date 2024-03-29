/*
 * generated by Xtext 2.10.0
 */
package nl.esi.comma.signature.ui.contentassist

import org.eclipse.emf.ecore.EObject
import org.eclipse.jface.resource.ImageDescriptor
import org.eclipse.jface.viewers.StyledString
import org.eclipse.swt.graphics.Image
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class InterfaceSignatureProposalProvider extends AbstractInterfaceSignatureProposalProvider {
	
	final Image templateIcon;

	final int TEMPLATE_DEFAULT_PRIORITY = 600;
	
	// UI TEXT
	public static String INTERFACE_TITLE = "Interface signature definition"
	static String INTERFACE_INFO = "An interface signature defines commands, signals and notifications. Optionally, types may be defined."

	public static String ENUM_TITLE = "Enum definition"
	static String ENUM_INFO = "Enum types define a set of enum literals as possible values"
	
	public static String RECORD_TITLE = "Record definition"
	static String RECORD_INFO = "Record types define tuples of typed fields"
	
	public static String TYPE_TITLE = "Type definition"
	static String TYPE_INFO = "Simple type"
	
	public static String VECTOR_TITLE = "Vector definition"
	static String VECTOR_INFO = "Simple Vector with elements of type Integer"
	
	public static String NOTIFICATION_TITLE = "Notification"
	static String NOTIFICATION_INFO = "Simple notification"
	
	public static String SIGNAL_TITLE = "Signal"
	static String SIGNAL_INFO = "Simple signal"
		
	public static String COMMAND_TITLE = "Command"
	static String COMMAND_INFO = "Simple Command"
	
	public static String COMMAND_IN_TITLE = "Command in"
	static String COMMAND_IN_INFO = "Simple Command with in parameter"
	
	public static String COMMAND_OUT_TITLE = "Command out"
	static String COMMAND_OUT_INFO = "Simple Command with out parameter"
	
	public static String COMMAND_INOUT_TITLE = "Command inout"
	static String COMMAND_INOUT_INFO = "Simple Command with inout parameter"
	
	
	new() {
		templateIcon = ImageDescriptor.createFromURL(this.class.getResource("/icons/icon_template_signature.png")).
			createImage();
	}
	
	private def createTemplate(String name, String content, String additionalInfo, Integer nrIndents,
		ContentAssistContext context) {
		createTemplate(name, content, additionalInfo, nrIndents, context, TEMPLATE_DEFAULT_PRIORITY)
	}

	private def createTemplate(String name, String content, String additionalInfo, Integer nrIndents,
		ContentAssistContext context, int priority) {
		var indent = "";
		for (var i = 0; i < nrIndents; i++) {
			indent += "\t";
		}
		var indentedContent = content.replace(System.lineSeparator, System.lineSeparator + indent)
		indentedContent = System.lineSeparator + indent + indentedContent

		var finalAdditionalInfo = content
		val proposal = createHtmlCompletionProposal(indentedContent, new StyledString(name), templateIcon,
			TEMPLATE_DEFAULT_PRIORITY, context);

		if (proposal instanceof ConfigurableCompletionProposal) {
			while (finalAdditionalInfo.startsWith(System.lineSeparator) || finalAdditionalInfo.startsWith("\r")) {
				finalAdditionalInfo = finalAdditionalInfo.substring(1);
			}
			finalAdditionalInfo = "<html><body bgcolor=\"#FFFFE1\"><style> body { font-size:9pt; font-family:'Segoe UI' }</style><pre>" +
				finalAdditionalInfo + "</pre>";
			if (additionalInfo !== null) {
				finalAdditionalInfo = finalAdditionalInfo + "<p>" + additionalInfo + "</p>";
			}
			finalAdditionalInfo = finalAdditionalInfo + "</body></html>"
			proposal.additionalProposalInfo = finalAdditionalInfo
			proposal.proposalContextResource = context.resource
			proposal.priority = priority
		}
		proposal
	}

	private def createHtmlCompletionProposal(String proposal, StyledString displayString, Image image, int priority,
		ContentAssistContext context) {
		//validation seems to interupt
		return doCreateHtmlCompletionProposal(proposal, displayString, image, priority, context);

	}
	
	private def doCreateHtmlCompletionProposal(String proposal, StyledString displayString, Image image, int priority,
		ContentAssistContext context) {
		val replacementOffset = context.getReplaceRegion().getOffset();
		val replacementLength = context.getReplaceRegion().getLength();
		val result = new HtmlConfigurableCompletionProposal(proposal, replacementOffset, replacementLength,
			proposal.length(), image, displayString, null, null);

		result.priority = priority
		result.matcher = context.matcher
		result.replaceContextLength = context.replaceContextLength
		result;
	}
	
	
	
	override complete_Signature(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_Signature(model, ruleCall, context, acceptor)
		val proposal = '''
			signature Iinterface
				
				commands
				int CommandIn (in int x)
				
				signals
				Signal(int x)
				
				notifications
				Notification(int x)
		'''
		acceptor.accept(createTemplate(INTERFACE_TITLE, proposal, INTERFACE_INFO, 0, context))
	}
	
	override complete_EnumTypeDecl(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_EnumTypeDecl(model, ruleCall, context, acceptor)
		val proposal = '''
			enum Enum {
				First
			}
		'''
		acceptor.accept(createTemplate(ENUM_TITLE, proposal, ENUM_INFO, 1, context))
	}
	
	override complete_TypeDecl(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_TypeDecl(model, ruleCall, context, acceptor)
		val proposal = '''type newType'''
		acceptor.accept(createTemplate(TYPE_TITLE, proposal, TYPE_INFO, 1, context))
	}
	
	override complete_RecordTypeDecl(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_RecordTypeDecl(model, ruleCall, context, acceptor)
		val proposal = '''
			record Record {
				int key, 
				int value
			}
		'''
		acceptor.accept(createTemplate(RECORD_TITLE, proposal, RECORD_INFO, 1, context))
	}
	
	override complete_Command(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_Command(model, ruleCall, context, acceptor)
		val proposal = '''int Command'''
		acceptor.accept(createTemplate(COMMAND_TITLE, proposal, COMMAND_INFO, 1, context))	
		
		val proposalIn = '''int CommandIn (in int value)'''
		acceptor.accept(createTemplate(COMMAND_IN_TITLE, proposalIn, COMMAND_IN_INFO, 1, context))
		
		val proposalOut = '''int CommandOut (out int value)'''
		acceptor.accept(createTemplate(COMMAND_OUT_TITLE, proposalOut, COMMAND_OUT_INFO, 1, context))
		
		val proposalInout = '''int CommandInOut (inout int value)'''
		acceptor.accept(createTemplate(COMMAND_INOUT_TITLE, proposalInout, COMMAND_INOUT_INFO, 1, context))
	}
	
	override complete_Notification(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_Notification(model, ruleCall, context, acceptor)
		
		val proposal = '''Notification(int x)'''
		acceptor.accept(createTemplate(NOTIFICATION_TITLE, proposal, NOTIFICATION_INFO, 1, context))
	}	
	
	override complete_VectorTypeDecl(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_VectorTypeDecl(model, ruleCall, context, acceptor)
		
		val proposal = '''vector Vector = int[][]'''
		acceptor.accept(createTemplate(VECTOR_TITLE, proposal, VECTOR_INFO, 1, context))
	}
	
	override complete_Signal(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_Signal(model, ruleCall, context, acceptor)
		
		val proposal = '''Signal(int x)'''
		acceptor.accept(createTemplate(SIGNAL_TITLE, proposal, SIGNAL_INFO, 1, context))
	}
	
}
