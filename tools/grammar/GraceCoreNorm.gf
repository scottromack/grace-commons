-- The tree written back in the fields normalize.py lowers a rule to, for the cross-check.
concrete GraceCoreNorm of GraceCore = {
  lincat
    Rule, Cond, Clause, Obl, Modal, V, Op, Obj, Atom, W, Tail = Str ;
    [Clause] = {and : Str ; or : Str} ;
    [Atom] = {and : Str ; or : Str} ;
    [W] = Str ; [Tail] = Str ;
  lin
    RPlain s o = "subject=" ++ s ++ o ;
    RIf c s o = "if=" ++ c ++ "|subject=" ++ s ++ o ;
    MkObl m v o t = "|modal=" ++ m ++ "|act=" ++ v ++ "|object=" ++ o ++ t ;
    COne c = c ;
    CAnd cs = cs.and ;
    COr cs = cs.or ;
    BaseClause x y = {and = x ++ "AND" ++ y ; or = x ++ "OR" ++ y} ;
    ConsClause x xs = {and = x ++ "AND" ++ xs.and ; or = x ++ "OR" ++ xs.or} ;
    CCmp a op b = a ++ op ++ b ;
    CExists a = a ++ "EXISTS" ;
    ONone = [] ;
    OAtom a = a ;
    OAnd as = as.and ;
    OOr as = as.or ;
    BaseAtom x y = {and = x ++ "AND" ++ y ; or = x ++ "OR" ++ y} ;
    ConsAtom x xs = {and = x ++ "AND" ++ xs.and ; or = x ++ "OR" ++ xs.or} ;
    OCmp a op b = a ++ op ++ b ;
    OGap a op = a ++ op ;
    TPer a = "|timing=PER" ++ a ;
    TOnlyIf c = "|only_if=" ++ c ;
    TCite a = "|cited=" ++ a ;
    BaseTail = [] ;
    ConsTail t ts = t ++ ts ;
    AWords ws = ws ;
    BaseW w = w ;
    ConsW w ws = w ++ ws ;
    WInt i = i.s ;
    Must = "MUST" ; MustNot = "MUST NOT" ; May = "MAY" ;
    Equals = "EQUALS" ; NotEquals = "DOES NOT EQUAL" ;
    Exceeds = "EXCEEDS" ; NotExceeds = "DOES NOT EXCEED" ;
    Precedes = "PRECEDES" ; NotPrecedes = "DOES NOT PRECEDE" ;
    IsIn = "IS IN" ; NotIn = "IS NOT IN" ;
}
