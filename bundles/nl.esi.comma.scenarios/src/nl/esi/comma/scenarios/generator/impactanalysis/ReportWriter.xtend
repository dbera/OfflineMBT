package nl.esi.comma.scenarios.generator.impactanalysis

import org.eclipse.xtext.generator.IFileSystemAccess2

class ReportWriter {
	
	val IFileSystemAccess2 fsa
	val String fileName
	
	new(IFileSystemAccess2 fsa, String fileName) {
		this.fsa = fsa
		this.fileName = fileName
	}
	
	def void write(ImpactAnalysisReport report) {
		var reports = new Reports
		val byte[] dashboardHtml = reports.htmlTemplate

		fsa.generateFile(fileName, new String(dashboardHtml).replace("\"%REPORT%\"", report.toJson()))
	}
}