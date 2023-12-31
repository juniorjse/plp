:- module(locadora, [menuLocadora/0, opcaoMenu/1, cadastrarCarro/0, confirmaCadastro/1, registrarDevolucao/0, printAluguel/4, menuDashboard/0, menuOpcao/1, calcularReceitaTotal/2, 
contarAlugueis/2, contarCarros/2, listarCarrosMaisDefeituosos/2, listarAlugueisPorCategoria/2, exibirReceitaTotal/1,
exibirNumeroDeAlugueis/1, exibirTotalDeCarros/1, 
exibirCarrosMaisDefeituosos/1, exibirAlugueisPorCategoria/1, removerCarro/0,listarTodosCarros/0]).
:- use_module(library(odbc)).
:- use_module(library(readutil)).
:- use_module(library(date_time)).
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/util').

menuLocadora :-
    writeln(''),
    writeln('|-----------------------------------|'),
    writeln('|               MENU                |'),
    writeln('|-----------------------------------|'),
    writeln('|1. Cadastrar carro                 |'),
    writeln('|2. Remover Carro                   |'),
    writeln('|3. Registrar Devolução             |'),
    writeln('|4. Registro de Aluguéis por pessoa |'),
    writeln('|5. Dashboard                       |'),
    writeln('|0. Sair                            |'),
    writeln(''),
    writeln('Escolha uma opção:'),
    read_line_to_string(user_input, Opcao),
    writeln(''),
    (Opcao = "1" -> cadastrarCarro, menuLocadora;
     Opcao = "2" -> removerCarro, menuLocadora;
     Opcao = "3" -> registrarDevolucao;
     Opcao = "4" -> listarAlugueisPorPessoa, menuLocadora;
     Opcao = "5" -> menuDashboard, menuLocadora;
     Opcao = "0" -> writeln('Saindo...'), writeln(''), halt;
     writeln('Opção inválida. Por favor, escolha novamente.'), menuLocadora).

%LISTAS
mostraCarros([]).  
mostraCarros([row(Id, Marca, Modelo, Ano, Placa) | Outros]) :-
    format('|Id:~t ~w ~t~8+ Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+ Ano:  ~w   Placa:  ~w|~n',[ Id, Marca, Modelo, Ano, Placa]),
    mostraCarros(Outros).

listarTodosCarros :-
    writeln("|-------------------------------------------------------------------------------|"),
    writeln("|                                    CARROS                                     |"),
    writeln("|-------------------------------------------------------------------------------|"),
    connectiondb:iniciandoDatabase(Connection),

    user_operations:getAllCars(Connection, Carros),
    mostraCarros(Carros),
    writeln(''),

    connectiondb:encerrandoDatabase(Connection).


mostrarUsuarios([]).  
mostrarUsuarios([row(ID_Usuario, Nome, Sobrenome, Email) | Outros]) :-
    format('|Id:~t ~w ~t~8+ Nome:~t ~w ~t~15+ Sobrenome:~t ~w ~t~25+ Email:~t  ~w~t~39+|~n',[ID_Usuario, Nome, Sobrenome, Email]),
    mostrarUsuarios(Outros).

listarTodosUsuarios :-
    writeln("|--------------------------------------------------------------------------------------|"),
    writeln("|                                       USUARIOS                                       |"),
    writeln("|--------------------------------------------------------------------------------------|"),
    connectiondb:iniciandoDatabase(Connection),

    user_operations:getAllClientes(Connection, Clientes),
    mostrarUsuarios(Clientes),
    writeln(''),

    connectiondb:encerrandoDatabase(Connection).

mostrarAlugueis([]).  
mostrarAlugueis([row(ID, Marca, Modelo, Nome, Sobrenome) | Outros]) :-
    format('|Id:~t ~w ~t~8+ Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+ Cliente:~t ~w ~w~t~40+|~n',[ID, Marca, Modelo, Nome, Sobrenome]),
    mostrarAlugueis(Outros).

