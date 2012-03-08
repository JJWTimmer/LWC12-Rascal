module lang::lwc::controller::AST
extend lang::lwc::expressions::AST;

anno loc TopStatement@location;
anno loc StateName@location;
anno loc Statement@location;
anno loc Value@location;
anno loc Expression@location;
anno loc Assignable@location;
anno loc Primary@location;

alias Statements = list[Statement];

data Controller = controller(list[TopStatement] topstatements);

data TopStatement = state(StateName state, Statements statements)
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

data Expression = expvalue(Primary p); // extension of the imported one

data Variable = variable(str name); 
data Property = property(str element, str attribute);