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

    listarAlugueisPorPessoa :-
        writeln('Digite o ID do cliente para listar os registros de aluguéis:'),
        util:get_input('', ClienteIDStr),
        writeln(''),
    
        (util:isANumber(ClienteID, ClienteIDStr) ->
            connectiondb:iniciandoDatabase(Connection),
            (clienteExiste(Connection, ClienteID) ->
                user_operations:getAlugueisPorPessoa(Connection, ClienteID, Alugueis),
                (length(Alugueis, NumRegistros), NumRegistros > 0 ->
                    writeln('Registros de Aluguéis:'),
                    mostrarRegistrosDeAlugueis(Connection, Alugueis)
                ;
                    writeln('Não há registros de aluguéis para este cliente.')
                ),
                connectiondb:encerrandoDatabase(Connection)
            ;
                writeln('Cliente não encontrado na base de dados.')
            )
        ;
            writeln('ID de cliente inválido. Tente novamente.')
        ).
    
    mostrarRegistrosDeAlugueis(_, []).
    mostrarRegistrosDeAlugueis(Connection, [Registro | RegistrosRestantes]) :-
        mostrarRegistroDeAluguel(Connection, Registro),
        mostrarRegistrosDeAlugueis(Connection, RegistrosRestantes).
    
    mostrarRegistroDeAluguel(Connection, row(IDCarro, Marca, Modelo, Ano, DataInicio, DataDevolucao, Valor, Status)) :-
        writeln('|-------Carro-------|'),
        write('Marca:               '), writeln(Marca),
        write('Modelo:              '), writeln(Modelo),
        write('Ano:                 '), writeln(Ano),
        write('Data de Início:      '), writeln(DataInicio), 
        write('Data de Devolução:   '), writeln(DataDevolucao), 
        write('Valor do Aluguel: R$ '), writeln(Valor), 
        write('Status do Aluguel:   '), writeln(Status), 
        writeln('').
