grammar AtalkPass2;

@members{
    Type checkTypes(Type firstType, Type secondType){
        if(firstType == null || secondType == null)
            return null;
        if(firstType instanceof NoType || secondType instanceof NoType){
            UI.printError("Assignment types don't match");
            return NoType.getInstance();
        }
        if(firstType.getClass().equals(secondType.getClass())){
            if(firstType.getClass().equals(ArrayType.class)){
                int lengthOne = ((ArrayType)firstType).getLength();
                int lengthTwo = ((ArrayType)secondType).getLength();
                if(lengthOne != lengthTwo){
                    UI.printError("Assignment types don't match");
                    return NoType.getInstance();
                }
                Type memberType = checkTypes(((ArrayType)firstType).getMemberType(), ((ArrayType)secondType).getMemberType());
                return new ArrayType(lengthOne, memberType);
            }
            return firstType;
        }
        else if(firstType.getClass().isAssignableFrom(secondType.getClass())){
            return firstType;
        }
        else if(secondType.getClass().isAssignableFrom(firstType.getClass())){
            return secondType;
        }
        else{
            UI.printError("Assignment types don't match");
            return NoType.getInstance();
        }
    }

    Type assignmentCheckTypes(Type Ltype, Type Rtype){
        if(Ltype == null || Rtype == null)
            return null;
        if(Ltype instanceof NoType || Rtype instanceof NoType){
            UI.printError("Assignment types don't match");
            return NoType.getInstance();
        }
        if(Ltype.getClass().equals(Rtype.getClass())){
            if(Ltype instanceof CharType || Ltype instanceof IntType){
                if(Ltype.getClass().isAssignableFrom(Rtype.getClass())){
                    return Ltype;
                }
            }
            else if(Ltype instanceof ArrayType){
                int lengthOne = ((ArrayType)Ltype).getLength();
                int lengthTwo = ((ArrayType)Rtype).getLength();
                if(lengthOne != lengthTwo){
                    UI.printError("Assignment types don't match");
                    return NoType.getInstance();
                }
                Type memberType = checkTypes(((ArrayType)Ltype).getMemberType(), ((ArrayType)Rtype).getMemberType());
                return new ArrayType(lengthOne, memberType);
            }
        }
        return NoType.getInstance();
    }

    void beginScope() {
        SymbolTable.push();
    }

    void endScope(boolean clear_stack) {
        int stack_size = SymbolTable.top.getOffset(Register.SP);
        UI.print("Stack offset: " + stack_size);
        if(clear_stack)
            mips.popStack((stack_size - SymbolTable.top.getOffset(Register.PSP)) / 4);
        SymbolTable.pop();
    }
    void endScope() {
        endScope(true);
    }

    Translator mips = new Translator();
}

program locals [ArrayList<String> actor_labels]:
        {
            UI.printHeader("Pass 2");
            $actor_labels = new ArrayList();
            beginScope();
        }
        (actor{
            $actor_labels.add($actor.actor_label);
        } | NL)*
        {
            endScope(false);
            mips.add_scheduler($actor_labels);
            mips.makeOutput();
        }
    ;

actor returns [String actor_label]:
    {beginScope();}
        'actor' actor_id=ID {
            $actor_label = $actor_id.text;
        } '<' mailbox_size=CONST_NUM '>' NL
            (state | receiver [$actor_id.text] | NL)*
        {
            int actor_offset =
                ((SymbolTableActorItem)SymbolTable.top.get(SymbolTableActorItem.getKey($actor_id.text)))
                .getOffset();
            mips.define_actor($actor_id.text, actor_offset);
            SymbolTableReceiverItem init_recv = ((SymbolTableReceiverItem)SymbolTable.top.get("recv__init__"));
            String receiver_label = $actor_id.text + "__" + "recv__init__";
            if(init_recv != null){
                mips.tell(actor_offset, receiver_label, Integer.parseInt($mailbox_size.text), 0, true);
            }
        }
        end_rule_without_clear_stack (NL | EOF)
    ;

state:
        type state_many[$type.return_type] (',' state_many[$type.return_type])* NL       
    ;

state_many [Type input_type] :
        ID {
            int offset =
                ((SymbolTableVariableItemBase)SymbolTable.top.get(SymbolTableVariableItemBase.getKey($ID.text)))
                .getOffset();
            mips.addGlobalVariable(offset,
                $input_type.size() / Type.WORD_BYTES);
        }
    ;

