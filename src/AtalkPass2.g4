grammar AtalkPass2;

@members{
    Type checkTypes(Type firstType, Type secondType){
        if(firstType == null || secondType == null)
            return null;
        if(firstType instanceof NoType || secondType instanceof NoType)
            return NoType.getInstance();
        if(firstType.getClass() == secondType.getClass()){
            return firstType;
        }
        else if(firstType.getClass().isAssignableFrom(secondType.getClass())){
            return firstType;
        }
        else if(secondType.getClass().isAssignableFrom(firstType.getClass())){
            return secondType;
        }
        else{
            return NoType.getInstance();
        }
    }

    Type assignmentCheckTypes(Type Ltype, Type Rtype){
        if(Ltype instanceof CharType || Ltype instanceof IntType){
            if(Ltype.getClass().isAssignableFrom(Rtype.getClass())){
                return Ltype;
            }
        }
        return NoType.getInstance();
    }

    void beginScope() {
        SymbolTable.push();
    }

    void endScope() {
        UI.print("Stack offset: " + SymbolTable.top.getOffset(Register.SP));
        SymbolTable.pop();
    }
}

program:
        {UI.printHeader("Pass 2");}
        (actor | NL)*
    ;

actor:
    {beginScope();}
        'actor' ID '<' CONST_NUM '>' NL
            (state | receiver [$ID.text] | NL)*
        end_rule (NL | EOF)
    ;

state:
        type ID (',' ID)* NL
    ;

receiver [String container_actor] locals [boolean is_init]:
    {beginScope();}
        'receiver' rcvr_id=ID '(' (type first_arg_id=ID (',' type ID)*)? ')' NL
        {
            $is_init = ($rcvr_id.text.equals("init") && ($first_arg_id == null));
        }
            statements [container_actor, $is_init]
        end_rule NL
    ;

type:
        'char' ('[' CONST_NUM ']')*
    |   'int' ('[' CONST_NUM ']')*
    ;

block [String container_actor, boolean is_init]:
    {beginScope();}
        'begin' NL
            statements [container_actor, is_init]
        end_rule NL
    ;

statements [String container_actor, boolean is_init]:
        (statement [container_actor, is_init] | NL)*
    ;

statement [String container_actor, boolean is_init]:
        stm_vardef
    |   stm_assignment
    |   stm_foreach [container_actor, is_init]
    |   stm_if_elseif_else [container_actor, is_init]
    |   stm_quit
    |   stm_break
    |   stm_tell [container_actor, is_init]
    |   stm_write
    |   block [container_actor, is_init]
    ;

stm_vardef:
    {SymbolTable.define();}
        type ID ('=' expr)? (',' ID ('=' expr)?)* NL
    ;

stm_tell [String container_actor, boolean is_init]:
        actr=(ID | 'sender' | 'self') '<<' rcvr=ID '(' (expr (',' expr)*)? ')' NL
        {
            if($actr.text != "sender") {
                String actor_name = (($actr.text.equals("self")) ? container_actor : $actr.text);
                SymbolTableItem item = SymbolTable.top.get(SymbolTableActorItem.getKey(actor_name));
                if(item == null) {
                    UI.printError(String.format(
                        "[Line #%s] Undefined actor \"%s\" has been used.",
                        $actr.getLine(),
                        $actr.text));
                } else {
                    // TODO check recv existance.
                }
            } else {
                if($is_init)
                    UI.printError(String.format(
                        "[Line #%s] Invalid keyword \"sender\" has been used in default receiver \"init()\".",
                        $actr.getLine()));
            }
        }
    ;

stm_write:
        'write' '(' expr ')' NL {
            if(!($expr.return_type instanceof IntType || $expr.return_type instanceof CharType)){
                //print error
            }
            else if($expr.return_type instanceof ArrayType){
                if(!(((ArrayType)$expr.return_type).getMemberType() instanceof CharType)){
                    //print error
                }
            }
        }
    ;

stm_if_elseif_else [String container_actor, boolean is_init]:
    {beginScope();}
        'if' expr NL statements [container_actor, is_init]
        ('elseif' expr NL statements [container_actor, is_init])*
        ('else' NL statements [container_actor, is_init])?
        end_rule NL
    ;

stm_foreach [String container_actor, boolean is_init]:
    {beginScope();}
        'foreach' ID 'in' expr NL
            statements [container_actor, is_init]
        end_rule NL
    ;

stm_quit:
        'quit' NL
    ;

stm_break:
        'break' NL
    ;

stm_assignment:
        expr NL
    ;

end_rule:
    'end' {
        endScope();
    }
    ;

expr returns [Type return_type, boolean isLeftHand]:
        expr_assign {
            $return_type = $expr_assign.return_type;
            $isLeftHand = $expr_assign.isLeftHand;
        }
    ;

