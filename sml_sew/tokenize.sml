datatype Symbol =
	 Lambda | (* \  *)
	 PiType | (* \\ *)
	 Return | (* >> *)
	 Body |   (* >  *)
	 Arrow |  (* -> *)
	 Equal |  (* =  *)
	 Inline | (* := *)
	 Insert|  (* <  *)
	 And |    (* &  *)
	 Is |     (* :  *)
	 Dot |    (* .  *)
	 At |     (* @  *)
	 Bang |   (* !  *)
	 Or |     (* |  *)
	 Tag |    (* '  *)
	 OpenParen |
	 OpenSquare |
	 OpneCurly |
	 CloseParen |
	 CloseSquare |
	 CloseCurly;
	 
datatype Keyword =
	 Mod |
	 End |
	 Rec;
	 

datatype Token =
	 Word |
	 Symbol of Symbol |
	 Keyword of Keyword;

type TokenMeta = {t:Token, s:string, line:int, column:int};




