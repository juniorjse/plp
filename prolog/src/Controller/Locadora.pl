:- module(Locadora, [menuLocadora/0]).
:- use_module(library(odbc)).
:- use_module(util).
:- use_module(dbop).

menuLocadora :-
    writeln(''),
    writeln('Menu:'),
    writeln('1. Cadastrar carro'),
    writeln('2. Remover Carro'),
    writeln('3. Registrar Devolução'),
    writeln('4. Registro de Aluguéis por pessoa'),
    writeln('5. Dashboard'),
    writeln('0. Sair'),
    writeln('Escolha uma opção:'),

    read_line_to_string(user_input, Opcao),
    (Opcao = "1" -> cadastrarCarro, menuLocadora;
     Opcao = "2" -> removerCarro, menuLocadora;
     Opcao = "3" -> registrarDevolucao, menuLocadora;
     Opcao = "4" -> registroDeAluguelPorPessoa, menuLocadora;
     Opcao = "5" -> dashboard, menuLocadora;
     Opcao = "0" -> halt;
     writeln('Opção inválida. Por favor, escolha novamente.'), menuLocadora).

