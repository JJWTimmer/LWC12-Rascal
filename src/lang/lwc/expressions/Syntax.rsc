module lang::lwc::expressions::Syntax

syntax Boolean = @category="Constant" \true: "true"
			   | @category="Constant" \false: "false"
			   ;


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
			        leq: Expression "\<=" Expression |
			        geq: Expression "\>=" Expression
			      ) 
			      > left(
					eq:  Expression "==" Expression |
					neq: Expression "!=" Expression
				  )
				  > left and: Expression "and" Expression
				  > left or:  Expression "or" Expression
				  ;