receiver [String container_actor] locals [boolean is_init, ArrayList<Variable> argVars]:
    {
        beginScope();
        $argVars = new ArrayList();
    }
        'receiver' rcvr_id=ID '(' (first_type=type first_arg_id=ID {
            int offset =
                ((SymbolTableVariableItemBase)SymbolTable.top.get(SymbolTableVariableItemBase.getKey($first_arg_id.text)))
                .getOffset();
            mips.addArgumentVariable(offset, $first_type.return_type.size() / Type.WORD_BYTES);
            $argVars.add(new Variable($first_arg_id.text, $first_type.return_type));
        } (',' second_type =  type second_arg_id=ID{
            offset =
                ((SymbolTableVariableItemBase)SymbolTable.top.get(SymbolTableVariableItemBase.getKey($second_arg_id.text)))
                .getOffset();
            mips.addArgumentVariable(offset, $second_type.return_type.size() / Type.WORD_BYTES);
            $argVars.add(new Variable($second_arg_id.text, $second_type.return_type));
        })*)? ')' NL
        {
            $is_init = ($rcvr_id.text.equals("init") && ($first_arg_id == null));
            Receiver tmpRcv = new Receiver($rcvr_id.text, $argVars);
            SymbolTableReceiverItem tmpRcvItem = new SymbolTableReceiverItem(tmpRcv);
            mips.define_receiver($container_actor + "__" + tmpRcvItem.getKey());
        }
            statements [container_actor, $is_init]
        end_rule NL
        {
            mips.jump(mips.scheduler_label);
        }
    ;

basetype returns [Type return_type]:
    'char' {$return_type = CharType.getInstance();}
    | 'int' {$return_type = IntType.getInstance();}
    ;

type returns [Type return_type]:
        basetype array_decl_dimensions [$basetype.return_type] {$return_type = $array_decl_dimensions.return_type;}
    ;

array_decl_dimensions [Type t] returns [Type return_type]:
    '[' CONST_NUM ']' {
        if($CONST_NUM.int == 0)
            UI.printError(String.format("[Line #%s] Array has 0 size.", $CONST_NUM.getLine()));
    }
    remainder=array_decl_dimensions[$t] {
        $return_type = new ArrayType($CONST_NUM.int, $remainder.return_type);
    }
    | {
        $return_type = $t;
    }
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

stm_vardef returns [Type return_type]:
    {SymbolTable.define();}
        type ID vardef_right_hand {
            int offset =
                ((SymbolTableVariableItemBase)SymbolTable.top.get(SymbolTableVariableItemBase.getKey($ID.text)))
                .getOffset();
            mips.addLocalVariable(offset,
                $type.return_type.size() / Type.WORD_BYTES, $vardef_right_hand.initialized);  
        } 
        vardef_many[$type.return_type] NL {
            Type local_type;
            if($vardef_many.return_type == null){
                local_type = $vardef_right_hand.return_type;
            }
            else {
                local_type = checkTypes($vardef_right_hand.return_type, $vardef_many.return_type);
            }
            Type mainType = assignmentCheckTypes($type.return_type, local_type);
            $return_type = mainType;
        }
    ;

vardef_right_hand returns [Type return_type, boolean initialized]:
        ('=' expr){
            $return_type = $expr.return_type;
            $initialized = true;
        }
        | {
            $return_type = null;
            $initialized = false;
        }
    ;

vardef_many [Type input_type] returns [Type return_type]:
        ',' ID vardef_right_hand {
            int offset =
                ((SymbolTableVariableItemBase)SymbolTable.top.get(SymbolTableVariableItemBase.getKey($ID.text)))
                .getOffset();
            mips.addLocalVariable(offset,
                $input_type.size() / Type.WORD_BYTES, $vardef_right_hand.initialized);  
        }
        secondVardef = vardef_many[$input_type] {
            if($secondVardef.return_type == null)
                $return_type = null;
            else{
                $return_type = checkTypes($vardef_many.return_type, $secondVardef.return_type);
            }
        }
        | {
            $return_type = null;
        }
    ;

