module lang::lwc::controller::AST

data Controller = controller(list[TopStatement] topstatements);

data TopStatement = state(StateName state, list[Statement] statements)
                  | condition(str condition, Expression expression)
                  | declaration(Primary variable, Primary val);
                  
data StateName = statename(str name);

data Statement = assignment(Assignable assignable, str operator, Value val)
               | ifstatement(Expression expression, Statement statement)
               | goto(StateName state);
                    
data Value = expression(Expression e)
           | connections(list[str] connections);
           
data Assignable = property(str element, Property property) | variable(str var);

data Property = propname(str name);
           
data Primary = integer(int val)
             | booltrue()
             | boolfalse()
             | variable(str var)
             | property(str element, str attribute)
             ; 
                             
data Expression = prim(Primary p)
                | paren(Expression e)
                | not(Expression e)
                | mul(Expression left, Expression right)
                | div(Expression left, Expression right)
                | mdl(Expression left, Expression right)
                | add(Expression left, Expression right)
                | sub(Expression left, Expression right)
                | lt(Expression left, Expression right)
                | gt(Expression left, Expression right)
                | slt(Expression left, Expression right)
                | sgt(Expression left, Expression right)
                | eq(Expression left, Expression right)
                | neq(Expression left, Expression right)
                | and(Expression left, Expression right)
                | or(Expression left, Expression right)
                ;