:- module(locadora, [menuLocadora/0, menuDashboard/1, calcularReceitaTotal/0, contarAlugueis/1, contarCarros/0, 
listarCarrosMaisDefeituosos/1, listarAlugueisPorCategoria/0, exibirReceitaTotal/1, 
exibirNumeroDeAlugueis/0, exibirTotalDeCarros/1, exibirCarrosMaisDefeituosos/0, exibirAlugueisPorCategoria/1]).
:- use_module(util).
:- use_module(library(odbc)).
:- use_module(library(readutil)).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').


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

    writeln('').

menuDashboard(Connection) :-
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
    menuOpcao(Opcao, Connection).

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

writeCarro([Marca, Modelo]) :-
    format('~w ~w~n', [Marca, Modelo]).

writeCategoria([Categoria, Quantidade]) :-
    format('~w: ~w~n', [Categoria, Quantidade]).


