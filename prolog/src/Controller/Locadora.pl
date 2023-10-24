:- module(Locadora, [menuLocadora/0,registrarDevolucao/0, printAluguel/4]).
:- use_module(library(odbc)).
:- use_module(util).
:- use_module(dbop).
:- use_module('./localdb/connectiondb').
:- use_module(library(date_time)).

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
     Opcao = "3" -> registrarDevolucao;
     Opcao = "4" -> registroDeAluguelPorPessoa, menuLocadora;
     Opcao = "5" -> dashboard, menuLocadora;
     Opcao = "0" -> true;
     writeln('Opção inválida. Por favor, escolha novamente.'), menuLocadora).

registrarDevolucao :-
    writeln('Digite o número do contrato/Id do aluguel a ser encerrado:'),
    read_line_to_string(user_input, InputString),
    atom_number(InputString, NumContrato),
    Contrato = [row(DataInicio, DataDevolucao, IDCarro, ValorTotal)],
    buscarAluguel(NumContrato, Contrato),
    (length(Contrato, 0) ->
        writeln('Aluguel não encontrado.'),
        writeln('1. Para digitar novamente'),
        writeln('2. Para voltar ao menu inicial'),
        read_line_to_string(user_input, Opcao),
        (Opcao = "1" -> registrarDevolucao;
        Opcao = "2" -> menuLocadora;
        writeln('Opção inválida. Você será direcionado(a) ao menu inicial.'), menuLocadora);

        printAluguel( DataInicio, DataDevolucao, IDCarro),
        verificaDevolucao(DataDevolucao, Devolucao),
        (Devolucao = "Devolução dentro do prazo" ->
            printDevolucao(ValorTotal, IDCarro);
        Devolucao = "Devolução adiantada" ->
            writeln('Motivo da devolução adiantada:'),
            writeln('1. Problema no carro'),
            writeln('2. Outro motivo'),
            read_line_to_string(user_input, Motivo),
            (Motivo = "1" -> enviaParaMecanico(IDCarro), menuLocadora;
             Motivo = "2" -> calculaValor( DataInicio, DataDevolucao, IDCarro, Valor), 
             printDevolucao(Valor, IDCarro), menuLocadora;
             writeln('Opção inválida. Você será direcionado(a) ao menu inicial.'), menuLocadora);
        writeln("---Devolução Atrasada---"),
        calculaValor(DataInicio, DataDevolucao, IDCarro, Valor), 
            printDevolucao(Valor, IDCarro), menuLocadora
        )
    ).

buscarAluguel(NumContrato, Contrato) :-
    connectiondb:iniciandoDatabase(Connection),
    dbop:db_parameterized_query(Connection, "SELECT data_inicio, data_devolucao, id_carro, valor_total FROM Alugueis WHERE id_aluguel = '%w'", [NumContrato], Contrato),
    connectiondb:encerrandoDatabase(Connection).

buscarCarro(IDCarro) :-
    connectiondb:iniciandoDatabase(Connection),
    format("Detalhes do aluguel com ID ~w: \n", [IDCarro]),
    Resultado = [row(Marca,Modelo,Ano)],
    dbop:db_parameterized_query(Connection, "SELECT marca, modelo, ano FROM Carros WHERE id_carro = '%w'", [IDCarro], Resultado),
    connectiondb:encerrandoDatabase(Connection),
    (
        Resultado = null ->
        writeln("Carro com ID " + IDCarro + " não encontrado.");  
        writeln("Detalhes do carro:"),
        writeln("Marca:" + Marca),
        writeln("Modelo: " + Modelo),
        writeln("Ano: " + Ano)
    ).

printAluguel(DataInicio, DataDevolucao, IDCarro) :-
    writeln("Carro Alugado: "),
    buscarCarro(IDCarro),
    calculaValor(DataInicio, DataDevolucao, IDCarro, Valor),
    writeln("Data de início do aluguel: " + DataInicio),
    writeln("Data de devolução: " + DataDevolucao),
    writeln("Valor total do aluguel: R$ " + Valor).

calculaValor(DataInicio, DataDevolucao, IDCarro, Valor) :-
    date_get(today, DataAtual),
    date_interval(DataInicio, DataAtual, QtdDiasAlugados days),
    retornaDiaria(IDCarro, Diaria),
    Valor is -1 * QtdDiasAlugados * Diaria.

retornaDiaria(IDCarro, Diaria) :- 
    connectiondb:iniciandoDatabase(Connection),
    dbop:db_parameterized_query(Connection, "SELECT diaria_carro FROM Carros WHERE id_carro = '%w'", [IDCarro], [row(Diaria)]),
    connectiondb:encerrandoDatabase(Connection).

verificaDevolucao(DataDevolucao, Resultado) :-
    date_get(today, CurrentDay),
    date_interval(CurrentDay, DataDevolucao, QtdDias days),
    (
        QtdDias == 0 ->
        Resultado = "Devolução dentro do prazo";
        QtdDias < 0 ->
        Resultado = "Devolução adiantada";
        Resultado = "Devolução atrasada"
    ).

printDevolucao(Valor, IDCarro) :-
    writeln("Realizar pagamento do aluguel! Valor total:"),
    writeln("R$ " + Valor),
    writeln("1. Confirmar pagamento"),
    writeln("2. Cancelar"),
    read_line_to_string(user_input, ConfirmaPagamento),
    processarPagamento(ConfirmaPagamento, IDCarro, Valor).

processarPagamento("1", IDCarro, ValorTotal) :- 
    connectiondb:iniciandoDatabase(Connection),
    writeln("Pagamento realizado com sucesso!"), 
    writeln("Aluguel finalizado."),
    dbop:db_parameterized_query_no_return(Connection, "UPDATE Alugueis SET status_aluguel = 'Concluído' WHERE id_carro = %w AND status_aluguel = 'ativo'", [IDCarro]),
    dbop:db_parameterized_query_no_return(Connection, "UPDATE Carros SET status = 'D' WHERE id_carro = %w", [IDCarro]),
    dbop:db_parameterized_query_no_return(Connection, "UPDATE Alugueis SET valor_total = %w WHERE id_carro = %w", [ValorTotal, IDCarro]),
    connectiondb:encerrandoDatabase(Connection),
    menuLocadora.
processarPagamento("2", _) :- 
    writeln("Operação cancelada!"), menuLocadora.
processarPagamento(_, _) :- 
    writeln("Opção inválida. Você será direcionado(a) ao menu inicial."), menuLocadora.

enviaParaMecanico(IDCarro) :-
    connectiondb:iniciandoDatabase(Connection),
    db_parameterized_query_no_return(Connection,  "UPDATE Carros SET status = 'R' WHERE id_carro = '%w'", [ID_Carro]),
    connectiondb:encerrandoDatabase(Connection).
