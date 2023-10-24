:- module(locadora, [menuLocadora/0, opcaoMenu/1, cadastrarCarro/0, listarAlugueisPorPessoa/0, confirmaCadastro/1, removerCarro/0]).
:- use_module(library(odbc)).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').
:- use_module('./localdb/util').

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

    (Opcao = "1" -> cadastrarCarro;
    Opcao = "2" -> removerCarro;
    Opcao = "4" -> listarAlugueisPorPessoa;
    Opcao = "0" -> writeln('Saindo do sistema...'), halt; 
    otherwise -> writeln('Opção inválida. Tente novamente.')),
    menuLocadora.

    removerCarro:-
        get_connection(Connection),
        writeln('Informe o ID do carro que deseja remover:'),
        read_line_to_string(user_input, IdCarroString),
        (isANumber(IdCarro, IdCarroString) ->
            checkCarroStatus(Connection, IdCarro, Status),
            (Status = 'O' ->
                writeln('Este carro encontra-se alugado. Escolha outro ou retorne ao menu principal.');
                Status = 'D' ->
                    confirmarRemocao(Connection, IdCarro);
                Status = 'R' ->
                    writeln('Este carro está em reparo. Escolha outro ou retorne ao menu principal.');
                otherwise ->
                    writeln('Carro não encontrado.');
            );
            writeln('ID informado é inválido. Tente novamente.')
        ),
        encerrandoDatabase(Connection).
    
    confirmarRemocao(Connection, IdCarro):-
        writeln('Deseja realmente remover este carro? (s/n):'),
        read_line_to_string(user_input, Confirmacao),
        (Confirmacao = "s" ->
            removeCarro(Connection, IdCarro),
            writeln('Carro removido com sucesso.');
            Confirmacao = "n" ->
                writeln('Remoção cancelada.');
            otherwise ->
                writeln('Opção inválida. Tente novamente.')
        ).
    
    checkCarroStatus(Connection, IdCarro, Status):-
        getCarro(Connection, IdCarro, [_, _, _, _, _, _, Status|_]).
    
    removeCarro(Connection, IdCarro):-
        db_parameterized_query_no_return(
            Connection, 
            "DELETE FROM Carros WHERE id_carro = %w;",
            [IdCarro]
        ).
    
    :- initialization(menuLocadora).
