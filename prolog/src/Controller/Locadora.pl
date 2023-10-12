:- module(locadora, [menuLocadora/0, escolherOpcao/1, cadastrarCarro/0, naoConfirmaCadastro/0]).
:- use_module(library(odbc)).
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
    escolherOpcao(Opcao).

escolherOpcao("1") :-    cadastrarCarro.
escolherOpcao("0") :-    writeln('Saindo...'), writeln(''), halt.
escolherOpcao(_)   :-    writeln('Opção inválida. Por favor, escolha novamente.'), menuLocadora.

cadastrarCarro :-
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
    atom_number(A,Ano),
    write('|Placa:     '),
    read_line_to_string(user_input, Placa),    
    write('|Categoria: '),
    read_line_to_string(user_input, Categoria),    
    write('|Diária:    '),    
    read_line_to_string(user_input, D),
    atom_number(D,Diaria),
    write('|Descrição: '),
    read_line_to_string(user_input, Descricao),   
    writeln(''),
    (
        (Marca = "" ; Modelo = "" ; Ano = "" ; Placa = ""; Categoria = "" ; Diaria = "" ; Descricao = "") ->
            writeln('Nenhum campo pode estar vazio. Por favor, tente novamente.'),
            writeln(''),
            cadastrarCarro
        ;
        naoConfirmaCadastro ->
            writeln('Esse cadastro foi cancelado!'),
            menuLocadora
        ;
            createCar(Marca, Modelo, Ano, Placa, Categoria, Diaria, Descricao, Confirmacao),
            (
                Confirmacao =:= 1 ->
                    writeln('Cadastro realizado com sucesso! Informações do carro cadastrado:'),
                    format("Marca:    %w \n Modelo:    %w \n Ano:      %w \n Placa:    %w \n Categoria: %w \n Diária:    %w \n Descrição: %w \n ", 
                            [Marca, Modelo, Ano, Placa, Categoria, Diaria, Descricao]),
                    menuLocadora
                ;
                    writeln('Esse carro já foi cadastrado no sistema! Tente novamente.'),
                    cadastrarCarro
            )
        ).

naoConfirmaCadastro:-
    write('Tem certeza que deseja cadastrar esse carro? \n 1.Sim \n 2.Não \n'), read_line_to_string(user_input, C),
    (C = "1" -> false ; C = "2" -> true ; naoConfirmaCadastro).

createCar(Marca, Modelo, Ano, Placa, Categoria, Diaria, Descricao, Confirmacao) :-
    connectiondb:iniciandoDatabase(Connection),
    carAlreadyExists(Connection, Placa, confCarro),
    (confCarro =:= 0 ->
            format(string(Query), "INSERT INTO carros (marca, modelo, ano, placa, categoria, quilometragem, status, diaria_carro, descricao_carro) VALUES ( '~w', '~w', '~w', '~w', '~w', '~w', '~w', '~w')",
               [Marca, Modelo, Ano, Placa, Categoria, 0.0, "A", Diaria, Descricao]),
            dbop:db_query_no_return(Connection, Query),             
            Confirmacao is 1
        ;
            Confirmacao is 0
    ),
    connectiondb:encerrandoDatabase(Connection).