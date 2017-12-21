grammar AtalkPass1;

@header {
    import java.util.*;
}

@members {

    final int RANDOM_NAME_LEN = 5;
    boolean hasError = false;
    boolean beautify = true;

    void putLocalVar(String name, Type type) throws ItemAlreadyExistsException {
        SymbolTableLocalVariableItem item =
            new SymbolTableLocalVariableItem(
                new Variable(name, type),
                SymbolTable.top.getOffset(Register.SP)
            );
        UI.printDetail(UI.OutputCategory.LocalVar, name + "\t" + type + "\t" + "Offset:"
         + ((SymbolTableVariableItemBase)item).getOffset()
         + "\tSize:"
         + ((SymbolTableVariableItemBase)item).getSize());
        SymbolTable.top.put(item);
    }

    void putGlobalVar(String name, Type type) throws ItemAlreadyExistsException {
        SymbolTableGlobalVariableItem item =
            new SymbolTableGlobalVariableItem(
                new Variable(name, type),
                SymbolTable.top.getOffset(Register.GP)
            );
        UI.printDetail(UI.OutputCategory.GlobalVar, name + "\t" + type + "\t" + "Offset:"
         + ((SymbolTableVariableItemBase)item).getOffset()
         + "\tSize:"
         + ((SymbolTableVariableItemBase)item).getSize());
        SymbolTable.top.put(item);
    }

    void putArgumentVar(String name, Type type) throws ItemAlreadyExistsException {
        SymbolTableArgumentVariableItem item =
            new SymbolTableArgumentVariableItem(
                new Variable(name, type),
                SymbolTable.top.getOffset(Register.TEMP9)
            );
        UI.printDetail(UI.OutputCategory.ArgumentVar, name + "\t" + type + "\t" + "Offset:"
        + ((SymbolTableVariableItemBase)item).getOffset()
        + "\tSize:"
        + ((SymbolTableVariableItemBase)item).getSize());
        SymbolTable.top.put(item);
    }

    void putActor(String name, int mailboxSize) throws ItemAlreadyExistsException{
        SymbolTable.top.put(
            new SymbolTableActorItem(
                new Actor(name, mailboxSize)
            )
        );
    }

    void putReceiver(String name, ArrayList<Variable> args) throws ItemAlreadyExistsException{
        SymbolTableReceiverItem receiverItem = new SymbolTableReceiverItem(
            new Receiver(name, args)
        );
        UI.printDetail(UI.OutputCategory.Receiver, receiverItem.getKey().replace(SymbolTableItem.delimiter, " "));
        SymbolTable.top.put(receiverItem);
    }

    void beginScope() {
        int offset = 0;
        if(SymbolTable.top != null)
            offset = SymbolTable.top.getOffset(Register.SP);
        SymbolTable.push(new SymbolTable(SymbolTable.top));
        SymbolTable.top.setOffset(Register.SP, offset);
    }

    void endScope() {
        UI.print("Stack offset: " + SymbolTable.top.getOffset(Register.SP));
        SymbolTable.pop();
    }

}

program locals [boolean hasActor]:
        {UI.printHeader("Pass 1");}
        (actor [false] {$hasActor = true;} | NL)*
        {
            if($hasActor == false)
                UI.printError("No actors found");
        }
    ;

actor [boolean isInLoop]:
        {beginScope();}
        'actor' ID '<' CONST_NUM '>' NL {
            UI.printDetail(UI.OutputCategory.Actor, $ID.text + " <" + $CONST_NUM.int + ">");
            if($CONST_NUM.int == 0)
                UI.printError(String.format("[Line #%s] Actor \"%s\" has 0 mailboxSize.", $ID.getLine(), $ID.text));
            try {
                putActor($ID.text, $CONST_NUM.int);
            }
            catch(ItemAlreadyExistsException e) {
                UI.printError(String.format("[Line #%s] Actor \"%s\" already exists.", $ID.getLine(), $ID.text));
                while(true) {
                    try {putActor(RandomStringGen.generate(RANDOM_NAME_LEN), $CONST_NUM.int); break;}
                    catch(ItemAlreadyExistsException eprim) {}
                }
            }
        }
            (state [UI.VariableScopeState.GLOBAL] | receiver [$isInLoop] | NL)*
        end_rule (NL | EOF)
    ;

