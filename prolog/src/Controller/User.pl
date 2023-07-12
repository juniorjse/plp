:- module(usuarios, [solicitarCadastro/0, login/2, menu/0]).
:- use_module("./Util.pl").

menu :-
    writeln('Menu:'),
    writeln('1. Logar'),
    writeln('2. Cadastrar'),
    writeln('0. Sair'),
    writeln('Escolha uma opção:'),
    get_input("", Opcao),
    escolherOpcao(Opcao).

escolherOpcao("1") :-
    writeln('Digite o e-mail:'),
    read_string(user_input, "\n", "\r", _, Email),
    writeln('Digite a senha:'),
    read_string(user_input, "\n", "\r", _, Senha),
    login(Email, Senha).

escolherOpcao("2") :-
    solicitarCadastro.

escolherOpcao("0") :- writeln('Saindo...').

escolherOpcao(_) :-
    writeln('Opção inválida. Por favor, escolha novamente.'),
    menu.

solicitarCadastro :-
    writeln('Digite o nome:'),
    read_string(user_input, "\n", "\r", _, Nome),
    writeln('Digite o sobrenome:'),
    read_string(user_input, "\n", "\r", _, Sobrenome),
    writeln('Digite o e-mail:'),
    read_string(user_input, "\n", "\r", _, Email),
    writeln('Digite a senha (mínimo de 7 caracteres):'),
    read_string(user_input, "\n", "\r", _, Senha),
    (
        usuario(Email, _)
        -> writeln('Usuário com e-mail já cadastrado. Por favor, tente novamente.'),
           solicitarCadastro
        ;  (
               string_length(Senha, Len),
               Len >= 7
           )
           -> assertz(usuario(Email, Senha)),
              writeln('Cadastro realizado com sucesso.'),
              menu
           ;  writeln('A senha deve ter no mínimo 7 caracteres.'),
              solicitarCadastro
    ).

login(Email, Senha) :-
    usuario(Email, Senha),
    writeln('Bem-vindo!'),
    menu.

usuario(Email, Senha) :-
    

login(_, _) :-
    writeln('E-mail ou senha incorretos.'),
    menu.