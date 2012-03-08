module lang::lwc::expressions::AST

data Boolean = \true() | \false();

data Expression = not(Expression e)
                | mul(Expression left, Expression right)
                | div(Expression left, Expression right)
                | mdl(Expression left, Expression right)
                | add(Expression left, Expression right)
                | sub(Expression left, Expression right)
                | lt(Expression left, Expression right)
                | gt(Expression left, Expression right)
                | leq(Expression left, Expression right)
                | geq(Expression left, Expression right)
                | eq(Expression left, Expression right)
                | neq(Expression left, Expression right)
                | and(Expression left, Expression right)
                | or(Expression left, Expression right)
                ;