grammar AtalkPass2;

program:
        (actor | NL)*
    ;

actor:
        'actor' ID '<' CONST_NUM '>' NL
            (state | receiver | NL)*
        'end' (NL | EOF)
    ;

state:
        type ID (',' ID)* NL
    ;

receiver:
        'receiver' ID '(' (type ID (',' type ID)*)? ')' NL
            statements
        'end' NL
    ;

type:
        'char' ('[' CONST_NUM ']')*
    |   'int' ('[' CONST_NUM ']')*
    ;

block:
        'begin' NL
            statements
        'end' NL
    ;

statements:
        (statement | NL)*
    ;

statement:
        stm_vardef
    |   stm_assignment
    |   stm_foreach
    |   stm_if_elseif_else
    |   stm_quit
    |   stm_break
    |   stm_tell
    |   stm_write
    |   block
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

stm_if_elseif_else:
        'if' expr NL statements
        ('elseif' expr NL statements)*
        ('else' NL statements)?
        'end' NL
    ;

stm_foreach:
        'foreach' ID 'in' expr NL
            statements
        'end' NL
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

expr returns [Type return_type]:
        expr_assign
    ;

expr_assign returns [Type return_type]:
        expr_or '=' expr_assign
    |   expr_or
    ;

expr_or returns [Type return_type]:
        expr_and expr_or_tmp
    ;

expr_or_tmp returns [Type return_type]:
        'or' expr_and expr_or_tmp
    |
    ;

expr_and returns [Type return_type]:
        expr_eq expr_and_tmp
    ;

expr_and_tmp returns [Type return_type]:
        'and' expr_eq expr_and_tmp
    |
    ;

expr_eq returns [Type return_type]:
        expr_cmp expr_eq_tmp
    ;

expr_eq_tmp returns [Type return_type]:
        ('==' | '<>') expr_cmp expr_eq_tmp
    |
    ;

expr_cmp returns [Type return_type]:
        expr_add expr_cmp_tmp
    ;

expr_cmp_tmp returns [Type return_type]:
        ('<' | '>') expr_add expr_cmp_tmp
    |
    ;

expr_add returns [Type return_type]:
        expr_mult expr_add_tmp
    ;

expr_add_tmp returns [Type return_type]:
        ('+' | '-') expr_mult expr_add_tmp
    |
    ;

expr_mult returns [Type return_type]:
        expr_un expr_mult_tmp
    ;

expr_mult_tmp returns [Type return_type]:
        ('*' | '/') expr_un expr_mult_tmp
    |
    ;

expr_un returns [Type return_type]:
        ('not' | '-') expr_un
    |   expr_mem
    ;

expr_mem returns [Type return_type]:
        expr_other expr_mem_tmp
    ;

expr_mem_tmp returns [Type return_type]:
        '[' expr ']' expr_mem_tmp
    |
    ;

expr_other returns [Type return_type]:
        CONST_NUM {
            $return_type = IntType.getInstance();
        }
    |   CONST_CHAR{
            $return_type = CharType.getInstance();
        }
    |   CONST_STR
    |   ID
    |   inline_array
    {
        //return_type = new Array;
    }
    |   'read' '(' CONST_NUM ')'
    |   '(' expr ')'
    ;

inline_array returns [int size, Type return_type]:
    '{' expr inline_array_member '}'
    {
        $size = $inline_array_member.size;
        $return_type = $expr.return_type;//TODO: set return type for inline_array
    }
    ;

inline_array_member returns [int size]:
    (',' expr) secondMember = inline_array_member
    {
        $size = $secondMember.size + 1;
    }
    |
    {
        $size = 0;
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