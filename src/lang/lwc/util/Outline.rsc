module lang::lwc::util::Outline

public data OutlineNode = olListNode(list[node] children)
				 | olSimpleNode(node child)
				 | olLeaf();