-- The tree written back in the fields normalize.py lowers a rule to, for the cross-check.
concrete GraceCoreNorm of GraceCore = {
  lincat
    Rule, Subj, Cond, Clause, Obl, Modal, V, Op, Obj, Atom, W, Tail, CW, Num, Rest, Pred, Prep = Str ;
    [Clause] = {and : Str ; or : Str} ;
    [Atom] = {and : Str ; or : Str} ;
    [W] = Str ; [Tail] = Str ; [CW] = Str ; [Pred] = Str ;
  lin
    RPlain s o = "subject=" ++ s ++ o ;
    RIf c s o = "if=" ++ c ++ "|subject=" ++ s ++ o ;
    RWhen c = "when=" ++ c ;
    RAuth s p = "subject=" ++ s ++ "|authority=" ++ p ;
    MkObl m v o t = "|modal=" ++ m ++ "|act=" ++ v ++ "|object=" ++ o ++ t ;
    COne c = c ;
    CAnd cs = cs.and ;
    COr cs = cs.or ;
    BaseClause x y = {and = x ++ "AND" ++ y ; or = x ++ "OR" ++ y} ;
    ConsClause x xs = {and = x ++ "AND" ++ xs.and ; or = x ++ "OR" ++ xs.or} ;
    CCmp a op b = a ++ op ++ b ;
    CExists a = a ++ "EXISTS" ;
    CExistsFor a b = a ++ "EXISTS" ++ "for" ++ b ;
    CExistsPrep a p b = a ++ "EXISTS" ++ p ++ b ;
    CPred a = a ;
    SAtom a = a ;
    SCmp a op b = a ++ op ++ b ;
    ONone = [] ;
    OAtom a = a ;
    OAnd as = as.and ;
    OOr as = as.or ;
    BaseAtom x y = {and = x ++ "AND" ++ y ; or = x ++ "OR" ++ y} ;
    ConsAtom x xs = {and = x ++ "AND" ++ xs.and ; or = x ++ "OR" ++ xs.or} ;
    OCmp a op b = a ++ op ++ b ;
    OGap a op = a ++ op ;
    OCmpAnd a ps = a ++ ps ;
    MkPred op b = op ++ b ;
    BasePred x y = x ++ "AND" ++ y ;
    ConsPred x xs = x ++ "AND" ++ xs ;
    TPer a = "|timing=PER" ++ a ;
    TPerAnd as = "|timing=PER" ++ as.and ;
    TOnlyIf c = "|only_if=" ++ c ;
    TOnlyAfter a = "|timing=ONLY AFTER" ++ a ;
    TAfter a = "|timing=ONLY AFTER" ++ a ;      -- the sugar's canonical form (Timing 2, Timing 3)
    TWithin a = "|timing=WITHIN" ++ a ;
    TBefore a = "|timing=BEFORE" ++ a ;
    TOnlyUnder c = "|only_under=" ++ c ;
    TCite p n r = "|cited=" ++ p ++ n ++ r ;
    NInt i = i.s ;
    RNone = [] ;
    RWords ws = ws ;
    BaseCW = [] ;
    ConsCW w ws = w ++ ws ;
    BaseTail = [] ;
    ConsTail t ts = t ++ ts ;
    AWords ws = ws ;
    BaseW w = w ;
    ConsW w ws = w ++ ws ;
    WInt i = i.s ;
    PAmong = "among" ; PUnder = "under" ; PBetween = "between" ; POver = "over" ; PIn = "in" ; POn = "on" ; PAt = "at" ; PBy = "by" ; PWith = "with" ; PFrom = "from" ; PWithin = "within" ; PInside = "inside" ; POutside = "outside" ; PAcross = "across" ; PThrough = "through" ; PThroughout = "throughout" ; PBeyond = "beyond" ; PAgainst = "against" ; PBeside = "beside" ; PAlong = "along" ; PAround = "around" ; PNear = "near" ; PPast = "past" ; PUpon = "upon" ; PInto = "into" ;
    Must = "MUST" ; MustNot = "MUST NOT" ; May = "MAY" ;
    Equals = "EQUALS" ; NotEquals = "DOES NOT EQUAL" ;
    Exceeds = "EXCEEDS" ; NotExceeds = "DOES NOT EXCEED" ;
    Precedes = "PRECEDES" ; NotPrecedes = "DOES NOT PRECEDE" ;
    IsIn = "IS IN" ; NotIn = "IS NOT IN" ;
}
