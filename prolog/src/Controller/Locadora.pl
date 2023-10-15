:- module(locadora, [menuLocadora/0, opcaoMenu/1, cadastrarCarro/0, confirmaCadastro/1]).
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
