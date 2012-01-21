module lang::lwc::structure::AST
/*
	AST for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

data Structure = structure(list[Statement] body);

data Statement = element(list[Modifier] modifiers, ElementName etype, str name, list[Asset] assets)
		  	   | aliaselem(str id, list[Modifier] modifiers, ElementName etype, list[Asset] assets)
		       | pipe(ElementName pid, str name, Value from, Value to, list[Asset] assets)
		       | sensor(str name, Value on, list[Asset] assets)
		       | constraint(str name, Expression expression)
		       ;

data Modifier = modifier(str id);

data Asset = asset(AssetName name, ValueList val);

data AssetName = assetname(str name);

data Value = integer(int val)
		   | realnum(real number)
		   | metric(Value size, Unit unit)
		   | booltrue()
		   | boolfalse()
		   | property(str var, Property property)
		   | variable(str var)
		   ;
		   
data ValueList = valuelist(list[Value] values);

data Property = propname(str name);

data ElementName = elementname(str id);

data Unit = unit(str name);

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
anno loc Asset@location;
anno loc AssetName@location;
anno loc Value@location;
anno loc ValueList@location;
anno loc ElementName@location;
anno loc Unit@location;
anno loc Expression@location;
