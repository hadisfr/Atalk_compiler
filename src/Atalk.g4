grammar Atalk;

@members{

    void printError(String str){
        System.out.println("Error: " + str + "\n");
    }

    void print(String str){
        System.out.println(str);
    }

    void putLocalVar(String name, Type type) throws ItemAlreadyExistsException {
        SymbolTable.top.put(
            new SymbolTableLocalVariableItem(
                new Variable(name, type),
                SymbolTable.top.getOffset(Register.SP)
            )
        );
    }

    void beginScope() {
    	int offset = 0;
    	if(SymbolTable.top != null)
        	offset = SymbolTable.top.getOffset(Register.SP);
        SymbolTable.push(new SymbolTable());
        SymbolTable.top.setOffset(Register.SP, offset);
    }

    void endScope() {
        print("Stack offset: " + SymbolTable.top.getOffset(Register.SP));
        SymbolTable.pop();
    }
}

program locals [boolean hasActor]:
		(actor [false] {$hasActor = true;} | NL)*
		{
		    if($hasActor == false)
		        printError("No actors found");
		}
	;

actor [boolean isInLoop]:
		'actor' ID '<' CONST_NUM '>' NL {
		    if($CONST_NUM.int)
        	    printError("Actor  zero");
		}
			(state | receiver [$isInLoop] | NL)*
		'end' (NL | EOF)
	;

state:
		type ID (',' ID)* NL
	;

receiver [boolean isInLoop]:
		'receiver' ID '(' (type ID (',' type ID)*)? ')' NL
			statements [$isInLoop]
		'end' NL
	;

basetype returns [Type return_type]
    :
    'char' {$return_type = CharType.getInstance();}
    | 'int' {$return_type = IntType.getInstance();}
    ;

type:
		basetype array_decl_dimensions [$basetype.return_type]
	;

array_decl_dimensions [Type t] returns [Type return_type]:
	'[' CONST_NUM ']' {
	    if($CONST_NUM.int)
	        printError("Array size zero");
	}
	remainder=array_decl_dimensions[$t] {
        $return_type = new ArrayType($CONST_NUM.int, $remainder.return_type);
	}
	| {
	    $return_type = $t;
	}
	;


block [boolean isInLoop]:
		'begin' NL
			statements [$isInLoop]
		'end' NL
	;

statements [boolean isInLoop]:
		(statement [$isInLoop] | NL)*
	;

statement [boolean isInLoop]:
		stm_vardef
	|	stm_assignment
	|	stm_foreach
	|	stm_if_elseif_else [$isInLoop]
	|	stm_quit
	|	stm_break [$isInLoop]
	|	stm_tell
	|	stm_write
	|	block [$isInLoop]
	;

stm_vardef:
		type ID ('=' expr)? (',' ID ('=' expr)?)* NL
	;

stm_tell:
		(ID | 'sender' | 'self') '<<' ID '(' (expr (',' expr)*)? ')' NL
	;

stm_write:
		'write' '(' expr ')' NL
	;

stm_if_elseif_else [boolean isInLoop]:
		'if' expr NL statements [$isInLoop]
		('elseif' expr NL statements [$isInLoop])*
		('else' NL statements [$isInLoop])?
		'end' NL
	;

stm_foreach:
		'foreach' ID 'in' expr NL
			statements [true]
		'end' NL
	;

stm_quit:
		'quit' NL
	;

stm_break [boolean isInLoop]:
		'break' NL {
		    if($isInLoop == false)
		        printError("Break outside loop");
		}
	;

stm_assignment:
		expr NL
	;

expr:
		expr_assign
	;

expr_assign:
		expr_or '=' expr_assign
	|	expr_or
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
	|	expr_mem
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
	|	CONST_CHAR
	|	CONST_STR
	|	ID
	|	'{' expr (',' expr)* '}'
	|	'read' '(' CONST_NUM ')'
	|	'(' expr ')'
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