state [UI.VariableScopeState scopeState]:
        type id_def[$type.return_type, $scopeState] (',' id_def[$type.return_type, $scopeState])* NL
    ;

id_def [Type typee, UI.VariableScopeState scopeState] returns [String name]
    :
    ID {
        $name = $ID.text;
        if($scopeState == UI.VariableScopeState.LOCAL) {
            try {
                putLocalVar($name, $typee);
            }
            catch(ItemAlreadyExistsException e) {
                UI.printError(String.format("[Line #%s] Variable \"%s\" already exists.", $ID.getLine(), $name));
                while(true) {
                    try {putLocalVar(RandomStringGen.generate(RANDOM_NAME_LEN), $typee); break;}
                    catch(ItemAlreadyExistsException eprim) {}
                }
            }
        } else if($scopeState == UI.VariableScopeState.GLOBAL) {
            try {
                putGlobalVar($name, $typee);
            }
            catch(ItemAlreadyExistsException e) {
                UI.printError(String.format("[Line #%s] Variable \"%s\" already exists.", $ID.getLine(), $name));
                while(true) {
                    try {putGlobalVar(RandomStringGen.generate(RANDOM_NAME_LEN), $typee); break;}
                    catch(ItemAlreadyExistsException eprim) {}
                }
            }
        } else if($scopeState == UI.VariableScopeState.ARG) {
            try {
                putArgumentVar($name, $typee);
            }
            catch(ItemAlreadyExistsException e) {
                UI.printError(String.format("[Line #%s] Variable \"%s\" already exists.", $ID.getLine(), $name));
                while(true) {
                    try {putArgumentVar(RandomStringGen.generate(RANDOM_NAME_LEN), $typee); break;}
                    catch(ItemAlreadyExistsException eprim) {}
                }
            }
        } else
            UI.printError(String.format("[Line #%s] Invalid UI.VariableScopeState", $ID.getLine()));
    }
    ;

receiver [boolean isInLoop]:
        {beginScope();}
        'receiver' ID '(' args ')' NL 
        {
            try {
                putReceiver($ID.text, $args.vars);
            }
            catch(ItemAlreadyExistsException e) {
                UI.printError(String.format("[Line #%s] Receiver \"%s\" already exists.", $ID.getLine(), $ID.text));
                while(true) {
                    try {putReceiver(RandomStringGen.generate(RANDOM_NAME_LEN), $args.vars); break;}
                    catch(ItemAlreadyExistsException eprim) {}
                }
            }
        }
            statements [$isInLoop]
        end_rule
        NL
    ;

args returns [ArrayList<Variable> vars]:
    arg_type_id more_args {
        $vars = $more_args.vars;
        $vars.add(0, $arg_type_id.var);
    }
    | {$vars = new ArrayList<Variable>();}
    ;

more_args returns [ArrayList<Variable> vars]:
    ',' arg_type_id others=more_args {
        $vars = $others.vars;
        $vars.add(0, $arg_type_id.var);
    }
    | {$vars = new ArrayList<Variable>();}
    ;

arg_type_id returns [Variable var]:
    type id_def[$type.return_type, UI.VariableScopeState.ARG] {$var = new Variable($id_def.name, $type.return_type);}
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

block [boolean isInLoop]:
        {beginScope();}
        'begin' NL
            statements [$isInLoop]
        end_rule NL
    ;

statements [boolean isInLoop]:
        (statement [$isInLoop] | NL)*
    ;

statement [boolean isInLoop]:
        stm_vardef
    |    stm_assignment
    |    stm_foreach
    |    stm_if_elseif_else [$isInLoop]
    |    stm_quit
    |    stm_break [$isInLoop]
    |    stm_tell
    |    stm_write
    |    block [$isInLoop]
    ;

stm_vardef:
        type id_def[$type.return_type, UI.VariableScopeState.LOCAL] ('=' expr)? (',' id_def[$type.return_type, UI.VariableScopeState.LOCAL] ('=' expr)?)* NL
    ;

