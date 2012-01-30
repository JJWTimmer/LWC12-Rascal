module lang::lwc::structure::AST
/*
	AST for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
	
	TODO:
		make Expression abstraction
		remove paren-case
		add val-case to Expression
		rename slt to leq and sgt to geq
*/

data Structure = structure(list[Statement] body);

data Statement = element(list[Modifier] modifiers, ElementName etype, str name, list[Attribute] attributes)
		  	   | aliaselem(str name, list[Modifier] modifiers, ElementName etype, list[Attribute] attributes)
		       | pipe(ElementName etype, str name, Value from, Value to, list[Attribute] attributes)
		       | constraint(str name, Expression expression)
		       ;

data Modifier = modifier(str id);

data Attribute = attribute(AttributeName name, ValueList val);

data AttributeName = attributename(str name);

data Value = integer(int val)
		   | realnum(real number)
		   | metric(Value size, Unit unit)
		   | booltrue()
		   | boolfalse()
		   | property(str var, PropName property)
		   | variable(str var)
		   ;
		   
data ValueList = valuelist(list[Value] values);

data PropName = propname(str name);

data ElementName = elementname(str id);

data Unit = unit(list[str] units);

data Expression = val(Value v)
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
anno loc Expression@location;
