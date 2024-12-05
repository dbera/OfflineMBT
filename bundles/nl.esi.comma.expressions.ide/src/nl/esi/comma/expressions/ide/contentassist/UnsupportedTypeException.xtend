package nl.esi.comma.expressions.ide.contentassist;

import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeDecl
import org.eclipse.xtend.lib.annotations.Accessors

class UnsupportedTypeException extends RuntimeException {
    static final long serialVersionUID = -2982313254232292289L;

    @Accessors
    val TypeDecl typeDeclaration;

    new(Type type) {
        this(type?.type)
    }

    new(TypeDecl typeDeclaration) {
        super('''Unsupported type: «typeDeclaration?.name»''');
        this.typeDeclaration = typeDeclaration;
    }
}