listarTodosAlugueis :-
    writeln("|------------------------------------------------------------------------------------------|"),
    writeln("|                                         ALUGUEIS                                         |"),
    writeln("|------------------------------------------------------------------------------------------|"),
    connectiondb:iniciandoDatabase(Connection),

    user_operations:getAlugueisAtivos(Connection, Alugueis),
    mostrarAlugueis(Alugueis),
    writeln(''),

    connectiondb:encerrandoDatabase(Connection).


%CADASTRAR_CARRO
cadastrarCarro :-
    connectiondb:iniciandoDatabase(Connection),
    writeln(''),
    writeln('|--------------------------------|'),
    writeln('| Digite as informações do carro |'),
    writeln('|--------------------------------|'),
    write('|Marca:     '),
    read_line_to_string(user_input, Marca),
    write('|Modelo:    '),
    read_line_to_string(user_input, Modelo),
    write('|Ano:       '),
    read_line_to_string(user_input, A),
    atom_number(A, Ano),
    write('|Placa:     '),
    read_line_to_string(user_input, Placa),
    write('|Categoria: '),
    read_line_to_string(user_input, Categoria),
    write('|Diária:    '),
    read_line_to_string(user_input, D),
    atom_number(D, Diaria),
    write('|Descrição: '),
    read_line_to_string(user_input, Descricao),
    writeln(''),
    confirmaCadastro(Confirm),
    (
        (Marca = "" ; Modelo = "" ; Ano = "" ; Placa = ""; Categoria = "" ; Diaria = "" ; Descricao = "") ->
            writeln('Nenhum campo pode estar vazio. Por favor, tente novamente.'),
            writeln(''),
            cadastrarCarro
        ;
        (
        Confirm = "2" -> writeln('Esse cadastro foi cancelado!')
        ;
        Confirm = "1" ->
            user_operations:createCar(Connection, Marca, Modelo, Ano, Placa, Categoria, Diaria, Descricao)
        )
    ),
    connectiondb:encerrandoDatabase(Connection),
    menuLocadora.

confirmaCadastro(Confirm) :-
    writeln('Tem certeza que deseja cadastrar esse carro? \n 1. Sim \n 2. Não'),
    read_line_to_string(user_input, C),
    ((C \= "1" , C \= "2") -> writeln('Opção inválida, tente novamente.\n'), confirmaCadastro(Confirm) ;
    Confirm = C).


