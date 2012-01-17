module lang::lwc::controller::AST

data Controller = controller(list[TopStatement] topstatements);

//2 opties voor TopStatement. Bij optie 2 moet je ook ADT's voor State,
//Condition en Declaration maken. Wel completer, maar is het ook mooier?
//Deze keuze moet bij meer ADT's gemaakt worden.
//optie 1
data TopStatement = state(StateName state, list[Statement] statements)
                  | condition(Identifier name, Expression expression)
                  | declaration(Identifier name, Primary val);
                  
//optie 2
/*
data TopStatement = state(State s)
                  | condition(Condition c)
                  | declaration(Declaration d);
*/
data Statement = assignment(Assignable assignable, str operator, Expression expression)
               | ifstatement(Expression expression, Statement statement)
               | goto(StateName state);
               
data Assignable = variable(Identifier name)
                | property(Identifier element, Identifier prop);
                
data Expression = prim(Primary p)
                | paren(Expression e)
                | not(Expression e)
                | mul(Expression left, Expression right)
                | div(Expression left, Expression right)
                | mod(Expression left, Expression right)
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