stm_tell:
        (ID | 'sender' | 'self') '<<' ID '(' (expr (',' expr)*)? ')' NL
    ;

stm_write:
        'write' '(' expr ')' NL
    ;

stm_if_elseif_else [boolean isInLoop]:
        {beginScope();}
        'if' expr NL statements [$isInLoop]
        ('elseif' expr NL statements [$isInLoop])*
        ('else' NL statements [$isInLoop])?
        end_rule NL
    ;

stm_foreach:
        {beginScope();}
        'foreach' ID 'in' expr NL
        /*'foreach' firstID=ID 'in' secondID=ID NL
        {
            SymbolTableItem array = SymbolTable.top.get(SymbolTableVariableItemBase.getKey($secondID.text));
            Type iteratorType;
            if(array instanceof SymbolTableVariableItemBase){
                Variable arrayVariable = ((SymbolTableVariableItemBase)array).getVariable();
                if((arrayVariable).getType() instanceof ArrayType){
                    iteratorType = ((ArrayType)(arrayVariable.getType())).getMemberType();    
                }
                else{
                    UI.printError(String.format("[Line #%s] Id \"%s\" should be an array.", $secondID.getLine(), $secondID.text));
                    iteratorType = arrayVariable.getType();
                }
                try {
                    putLocalVar($firstID.text, iteratorType);
                }
                catch(ItemAlreadyExistsException e) {
                    UI.printError(String.format("[Line #%s] Variable \"%s\" already exists.", $firstID.getLine(), $firstID.text));
                    while(true) {
                        try {putLocalVar(RandomStringGen.generate(RANDOM_NAME_LEN), iteratorType); break;}
                        catch(ItemAlreadyExistsException eprim) {}
                    }
                }
            } else {
                // not in SymbolTable
            }
        }*/
            statements [true]
        end_rule NL
    ;

stm_quit:
        'quit' NL
    ;

stm_break [boolean isInLoop]:
        'break' NL {
            if($isInLoop == false)
                UI.printError(String.format("[Line #%s] Invalid UI.VariableScopeState", $NL.getLine()));
        }
    ;

stm_assignment:
        expr NL
    ;

end_rule:
    'end' {
        endScope();
    }
    ;

expr:
        expr_assign
    ;

expr_assign:
        expr_or '=' expr_assign
    |    expr_or
    ;

expr_or:
        expr_and expr_or_tmp
    ;

expr_or_tmp:
        'or' expr_and expr_or_tmp
    |
    ;

expr_and:
        expr_eq expr_and_tmp
    ;

expr_and_tmp:
        'and' expr_eq expr_and_tmp
    |
    ;

expr_eq:
        expr_cmp expr_eq_tmp
    ;

expr_eq_tmp:
        ('==' | '<>') expr_cmp expr_eq_tmp
    |
    ;

expr_cmp:
        expr_add expr_cmp_tmp
    ;

expr_cmp_tmp:
        ('<' | '>') expr_add expr_cmp_tmp
    |
    ;

expr_add:
        expr_mult expr_add_tmp
    ;

expr_add_tmp:
        ('+' | '-') expr_mult expr_add_tmp
    |
    ;

expr_mult:
        expr_un expr_mult_tmp
    ;

expr_mult_tmp:
        ('*' | '/') expr_un expr_mult_tmp
    |
    ;

expr_un:
        ('not' | '-') expr_un
    |    expr_mem
    ;

expr_mem:
        expr_other expr_mem_tmp
    ;

expr_mem_tmp:
        '[' expr ']' expr_mem_tmp
    |
    ;

expr_other:
        CONST_NUM
    |    CONST_CHAR
    |    CONST_STR
    |    ID
    |    inline_array
    |    'read' '(' CONST_NUM ')'
    |    '(' expr ')'
    ;

inline_array returns [int size, Type return_type]:
    '{' expr inline_array_member '}'
    ;

inline_array_member returns [int size]:
    (',' expr) secondMember = inline_array_member
    |
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