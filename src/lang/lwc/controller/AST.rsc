module lang::lwc::controller::AST
/*
	TODO:
		make Expression abstraction
		remove paren-case
		add prim-case to Expression
		rename slt to leq and sgt to geq
*/

anno loc TopStatement@location;
anno loc StateName@location;
anno loc Statement@location;
anno loc Value@location;
anno loc Expression@location;
anno loc Assignable@location;
anno loc Primary@location;

data Controller = controller(list[TopStatement] topstatements);

data TopStatement = state(StateName state, list[Statement] statements)
                  | condition(str name, Expression expression)
                  | declaration(str name, Primary val);
                  
data StateName = statename(str name);

data Statement = assign(Assignable left, Value right)
               | \append(Assignable left, Value right)
               | remove(Assignable left, Value right)
               | multiply(Assignable left, Value right)
               | ifstatement(Expression expression, Statement statement)
               | goto(StateName state);
                    
data Value = expression(Expression e)
           | connections(list[str] connections);
           
data Assignable = lhsproperty(Property prop) 
                | lhsvariable(Variable var);
           
data Primary = integer(int intVal)
             | boolean(Boolean boolVal)
             | rhsvariable(Variable var)
             | rhsproperty(Property prop);
             
data Variable = variable(str name); 
data Property = property(str element, str attribute);

data Boolean = \true() | \false();                        
     
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
                | or(Expression left, Expression right);