stm_tell [String container_actor, boolean is_init] locals [ArrayList<Variable> argVars, int argsSize]:
        {$argVars = new ArrayList(); $argsSize = 0;}
        actr=(ID | 'sender' | 'self') '<<' rcvr=ID '(' (first_expr = expr{
            $argVars.add(new Variable("text", $first_expr.return_type));
            $argsSize += $first_expr.return_type.size();
        } (',' second_expr = expr {
            $argVars.add(new Variable("text", $second_expr.return_type));
            $argsSize += $second_expr.return_type.size();
        })*)? ')' NL
        {
            Receiver tmpRcv = new Receiver($rcvr.text, $argVars);
            SymbolTableReceiverItem tmpRcvItem = new SymbolTableReceiverItem(tmpRcv);
            String keys = tmpRcvItem.getKey();

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
                    // TODO: handle casting
                    SymbolTableActorItem actorItem = (SymbolTableActorItem) item;
                    int actor_adr = actorItem.getOffset();
                    int mailbox_size = actorItem.getMailboxSize();
                    String receiver_label = actor_name + SymbolTableItem.delimiter + keys;
                    mips.tell(actor_adr, receiver_label, mailbox_size, $argsSize / 4);
                }
            } else {
                if($is_init)
                    UI.printError(String.format(
                        "[Line #%s] Invalid keyword \"sender\" has been used in default receiver \"init()\".",
                        $actr.getLine()));
                // TODO: handle 'sender'
            }
        }
    ;

stm_write:
        'write' '(' expr ')' NL {
            if($expr.return_type instanceof ArrayType){
                if(!(((ArrayType)$expr.return_type).getMemberType() instanceof CharType)){
                    UI.printError("Can't write an array.");
                }
            }
            String type_str = "int";
            if($expr.return_type instanceof ArrayType){
                if(((ArrayType)$expr.return_type).getMemberType() instanceof CharType){
                    int size = ((ArrayType)$expr.return_type).getLength();
                    type_str = "char";
                    mips.write(type_str, size);
                }
            }
            else{
                if($expr.return_type instanceof CharType)
                    type_str = "char";
                mips.write(type_str);                
            }
        }
    ;

stm_if_elseif_else [String container_actor, boolean is_init]:
    {beginScope();}
        'if' {
            mips.addComment("start if");
            String label_end = mips.getLabel();
            String label_next = mips.getLabel();
        } expr NL {
            mips.check_if_expr(label_next);
        }
        statements [container_actor, is_init] {
            mips.jump(label_end);
        }
        (
            'elseif' {
                mips.addComment("elseif");
                mips.addLabel(label_next);
                label_next = mips.getLabel();
            } expr NL {
                mips.check_if_expr(label_next);
            }
            statements [container_actor, is_init] {
                mips.jump(label_end);
            }
        )*
        (
            'else' {
                mips.addComment("else");
                mips.addLabel(label_next);
                label_next = mips.getLabel();
            } NL statements [container_actor, is_init]
        )?
        {
            mips.addLabel(label_next);
            mips.addLabel(label_end);
            mips.addComment("end if");
        }
        end_rule NL
    ;

stm_foreach [String container_actor, boolean is_init]:  // TODO: support foreach
    {beginScope();}
        'foreach' ID 'in' expr NL {
            UI.printError(String.format("[Line #%s] Sorry. `foreach` is not supported.", $ID.getLine()));
            mips.addComment("Sorry. `foreach` is not supported.");
        }
            statements [container_actor, is_init]  // TODO: label_next should be pased to statements to handle break
        end_rule NL
    ;

stm_quit:
        'quit' {
            mips.quit();
        } NL
    ;

stm_break:  // TODO: support break
        'break' {
            // mips.jump(label_end);
        } NL
    ;

stm_assignment:
        expr NL {
            for(int i = 0; i < $expr.numberOfPops; i++)
                mips.popStack();
        }
    ;

end_rule:
    'end' {
        endScope();
    }
    ;

end_rule_without_clear_stack:
    'end' {
        endScope(false);
    }
    ;


expr returns [Type return_type, boolean isLeftHand, int numberOfPops]:
        expr_assign {
            $return_type = $expr_assign.return_type;
            $isLeftHand = $expr_assign.isLeftHand;
            $numberOfPops = $expr_assign.numberOfPops;
        }
    ;

expr_assign returns [Type return_type, boolean isLeftHand, int numberOfPops]:
        expr_or [true] '=' secondExpr = expr_assign {
            $isLeftHand = $expr_or.isLeftHand;
            if($expr_or.isLeftHand == true){
                $return_type = assignmentCheckTypes($expr_or.return_type, $secondExpr.return_type);
            }
            else{
                $return_type = NoType.getInstance();
                UI.printError("\"" + $expr_or.text + "\"" + " is not a Lvalue");
            }
            ArrayList<Integer> dimensionsList = new ArrayList();
            int size = 1;
            if($expr_or.return_type instanceof ArrayType)
                dimensionsList = ((ArrayType)$expr_or.return_type).getDimensionsSize();
            for(int i = 0; i < dimensionsList.size(); i++)
                size *= dimensionsList.get(i);
            $numberOfPops = size;
            mips.assignCommand(size);
        }
    |   expr_or [false] {
        $return_type = $expr_or.return_type;
        $isLeftHand = $expr_or.isLeftHand;
        $numberOfPops = 1;
    }
    ;