expr_assign returns [Type return_type, boolean isLeftHand]:
        expr_or '=' secondExpr = expr_assign {
            $isLeftHand = $expr_or.isLeftHand;
            if($expr_or.isLeftHand == true){
                if($expr_or.return_type instanceof CharType || $expr_or.return_type instanceof IntType){
                    
                }
            }
        }
    |   expr_or {
        $return_type = $expr_or.return_type;
        $isLeftHand = $expr_or.isLeftHand;
    }
    ;

expr_or returns [Type return_type, boolean isLeftHand]:
        expr_and expr_or_tmp {
            if($expr_or_tmp.return_type == null){
                $isLeftHand = $expr_and.isLeftHand;
            }
            else{
                $isLeftHand = false;
            }
            if($expr_or_tmp.return_type == null){
                $return_type = $expr_and.return_type;
            }
            else{
                $return_type = checkTypes($expr_and.return_type, $expr_or_tmp.return_type);                
            }
        }
    ;

expr_or_tmp returns [Type return_type]:
        'or' expr_and secondExpr = expr_or_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_and.return_type;
            }
            else{
                $return_type = checkTypes($expr_and.return_type, $secondExpr.return_type);                
            }
        }
    | {
        $return_type = null;        
    }
    ;

expr_and returns [Type return_type, boolean isLeftHand]:
        expr_eq expr_and_tmp {
            if($expr_and_tmp.return_type == null){
                $isLeftHand = $expr_eq.isLeftHand;
            }
            else{
                $isLeftHand = false;
            }
            if($expr_and_tmp.return_type == null){
                $return_type = $expr_eq.return_type;
            }
            else{
                $return_type = checkTypes($expr_eq.return_type, $expr_and_tmp.return_type);                
            }
        }
    ;

expr_and_tmp returns [Type return_type]:
        'and' expr_eq secondExpr = expr_and_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_eq.return_type;
            }
            else{
                $return_type = checkTypes($expr_eq.return_type, $secondExpr.return_type);                
            }
        }
    | {
        $return_type = null;        
    }
    ;

expr_eq returns [Type return_type, boolean isLeftHand]:
        expr_cmp expr_eq_tmp {
            if($expr_eq_tmp.return_type == null){
                $isLeftHand = $expr_cmp.isLeftHand;
            }
            else{
                $isLeftHand = false;
            }
            if($expr_eq_tmp.return_type == null){
                $return_type = $expr_cmp.return_type;
            }
            else{
                $return_type = checkTypes($expr_cmp.return_type, $expr_eq_tmp.return_type);                
            }
        }
    ;

expr_eq_tmp returns [Type return_type]:
        ('==' | '<>') expr_cmp secondExpr = expr_eq_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_cmp.return_type;
            }
            else{
                $return_type = checkTypes($expr_cmp.return_type, $secondExpr.return_type);                
            }
        }
    | {
        $return_type = null;
    }
    ;

expr_cmp returns [Type return_type, boolean isLeftHand]:
        expr_add expr_cmp_tmp {
            if($expr_cmp_tmp.return_type == null){
                $isLeftHand = $expr_add.isLeftHand;
            }
            else{
                $isLeftHand = false;
            }
            if($expr_cmp_tmp.return_type == null){
                $return_type = $expr_add.return_type;
            }
            else{
                $return_type = checkTypes($expr_add.return_type, $expr_cmp_tmp.return_type);
            }
        }
    ;

expr_cmp_tmp returns [Type return_type]:
        ('<' | '>') expr_add secondExpr = expr_cmp_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_add.return_type;
            }
            else{
                $return_type = checkTypes($expr_add.return_type, $secondExpr.return_type);                
            }
        }
    | {
        $return_type = null;
    }
    ;

expr_add returns [Type return_type, boolean isLeftHand]:
        expr_mult expr_add_tmp {
            if($expr_add_tmp.return_type == null){
                $isLeftHand = $expr_mult.isLeftHand;
            }
            else{
                $isLeftHand = false;
            }
            if($expr_add_tmp.return_type == null){
                $return_type = $expr_mult.return_type;
            }
            else{
                $return_type = checkTypes($expr_mult.return_type, $expr_add_tmp.return_type);
            }
        }
    ;

expr_add_tmp returns [Type return_type]:
        ('+' | '-') expr_mult secondExpr = expr_add_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_mult.return_type;
            }
            else{
                $return_type = checkTypes($expr_mult.return_type, $secondExpr.return_type);                
            }
        }
    | {
        $return_type = null;
    }
    ;

expr_mult returns [Type return_type, boolean isLeftHand]:
        expr_un expr_mult_tmp {
            if($expr_mult_tmp.return_type == null){
                $isLeftHand = $expr_un.isLeftHand;
            }
            else{
                $isLeftHand = false;
            }

            if($expr_mult_tmp.return_type == null){
                $return_type = $expr_un.return_type;
            }
            else{
                $return_type = checkTypes($expr_un.return_type, $expr_mult_tmp.return_type);
            }
        }
    ;

