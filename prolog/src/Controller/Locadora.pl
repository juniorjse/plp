:- module(Locadora, [menuLocadora/0]).
:- use_module(library(odbc)).
:- use_module(util).
:- use_module(dbop).
:- use_module('./localdb/connectiondb').

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

registraDevolucao(Connection) :-
    writeln('Digite o número do contrato/Id do aluguel a ser encerrado:'),
    read_line_to_string(user_input, InputString),
    atom_number(InputString, NumContrato),
    buscarAluguel(Connection, NumContrato, Contrato),
    (length(Contrato, 0) ->
        writeln('Aluguel não encontrado.'),
        writeln('1. Para digitar novamente'),
        writeln('2. Para voltar ao menu inicial'),
        read_line_to_string(user_input, Opcao),
        (Opcao = "1" -> registraDevolucao(Connection);
        Opcao = "2" -> menuLocadora(Connection);
        writeln('Opção inválida. Você será direcionado(a) ao menu inicial.'), menuLocadora(Connection)));
    [Aluguel] = Contrato,
    ( Aluguel = (DataInicio, DataDevolucao, IDCarro, ValorTotal) ->
        printAluguel(Connection, DataInicio, DataDevolucao, IDCarro, ValorTotal),
        verificaDevolucao(DataDevolucao, Devolucao),
        ( Devolucao = "Devolução dentro do prazo" ->
            printDevolucao(Connection, ValorTotal, IDCarro);
            Devolucao = "Devolução adiantada" ->
            writeln('Motivo da devolução adiantada:'),
            writeln('1. Problema no carro'),
            writeln('2. Outro motivo'),
            read_line_to_string(user_input, Motivo),
            (Motivo = "1" -> enviaParaMecanico(Connection, IDCarro), menuLocadora(Connection);
             Motivo = "2" -> calculaValor(Connection, DataInicio, DataDevolucao, ValorTotal, IDCarro, Valor), 
             printDevolucao(Connection, Valor, IDCarro), menuLocadora(Connection);
             writeln('Opção inválida. Você será direcionado(a) ao menu inicial.'), menuLocadora(Connection));
            calculaValor(Connection, DataInicio, DataDevolucao, ValorTotal, IDCarro, Valor), 
            printDevolucao(Connection, Valor, IDCarro), menuLocadora(Connection)
        )
    ).

buscarAluguel(NumContrato, Contrato) :-
    connectiondb:iniciandoDatabase(Connection),
    dbop:db_parameterized_query(Connection, "SELECT data_inicio, data_devolucao, id_carro, valor_total FROM Alugueis WHERE id_aluguel = '%w'", [NumContrato], Contrato),
    connectiondb:encerrandoDatabase(Connection).

buscarCarro(IDCarro) :-
    connectiondb:iniciandoDatabase(Connection),
    writeln("Detalhes do aluguel com ID " + IDCarro + ": "),
    dbop:db_parameterized_query(Connection, "SELECT marca, modelo, ano FROM Carros WHERE id_carro = '%w'", [IDCarro], Resultado),
    connectiondb:encerrandoDatabase(Connection),
    (
        Resultado = null ->
        writeln("Carro com ID " + IDCarro + " não encontrado.");  
        writeln("Detalhes do carro:"),
        writeln("Marca: " + Resultado.marca),
        writeln("Modelo: " + Resultado.modelo),
        writeln("Ano: " + Resultado.ano)
    ).

printAluguel(DataInicio, DataDevolucao, IDCarro, ValorTotal) :-
    writeln("Carro Alugado: "),
    buscarCarro(IDCarro),
    calculaValor(DataInicio, DataDevolucao, IDCarro, ValorTotal, Valor),
    writeln("Data de início do aluguel: " + DataInicio),
    writeln("Data de devolução: " + DataDevolucao),
    writeln("Valor total do aluguel: R$ " + Valor).

calculaValor(DataInicio, DataDevolucao, IDCarro, ValorTotal, Valor) :-
    getCurrentTime(CurrentTime),
    utctDay(CurrentTime, DataAtual),
    diffDays(DataInicio, DataAtual, QtdDiasAlugados),
    retornaDiaria(IDCarro, Diaria),
    Valor is -1 * QtdDiasAlugados * Diaria.

retornaDiaria(IDCarro, Diaria) :- 
    connectiondb:iniciandoDatabase(Connection),
    dbop:db_parameterized_query(Connection, "SELECT diaria_carro FROM Carros WHERE id_carro = '%w'", [IDCarro], Diaria),
    connectiondb:encerrandoDatabase(Connection).

verificaDevolucao(DataDevolucao, Resultado) :-
    getCurrentTime(CurrentTime),
    utctDay(CurrentTime, CurrentDay),
    (
        DataDevolucao == CurrentDay ->
        Resultado = "Devolução dentro do prazo";
        DataDevolucao > CurrentDay ->
        Resultado = "Devolução adiantada";
        Resultado = "Devolução atrasada"
    ).

printDevolucao(Valor, IDCarro) :-
    writeln("Realizar pagamento do aluguel! Valor total:"),
    writeln("R$ " + Valor),
    writeln("1. Confirmar pagamento"),
    writeln("2. Cancelar"),
    read_line_to_string(user_input, ConfirmaPagamento),
    processarPagamento(ConfirmaPagamento, Valor, IDCarro).

processarPagamento(_, _, _) :- 
    writeln("Opção inválida. Você será direcionado(a) ao menu inicial."), menuLocadora.
processarPagamento("1", Valor, IDCarro) :- 
    writeln("Pagamento realizado com sucesso!"), 
    writeln("Aluguel finalizado."),
    db_parameterized_query_no_return(Connection, "UPDATE Alugueis SET status_aluguel = 'Concluído' WHERE id_carro = '%w' AND status_aluguel = 'ativo'", [ID_Carro]),
    db_parameterized_query_no_return(Connection, "UPDATE Carros SET status = 'D' WHERE id_carro = '%w'", [ID_Carro]),
    menuLocadora.
processarPagamento("2", _, _) :- writeln("Operação cancelada!"), menuLocadora.

enviaParaMecanico(IDCarro) :-
    db_parameterized_query_no_return(Connection,  "UPDATE Carros SET status = 'R' WHERE id_carro = '%w'", [ID_Carro]).
