module lang::lwc::Outline

public data OutlineNode = olListNode(list[node] children)
				 | olSimpleNode(node child)
				 | olLeaf();