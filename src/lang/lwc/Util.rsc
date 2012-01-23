module lang::lwc::Util

import String;
import List;
import Set;

public str implode(list[str] L, str glue) = ("" | size(it) > 0 ? "<it><glue><e>" : "<e>" | str e <- L);
public str implode(set[str] S, str glue) = implode(toList(S), glue);
