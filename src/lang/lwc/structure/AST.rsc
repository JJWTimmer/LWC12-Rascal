module lang::lwc::structure::AST
extend lang::lwc::expressions::AST;
/*
	AST for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

data Structure = structure(list[Statement] body);

data Statement = element(list[Modifier] modifiers, ElementName etype, str name, list[Attribute] attributes)
		  	   | aliaselem(str name, list[Modifier] modifiers, ElementName etype, list[Attribute] attributes)
		       | pipe(ElementName etype, str name, Value from, Value to, list[Attribute] attributes)
		       | constraint(str name, Expression expression)
		       ;

data Modifier = modifier(str id);

data Attribute = attribute(AttributeName name, ValueList val)
			   | realproperty(str pname, ValueList val);

data AttributeName = attributename(str name);

data Value = integer(int val)
		   | realnum(real number)
		   | metric(Value size, Unit unit)
		   | boolean(Boolean boolVal)
		   | property(str var, PropName property)
		   | variable(str var)
		   ;
		   
data Expression = expvalue(Value v); // extension of the imported one

data ValueList = valuelist(list[Value] values);

data PropName = propname(str name);

data ElementName = elementname(str id);

data Unit = unit(list[str] units);

//location annotations
anno loc Structure@location;
anno loc Statement@location;
anno loc Modifier@location;
anno loc Attribute@location;
anno loc AttributeName@location;
anno loc Value@location;
anno loc ValueList@location;
anno loc ElementName@location;
anno loc Unit@location;
anno loc PropName@location;
anno loc Expression@location;
