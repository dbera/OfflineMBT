package nl.esi.comma.constraints.generator.cpn.model

class ConstraintGenerationResult {
    val String pspecFileName
    val String acceptanceJsonFileName
    val String acceptancePythonFileName
    val String constraintFolderName
    
    

    new(
        String pspecFileName,
        String acceptanceJsonFileName,
        String acceptancePythonFileName,
        String constraintFolderName
    ) {
        this.pspecFileName = pspecFileName
        this.acceptanceJsonFileName = acceptanceJsonFileName
        this.acceptancePythonFileName = acceptancePythonFileName
        this.constraintFolderName = constraintFolderName
    }

    def String getPspecFileName() {
        pspecFileName
    }

    def String getAcceptanceJsonFileName() {
        acceptanceJsonFileName
    }

    def String getAcceptancePythonFileName() {
        acceptancePythonFileName
    }
    
    def String getConstraintFolderName() {
        constraintFolderName
    }
}