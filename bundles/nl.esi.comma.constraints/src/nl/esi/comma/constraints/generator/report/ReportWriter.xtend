package nl.esi.comma.constraints.generator.report

import org.eclipse.xtext.generator.IFileSystemAccess2

class ReportWriter {
	
	val IFileSystemAccess2 fsa
	val String fileName
	
	new(IFileSystemAccess2 fsa, String fileName) {
		this.fsa = fsa
		this.fileName = fileName
	}
	
	def void write(ConformanceReport report) {
		var reports = new Reports
		val byte[] dashboardHtml = reports.htmlTemplate
		
		fsa.generateFile(fileName, new String(dashboardHtml).replaceFirst("\"%REPORT%\"", report.toJson()))
	}
}