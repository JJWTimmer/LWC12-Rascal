module lang::lwc::structure::AST
/*
	AST for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
	
	TODO: Add interlock / variant / constraint nodes
*/

data Structure = structure(list[Statement] body);

data Statement = element(list[Modifier] modifiers, ElementName etype, str name, list[Property] properties)
		  	   | aliaselem(str id, list[Modifier] modifiers, ElementName etype, list[Property] properties)
		       | pipe(ElementName pid, str name, ConnectionPoint from, ConnectionPoint to, list[Property] properties)
		       | sensor(list[Modifier] modifiers, ElementName etype, str name, ConnectionPoint on)
		       ;

data Modifier = modifier(str id);

data Property = property(PropName name, Value val);

data PropName = propertyname(str name);

data Value = id(str name)
		   | integer(int val)
		   | realnum(real number)
		   | metric(Value size, Unit unit)
		   | idlist(list[str] ids)
		   ;

data ConnectionPoint = connectionpoint(str eid, ConnectionPointName connectionpoint)
					 | singleconnection(str eid);

data ConnectionPointName = connectionpointname(str id);

data ElementName = elementname(str id);

data Unit = unit(str name);

//location annotations
anno loc Structure@location;
anno loc Statement@location;
anno loc Modifier@location;
anno loc Property@location;
anno loc PropName@location;
anno loc Value@location;
anno loc ConnectionPoint@location;
anno loc ConnectionPointName@location;
anno loc ElementName@location;
anno loc Unit@location;
