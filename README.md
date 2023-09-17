# MÃO NA RODA - LOCADORA DE AUTOMÓVEIS 

## O SISTEMA

Esse é um sistema para uma locadora de automóveis que roda em terminal e tem como usuários principais: o Cliente, a Locadora e o Mecânico. Como veremos detalhadamente mais a frente, o cliente poderá, após se cadastrar, visualizar os carros disponíveis, realizar e cancelar alugueis; a Locadora pode cadastrar novos carros nos banco de dados, registrar a devolução de um carro e visualizar alugueis passados dos clientes; e o mecânico pode visualizar os carros que foram entregues com defeitos, registrar que o reparo foi realizado e inserir o valor adicional do reparo ao aluguel.

## REQUISITOS FUNCIONAIS

## COMO EXECUTAR

### Instalação do PostgreSQL:

1. Baixe o [PostgreSQL](https://www.enterprisedb.com/postgresql-tutorial-resources-training-2?uuid=b63d9058-0ab9-44f7-aef0-ec0e0e2414e5&campaignId=Product_Trial_PostgreSQL_14). Para nossa aplicação foi utilizada a versão 14;  
2. Baixe o [driver do PostgreSQL ODBC para Windows](https://www.postgresql.org/ftp/odbc/versions/msi/);
3. Após a instalação, entre no pgAdmin e crie o database “plp_app”;
4. Pesquise no menu iniciar por ODBC e clique na primeira opção. A tela “Administrador de Fonte de Dados ODBC” deve abrir. Na aba “DNS de Usuário” clique em Adicionar, e crie uma fonte de dados com o driver “PostgreSQL Unicode” que você baixou anteriormente. Os dados a serem inseridos são:  
>
     Data Source: SWI-Prolog 
     Database: plp_app
     Server: localhost
     User: postgres
     Description: DSN para conexão local ao PostgreSQL
     SSL mode: disable
     Port: 5433
     Password: plp123 

- ATENÇÃO. Porta e/ou senha diferentes das utilizadas na aplicação podem acarretar em problemas na execução. Ao instalar o PostgreSQL tenha certeza que as informações estão compatíveis com o projeto.

### HASKELL:

1. Instale o [GHCup](https://www.haskell.org/ghcup/);
2. Baixe as extensões necessárias, caso esteja no VSCode;
3. Se o seu PostgreSQL já estiver devidamente configurado, abra um terminal no diretório haskell e rode os comandos: `cabal init -n` e `cabal build`.
4. Caso não ocorram erros, digite cabal run para rodar a aplicação.

### PROLOG:
 
1. Faça o download do [SWI_Prolog](https://www.swi-prolog.org/download/stable);  
2. Se o seu PostgreSQL já estiver devidamente configurado, abra um terminal no diretório prolog\src e digite o comando `swipl run.pl` para executar a aplicação.


## AUTORES
- [@juniorjse](https://github.com/juniorjse)
- [@Leticiagc](https://github.com/Leticiagc)
- [@carolcordeiro](https://github.com/carolcordeiro)
- [@luizaugustoliveira](https://github.com/luizaugustoliveira)
- [@vitoriapimentel2103](https://github.com/vitoriapimentel2103)
