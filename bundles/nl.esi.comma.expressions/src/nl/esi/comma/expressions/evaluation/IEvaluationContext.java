package nl.esi.comma.expressions.evaluation;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.validation.ExpressionValidator;
import nl.esi.comma.types.types.TypeObject;

public interface IEvaluationContext {
	static final IEvaluationContext EMPTY = v -> null;

	Expression getExpression(ExpressionVariable variable);
	
	default TypeObject typeOf(Expression expression) {
		return ExpressionValidator.typeOf(expression);
	}
}
