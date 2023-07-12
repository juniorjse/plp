:- module(Util, [get_input/2]).

get_input(Prompt, Input) :- 
    writeln(Prompt),
    read_string(user_input, "\n", "\t ", _, Input).