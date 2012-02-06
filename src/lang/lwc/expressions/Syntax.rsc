module lang::lwc::expressions::Syntax

syntax Expression = bracket "(" Expression ")"
				  | not: "not" Expression
				  > left (
			      	mul: Expression "*" Expression |
			      	div: Expression "/" Expression |
			      	mdl: Expression "%" Expression
			      )
			      > left (
			      	add: Expression "+" Expression |
					sub: Expression "-" Expression
			      )
			      > left (
			      	lt:  Expression "\<" Expression |
			        gt:  Expression "\>" Expression |
			        slt: Expression "\<=" Expression |
			        sgt: Expression "\>=" Expression
			      ) 
			      > left(
					eq:  Expression "==" Expression |
					neq: Expression "!=" Expression
				  )
				  > left and: Expression "and" Expression
				  > left or:  Expression "or" Expression
				  ;