expr_or [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        expr_and [$nowIsLeft] expr_or_tmp {
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
        op='or' expr_and [false] secondExpr = expr_or_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_and.return_type;
            }
            else{
                $return_type = checkTypes($expr_and.return_type, $secondExpr.return_type);
            }
            mips.binaryOperationCommand($op.text);
        }
    | {
        $return_type = null;        
    }
    ;

expr_and [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        expr_eq [$nowIsLeft] expr_and_tmp {
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
        op='and' expr_eq [false] secondExpr = expr_and_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_eq.return_type;
            }
            else{
                $return_type = checkTypes($expr_eq.return_type, $secondExpr.return_type);                
            }
            mips.binaryOperationCommand($op.text);
        }
    | {
        $return_type = null;        
    }
    ;

expr_eq [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        expr_cmp [$nowIsLeft] expr_eq_tmp {
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
        op=('==' | '<>') expr_cmp [false] secondExpr = expr_eq_tmp {
            if($secondExpr.return_type == null){
                $return_type = IntType.getInstance();
            }
            else{
                $return_type = IntType.getInstance();
            }
            int size = 1;
            if($expr_cmp.return_type instanceof ArrayType){
                ArrayList<Integer> dimensionsList = ((ArrayType)$expr_cmp.return_type).getDimensionsSize();
                for(int i = 0; i < dimensionsList.size(); i++)
                    size *= dimensionsList.get(i);
            }
            mips.binaryOperationCommand($op.text, size);
        }
    | {
        $return_type = null;
    }
    ;

expr_cmp [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        expr_add [$nowIsLeft] expr_cmp_tmp {
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
        op=('<' | '>') expr_add [false] secondExpr = expr_cmp_tmp {
            if($secondExpr.return_type == null){
                $return_type = IntType.getInstance();
            }
            else{
                $return_type = IntType.getInstance();
            }
            mips.binaryOperationCommand($op.text);
        }
    | {
        $return_type = null;
    }
    ;

expr_add [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        expr_mult [$nowIsLeft] expr_add_tmp {
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
        op=('+' | '-') expr_mult [false] secondExpr = expr_add_tmp {
            if($secondExpr.return_type == null){
                $return_type = $expr_mult.return_type;
            }
            else{
                $return_type = checkTypes($expr_mult.return_type, $secondExpr.return_type);                
            }
            mips.binaryOperationCommand($op.text);
        }
    | {
        $return_type = null;
    }
    ;

expr_mult [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        expr_un [$nowIsLeft] expr_mult_tmp {
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
        op=('*' | '/') expr_un [false] secondExpr = expr_mult_tmp{
            if($secondExpr.return_type == null){
                $return_type = $expr_un.return_type;
            }
            else{
                $return_type = checkTypes($expr_un.return_type, $secondExpr.return_type);
            }
            mips.binaryOperationCommand($op.text);
        }
    | {
        $return_type = null;
    }
    ;

expr_un [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        op=('not' | '-') secondExpr = expr_un [false] {
            $return_type = $secondExpr.return_type;
            $isLeftHand = false;
            mips.unaryOperationCommand($op.text);
        }
    |   expr_mem [$nowIsLeft] {
            $return_type = $expr_mem.return_type;
            $isLeftHand = $expr_mem.isLeftHand;
        }
    ;

expr_mem [boolean nowIsLeft] returns [Type return_type, boolean isLeftHand]:
        expr_other {
            if($expr_other.isId == true && $expr_other.return_type instanceof ArrayType)
                mips.addToStack(0);
        } expr_mem_tmp [$expr_other.return_type] {
            $return_type = $expr_mem_tmp.return_type;
            $isLeftHand = $expr_other.isLeftHand;

            if($expr_other.isId == true){
                SymbolTableVariableItemBase var = (SymbolTableVariableItemBase) $expr_other.IDitem;
                Type thisType = var.getVariable().getType();
                if(thisType instanceof ArrayType){
                    if (var.getBaseRegister() == Register.SP)
                        mips.addAddressToStack($expr_other.IDText, var.getOffset());
                    else if (var.getBaseRegister() == Register.GP)
                        mips.addGlobalAddressToStack($expr_other.IDText, var.getOffset());
                    else if (var.getBaseRegister() == Register.AP)
                        mips.addArgumentAddressToStack($expr_other.IDText, var.getOffset());
                    else
                        UI.printError(String.format("Variable '%s' has invalid reference register.", $expr_other.IDText));
                    ArrayList<Integer> dimensionsList = ((ArrayType)thisType).getDimensionsSize();
                    int arrayOffset = 1;
                    for(int i = $expr_mem_tmp.levels; i < dimensionsList.size(); i++)
                        arrayOffset *= dimensionsList.get(i);
                    if (var.getBaseRegister() == Register.SP){
                        if ($nowIsLeft == false) mips.addArrayToStack(arrayOffset);
                        else mips.addArrayAddressToStack();
                    }
                    else if (var.getBaseRegister() == Register.GP){
                        if ($nowIsLeft == false) mips.addGlobalArrayToStack(arrayOffset);
                        else mips.addGlobalArrayAddressToStack();
                    }
                    else if (var.getBaseRegister() == Register.AP){
                        if ($nowIsLeft == false) mips.addArgumentArrayToStack(arrayOffset);
                        else mips.addArgumentArrayAddressToStack();
                    }
                }
                else {
                    if (var.getBaseRegister() == Register.SP){
                        if ($nowIsLeft == false) mips.addToStack($expr_other.IDText, var.getOffset());
                        else mips.addAddressToStack($expr_other.IDText, var.getOffset());
                    }
                    else if (var.getBaseRegister() == Register.GP){
                        if ($nowIsLeft == false) mips.addGlobalToStack($expr_other.IDText, var.getOffset());
                        else mips.addGlobalAddressToStack($expr_other.IDText, var.getOffset());
                    }
                    else if (var.getBaseRegister() == Register.AP){
                        if ($nowIsLeft == false) mips.addArgumentToStack($expr_other.IDText, var.getOffset());
                        else mips.addArgumentAddressToStack($expr_other.IDText, var.getOffset());
                    }
                    else
                        UI.printError(String.format("Variable '%s' has invalid reference register.", $expr_other.IDText));
                }
            }
        }
    ;

expr_mem_tmp [Type input_type] returns [Type return_type, int levels] locals [Type local_type, boolean failed]:
        '[' expr ']'{
            $failed = false;
            if($expr.return_type instanceof IntType){
                if($input_type instanceof ArrayType){
                    $local_type = ((ArrayType)($input_type)).getMemberType();
                }
                else{
                    $local_type = $input_type;
                    $failed = true;
                    $return_type = NoType.getInstance();
                    UI.printError("Can't access a non array type using \"[]\" operator");
                }
            }
            else{
                $return_type = NoType.getInstance();
                UI.printError("Can only access array members with int");
            }

            ArrayList<Integer> dimensions = ((ArrayType)$input_type).getDimensionsSize();
            int dimensionsMult = 1;
            for(int i = 0; i < dimensions.size(); i++)
                if(i != 0)
                    dimensionsMult *= dimensions.get(i);
            mips.arrayLengthCalculate(dimensionsMult, dimensions.get(0));
        }
        secondMemTmp = expr_mem_tmp [$local_type] 
        {
            if($failed == false){
                $return_type = $secondMemTmp.return_type;
            }
            $levels = $secondMemTmp.levels + 1;
        }
    | {
        $return_type = $input_type;

        $levels = 0;
    }
    ;

expr_other returns [Type return_type, boolean isLeftHand, boolean isId, SymbolTableItem IDitem, String IDText]:
        CONST_NUM {
            $return_type = IntType.getInstance();
            $isLeftHand = false;
            $isId = false;
            mips.addToStack(Integer.parseInt($CONST_NUM.text));
        }
    |   CONST_CHAR {
            $return_type = CharType.getInstance();
            $isLeftHand = false;
            $isId = false;
            mips.addToStack($CONST_CHAR.text.charAt(1));
        }
    |   CONST_STR {
            String str = $CONST_STR.text;
            str = str.substring(1, str.length()-1);
            $return_type = new ArrayType(str.length(), CharType.getInstance());
            $isLeftHand = false;
            $isId = false;
            for(int i = 0; i < str.length(); i++)
                mips.addToStack(str.charAt(i));
    }
    |   ID {
            $isId = true;
            $IDText = $ID.text;
            SymbolTableItem item = SymbolTable.top.get(SymbolTableVariableItemBase.getKey($ID.text));
            $IDitem = item;
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
            $isId = false;
        }
    |   'read' '(' CONST_NUM ')'{
            int len = Integer.parseInt($CONST_NUM.text);
            $return_type = new ArrayType(len, CharType.getInstance());
            $isLeftHand = false;               
            $isId = false;
            for(int i = 0; i < len ; i++)
                mips.read();
        }
    |   '(' expr ')' {
            $return_type = $expr.return_type;
            $isLeftHand = $expr.isLeftHand;
            $isId = false;
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
