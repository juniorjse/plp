:- module(locadora, [menuLocadora/0, menuDashboard/0, menuOpcao/1, calcularReceitaTotal/2, 
contarAlugueis/2, contarCarros/2, listarCarrosMaisDefeituosos/2, listarAlugueisPorCategoria/2, exibirReceitaTotal/1,
exibirNumeroDeAlugueis/1, exibirTotalDeCarros/1, 
exibirCarrosMaisDefeituosos/1, exibirAlugueisPorCategoria/1]).


:- use_module(util).
:- module(locadora, [menuLocadora/0, opcaoMenu/1, cadastrarCarro/0, confirmaCadastro/1]).
:- use_module(library(odbc)).
:- use_module(library(readutil)).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').


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
    opcaoMenu(Opcao).

opcaoMenu("1") :-    cadastrarCarro.
opcaoMenu("0") :-    writeln('Saindo...'), writeln(''), halt.
opcaoMenu(_)   :-    writeln('Opção inválida. Por favor, escolha novamente.'), menuLocadora.

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

menuDashboard :-

    connectiondb:iniciandoDatabase(Connection),

    writeln(''),
    writeln('Dashboard:'),
    writeln('1. Receita total'),
    writeln('2. Número de aluguéis'),
    writeln('3. Total de carros'),
    writeln('4. Carros mais defeituosos'),
    writeln('5. Aluguéis por categoria'),
    writeln('Escolha uma opção (ou digite qualquer outra coisa para voltar ao menu principal):'),
    read_line_to_string(user_input, Opcao),
    writeln(''),
    menuOpcao(Opcao).

menuOpcao("1", Connection) :- exibirReceitaTotal(Connection).
menuOpcao("2", Connection) :- exibirNumeroDeAlugueis(Connection).
menuOpcao("3", Connection) :- exibirTotalDeCarros(Connection).
menuOpcao("4", Connection) :- exibirCarrosMaisDefeituosos(Connection).
menuOpcao("5", Connection) :- exibirAlugueisPorCategoria(Connection).

menuOpcao(_, Connection) :-
    writeln('Dígito inválido. Voltando ao menu principal.'),
    menuDashboard(Connection).

calcularReceitaTotal(Connection, Total) :-
    odbc_query(Connection, 'SELECT SUM(valor_total) FROM Alugueis', row([Total])).

contarAlugueis(Connection, Count) :-
    odbc_query(Connection, 'SELECT COUNT(*) FROM Alugueis', row([Count])).

contarCarros(Connection, Count) :-
    odbc_query(Connection, 'SELECT COUNT(*) FROM Carros', row([Count])).

listarCarrosMaisDefeituosos(Connection, Carros) :-
    odbc_query(Connection, 'SELECT marca, modelo FROM Carros WHERE status = ''R''', rows(Carros)).

listarAlugueisPorCategoria(Connection, Alugueis) :-
    odbc_query(Connection, 'SELECT categoria, COUNT(*) FROM Alugueis JOIN Carros ON Alugueis.id_carro = Carros.id_carro GROUP BY categoria', rows(Alugueis)).

exibirReceitaTotal(Connection) :-
    calcularReceitaTotal(Connection, Total),
    writeln('Receita Total: '),
    write(Total),
    menuDashboard(Connection).

exibirNumeroDeAlugueis(Connection) :-
    contarAlugueis(Connection, Count),
    writeln('Número de Aluguéis: '),
    write(Count),
    menuDashboard(Connection).

exibirTotalDeCarros(Connection) :-
    contarCarros(Connection, Count),
    writeln('Total de Carros: '),
    write(Count),
    menuDashboard(Connection).

exibirCarrosMaisDefeituosos(Connection) :-
    listarCarrosMaisDefeituosos(Connection, Carros),
    writeln('Carros mais defeituosos:'),
    maplist(writeCarro, Carros),
    menuDashboard(Connection).

exibirAlugueisPorCategoria(Connection) :-
    listarAlugueisPorCategoria(Connection, Alugueis),
    writeln('Aluguéis por Categoria:'),
    maplist(writeCategoria, Alugueis),
    menuDashboard(Connection).

connectiondb:encerrandoDatabase(Connection).