%REGISTRAR_DEVOLUCAO
registrarDevolucao :-
    listarTodosAlugueis,
    writeln('Digite o número do contrato/Id do aluguel a ser encerrado:'),
    read_line_to_string(user_input, InputString),
    writeln(''),
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
        writeln('Opção inválida. Você será direcionado(a) ao menu inicial.'), menuLocadora)
        ;
        printAluguel( DataInicio, DataDevolucao, IDCarro),
        verificaDevolucao(DataDevolucao, Devolucao),
        (Devolucao = "Devolução dentro do prazo" ->
            writeln('|DEVOLUÇÃO NO PRAZO'),
            printDevolucao(ValorTotal, IDCarro);
        Devolucao = "Devolução adiantada" ->
            writeln('|DEVOLUÇÃO ADIANTADA \n|Motivo da devolução adiantada:'),
            writeln('|1. Problema no carro'),
            writeln('|2. Outro motivo'),
            read_line_to_string(user_input, Motivo),
            (Motivo = "1" -> enviaParaMecanico(IDCarro),
                             writeln('Carro enviado para conserto!'), menuLocadora;
             Motivo = "2" -> calculaValor( DataInicio, DataDevolucao, IDCarro, Valor), 
             printDevolucao(Valor, IDCarro), menuLocadora;
             writeln('Opção inválida. Você será direcionado(a) ao menu inicial.'), menuLocadora);
        writeln("|DEVOLUÇÃO ATRASADA"),
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
    format("|-----------Detalhes do aluguel com ID ~w:-------------| \n", [IDCarro]),
    Resultado = [row(Marca,Modelo,Ano)],
    dbop:db_parameterized_query(Connection, "SELECT marca, modelo, ano FROM Carros WHERE id_carro = '%w'", [IDCarro], Resultado),
    connectiondb:encerrandoDatabase(Connection),
    (
        Resultado = null ->
        writeln("Carro com ID " + IDCarro + " não encontrado.");  
        format("|Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+ Ano:  ~w|\n", [Marca,Modelo,Ano])
    ).

printAluguel(DataInicio, DataDevolucao, IDCarro) :-
    buscarCarro(IDCarro),
    DataInicio = date(YI,MI,DI),
    DataDevolucao = date(YD,MD,DD),
    calculaValor(DataInicio, DataDevolucao, IDCarro, Valor),
    format("|Data de início do aluguel:       ~w/~w/~w~n", [DI,MI,YI]),
    format("|Data de devolução:               ~w/~w/~w~n", [DD,MD,YD]),
    format("|Valor total do aluguel:          R$ ~w~n", [Valor]),
    writeln('').

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
    format("|Realizar pagamento do aluguel! \n|Valor total: R$ ~w\n\n", [Valor]),
    write("|1. Confirmar pagamento\n|2. Cancelar\n|:"),
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
processarPagamento("2", _,_) :- 
    writeln("Operação cancelada!"), menuLocadora.
processarPagamento(_, _,_) :- 
    writeln("Opção inválida. Você será direcionado(a) ao menu inicial."), menuLocadora.

enviaParaMecanico(IDCarro) :-
    connectiondb:iniciandoDatabase(Connection),
    db_parameterized_query_no_return(Connection,  "UPDATE Carros SET status = 'R' WHERE id_carro = %w", [IDCarro]),
    connectiondb:encerrandoDatabase(Connection).


%DASHBOARD
menuDashboard :-

    connectiondb:iniciandoDatabase(Connection),

    writeln(''),
    writeln('|---------------------------|'),
    writeln('|---------DASHBOARD---------|'),
    writeln('|---------------------------|'),
    writeln('|1. Receita total           |'),
    writeln('|2. Número de aluguéis      |'),
    writeln('|3. Total de carros         |'),
    writeln('|4. Carros mais defeituosos |'),
    writeln('|5. Aluguéis por categoria  |'),
    writeln('Escolha uma opção (ou digite qualquer outra coisa para voltar ao menu principal):'),
    read_line_to_string(user_input, Opcao),
    writeln(''),
    (Opcao = "1" -> exibirReceitaTotal(Connection)          ;
    Opcao = "2" -> exibirNumeroDeAlugueis(Connection)       ;
    Opcao = "3" -> exibirTotalDeCarros(Connection)          ;
    Opcao = "4" -> exibirCarrosMaisDefeituosos(Connection)  ;
    Opcao = "5" -> exibirAlugueisPorCategoria(Connection)   ;
    writeln('Dígito inválido. Voltando ao menu principal.'), menuLocadora),
    connectiondb:encerrandoDatabase(Connection).

calcularReceitaTotal(Connection, Total) :-
    db_query(Connection, 'SELECT SUM(valor_total) FROM Alugueis', [row(Total)]).

contarAlugueis(Connection, Count) :-
    db_query(Connection, 'SELECT COUNT(*) FROM Alugueis', [row(Count)]).

contarCarros(Connection, Count) :-
    db_query(Connection, 'SELECT COUNT(*) FROM Carros', [row(Count)]).

listarCarrosMaisDefeituosos(Connection, Carros) :-
    db_query(Connection, "SELECT marca, modelo FROM Carros WHERE status = 'R'", Carros).

listarAlugueisPorCategoria(Connection, Alugueis) :-
    db_query(Connection, 'SELECT categoria, COUNT(*) FROM Alugueis JOIN Carros ON Alugueis.id_carro = Carros.id_carro GROUP BY categoria ORDER BY count DESC', Alugueis).

mostraCarrosDefeituosos([]).  
mostraCarrosDefeituosos([row( Marca,Modelo) | Outros]) :-
    format('|Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+~n',[Marca, Modelo]),
    mostraCarrosDefeituosos(Outros).
    
mostraAlugueisPorCategoria([]).
mostraAlugueisPorCategoria([row(Categoria, Qtd)|Outros]) :-
    format('|~t ~w: ~t~20+ ~w ~n',[Categoria, Qtd]),
    mostraAlugueisPorCategoria(Outros).

exibirReceitaTotal(Connection) :-
    calcularReceitaTotal(Connection, Total),
    format('| Receita Total: ~w~n', [Total]),
    menuDashboard.

exibirNumeroDeAlugueis(Connection) :-
    contarAlugueis(Connection, Count),
    format('| Número de Aluguéis: ~w~n', [Count]),
    menuDashboard.

exibirTotalDeCarros(Connection) :-
    contarCarros(Connection, Count),
    format('| Total de Carros: ~w~n', [Count]),
    menuDashboard.

exibirCarrosMaisDefeituosos(Connection) :-
    listarCarrosMaisDefeituosos(Connection, Carros),
    writeln('| Carros mais defeituosos:'),
    mostraCarrosDefeituosos(Carros),
    menuDashboard.

exibirAlugueisPorCategoria(Connection) :-
    listarAlugueisPorCategoria(Connection, Alugueis),
    writeln('| Aluguéis por Categoria: '),
    mostraAlugueisPorCategoria(Alugueis),
    menuDashboard.


%REGISTRO_ALUGUEL_PESSOA
listarAlugueisPorPessoa :-

    listarTodosUsuarios,
    writeln('Digite o ID do cliente para listar os registros de aluguéis:'),
    util:get_input('', ClienteIDStr),
    writeln(''),

    (util:isANumber(ClienteID, ClienteIDStr) ->
        connectiondb:iniciandoDatabase(Connection),
        (clienteExiste(Connection, ClienteID) ->
            user_operations:getAlugueisPorPessoa(Connection, ClienteID, Alugueis),
            (length(Alugueis, NumRegistros), NumRegistros > 0 ->
                writeln('|REGISTRO DE ALUGUEIS\n'),
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

mostrarRegistroDeAluguel(Connection, row(IDCarro, Marca, Ano, Modelo, DataInicio, DataDevolucao, Valor, Status)) :-
    DataInicio = date(YI,MI,DI),
    DataDevolucao = date(YD,MD,DD),
    format('|Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+ Ano:  ~w~n', [Marca,Modelo,Ano]),
    format('|Início: ~w/~w/~w    Devolução: ~w/~w/~w~n', [DI,MI,YI,DD,MD,YD]), 
    format('|Valor:  R$ ~w~n', [Valor]),
    format('|Status:   ~w~n', [Status]),
    writeln('').

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

removerCarro :-
    listarTodosCarros,
    writeln('Digite o ID do carro que deseja remover:'),
    util:get_input('', CarroIDStr),

    (util:isANumber(CarroID, CarroIDStr) ->
        connectiondb:iniciandoDatabase(Connection),
        (carroExiste(Connection, CarroID) ->
            user_operations:getCarroStatus(Connection, CarroID, Status),  
            (Status = 'O' ->  
                writeln('Este carro no momento encontra-se alugado... Escolha outro ou retorne ao menu principal.')
            ;
                writeln('Confirma a remoção do carro? (s/n):'),
                read_line_to_string(user_input, ConfirmaRemocao),
                (ConfirmaRemocao = "s" ->  
                    user_operations:removeCarro(Connection, CarroID),
                    writeln('Carro removido com sucesso.');
                    writeln('Remoção cancelada.')  
                )
            )
        ;
            writeln('ID informado é inexistente ou incorreto.')  
        ),
        connectiondb:encerrandoDatabase(Connection)
    ;
        writeln('ID de carro inválido. Tente novamente.')
    ).
