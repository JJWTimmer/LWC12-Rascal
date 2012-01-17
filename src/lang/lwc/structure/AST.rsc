module lang::lwc::structure::AST

data Structure = structure(list[Statement] body);

data Statement = element(list[Modifier] modifiers, ElementName etype, Value name, list[Property] properties)
		  	   | aliaselem(Value id, list[Modifier] modifiers, ElementName etype, list[Property] properties)
		       | pipe(ElementName pid, Value name, Value from, Value to, list[Property] properties)
		       ;

data Modifier = modifier(Value id);

data Property = property(PropName name, Value val);

data PropName = propertyname(str name);

data Value = id(str name)
		   | ident(Value v)
		   | integer(bool negative, int val)
		   | metric(bool negative, int val, str unit)
		   | idlist(Value lst, Value v)
		   ;

data ConnectionPoint = connectionpoint(Value id, Value connectionpoint)
		   			 | connectionpointname(Value id)
					 ;

data ElementName = elementname(Value id);

data Unit = unit(Value name);
