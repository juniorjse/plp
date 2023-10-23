:- module(util, [get_input/2, clear_screen/0]).

get_input(Prompt, Input) :- 
    writeln(Prompt),
    read_string(user_input, "\n", "\t ", _, Input).

clear_screen :- write('\e[2J\e[H\e[3J').

isANumber(Number,String):- number_string(Number, String).

splitItems(String, Items):- split_string(String, ",", " ", Items).

capitalize(String, Result):- string_upper(String, Result).

concatenate_with_comma(A,C):- atomic_list_concat(A,', ', C).

verify_cartegory([]).
verify_cartegory([X|XS]):- verify_cartegory(XS), number_string(Y, X), Y < 15, Y > 0.

strip(A,B):- split_string(A, "", "\s\t\n", [B]).

isANumber(Number, String) :-
    catch(
        atom_number(String, Number),
        _,
        fail
    ).