expr_mult_tmp returns [Type return_type]:
        ('*' | '/') expr_un secondExpr = expr_mult_tmp{
            if($secondExpr.return_type == null){
                $return_type = $expr_un.return_type;
            }
            else{
                $return_type = checkTypes($expr_un.return_type, $secondExpr.return_type);
            }
        }
    | {
        $return_type = null;
    }
    ;

expr_un returns [Type return_type, boolean isLeftHand]:
        ('not' | '-') secondExpr = expr_un {
            $return_type = $secondExpr.return_type;
            $isLeftHand = false;
        }
    |   expr_mem {
            $return_type = $expr_mem.return_type;
            $isLeftHand = $expr_mem.isLeftHand;
        }
    ;

expr_mem returns [Type return_type, boolean isLeftHand]:
        expr_other expr_mem_tmp [$expr_other.return_type] {
            $return_type = $expr_mem_tmp.return_type;
            $isLeftHand = $expr_other.isLeftHand;
        }
    ;

expr_mem_tmp [Type input_type] returns [Type return_type] locals [Type local_type, boolean failed]:
        '[' expr ']'{
            $failed = false;
            if($expr.return_type instanceof IntType){
                if($input_type instanceof ArrayType){
                    $local_type = ((ArrayType)($input_type)).getMemberType();
                }
                {
                    $local_type = $input_type;
                    $failed = true;
                    $return_type = NoType.getInstance();
                }
            }
            else{
                $return_type = NoType.getInstance();
            }
        }
        secondMemTmp = expr_mem_tmp [$local_type] 
        {
            if($failed == false){
                $return_type = $secondMemTmp.return_type;
            }
        }
    | {
        $return_type = $input_type;
    }
    ;

expr_other returns [Type return_type, boolean isLeftHand]:
        CONST_NUM {
            $return_type = IntType.getInstance();
            $isLeftHand = false;
        }
    |   CONST_CHAR {
            $return_type = CharType.getInstance();
            $isLeftHand = false;
        }
    |   CONST_STR {
            $return_type = new ArrayType($CONST_STR.getText().length(), CharType.getInstance());
            $isLeftHand = false;
    }
    |   ID {
            SymbolTableItem item = SymbolTable.top.get(SymbolTableVariableItemBase.getKey($ID.text));
            if(item == null) {
                UI.printError(String.format(
                    "[Line #%s] Undefined variable \"%s\" has been used.",
                    $ID.getLine(),
                    $ID.text));
                $return_type = NoType.getInstance();
                $isLeftHand = false;
            }
            else {
                if(item instanceof SymbolTableVariableItemBase){
                    Variable IDvar = ((SymbolTableVariableItemBase) item).getVariable();
                    Type IDtype = IDvar.getType();
                    $return_type = IDtype;
                    $isLeftHand = true;
                }
                else{
                    UI.printError(String.format(
                        "[Line #%s] Can't assign value to non variable item \"%s\".",
                        $ID.getLine(),
                        $ID.text));
                    $return_type = NoType.getInstance();
                    $isLeftHand = false;
                }
            }
        }
    |   inline_array {
            $return_type = new ArrayType($inline_array.size, $inline_array.return_type);
            $isLeftHand = false;
        }
    |   'read' '(' CONST_NUM ')'{
            $return_type = new ArrayType(Integer.parseInt($CONST_NUM.getText()), CharType.getInstance());
            $isLeftHand = false;               
        }
    |   '(' expr ')' {
            $return_type = $expr.return_type;
            $isLeftHand = $expr.isLeftHand;
        }
    ;

inline_array returns [int size, Type return_type]:
    '{' expr inline_array_member '}'
    {
        $size = $inline_array_member.size + 1;
        if($inline_array_member.return_type == null){
            $return_type = $expr.return_type;
        }
        else{
            $return_type = checkTypes($expr.return_type, $inline_array_member.return_type);
        }
    }
    ;

inline_array_member returns [int size, Type return_type]:
    (',' expr) secondMember = inline_array_member
    {
        $size = $secondMember.size + 1;
        if($secondMember.return_type == null){
            $return_type = $expr.return_type;
        }
        else{
            $return_type = checkTypes($expr.return_type, $secondMember.return_type);
        }
    }
    |
    {
        $size = 0;
        $return_type = null;
    }
    ;

CONST_NUM:
        [0-9]+
    ;

CONST_CHAR:
        '\'' . '\''
    ;

CONST_STR:
        '"' ~('\r' | '\n' | '"')* '"'
    ;

NL:
        '\r'? '\n' { setText("new_line"); }
    ;

ID:
        [a-zA-Z_][a-zA-Z0-9_]*
    ;

COMMENT:
        '#'(~[\r\n])* -> skip
    ;

WS:
        [ \t] -> skip
    ;