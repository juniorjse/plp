# 🚗 MÃO NA RODA - LOCADORA DE AUTOMÓVEIS 🛻

## 🖥️ O SISTEMA

O projeto consiste em desenvolver um sistema de locadora de carros operado por terminal de linha de comando. Os principais requisitos incluem autenticação de usuários, cadastro de novos usuários e carros, registro de aluguéis e devoluções, listagem de carros disponíveis, ranking de mais alugados, sistema de recomendação e cancelamento de aluguéis. O sistema busca oferecer uma solução eficiente para a gestão de aluguéis de carros, proporcionando uma experiência ágil e facilitada para os usuários e a locadora. Nesse projeto terá 3 atores principais que serão os usuários(clientes), locadora e o mecânico, onde cada um terá seus respectivos menus com as opções necessárias.

## 📋 REQUISITOS FUNCIONAIS

* **Cliente**  
     - Login e Cadastro de novos usuários.
     - Visualização de carros por categoria.
     - Realização de aluguel.
     - Cancelamento de aluguel.
     - Visualização de Ranking de carros por popularidade (mais alugados).

* **Locadora** (Admin)  
     - Cadastrar Carro.
     - Registrar a devolução.
     - Visualizar o registro de alugueis por pessoa.
     - Visualizar _Dashboard_ com informações e estatísticas da locadora.

* **Mecânico**  
     - Visualizar carros que necessitam de reparo.
     - Marcar o reparo de um carro como finalizado.

## 💻 COMO EXECUTAR

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

- **ATENÇÃO:** Porta e/ou senha diferentes das utilizadas na aplicação podem acarretar em problemas na execução. Ao instalar o PostgreSQL tenha certeza que as informações estão compatíveis com o projeto.

### HASKELL:

1. Instale o [GHCup](https://www.haskell.org/ghcup/);
2. Baixe as extensões necessárias, caso esteja no VSCode;
3. Se o seu PostgreSQL já estiver devidamente configurado, abra um terminal no diretório haskell e rode os comandos: `cabal init -n` e `cabal build`.
4. Caso não ocorram erros, digite cabal run para rodar a aplicação.

### PROLOG:
 
1. Faça o download do [SWI_Prolog](https://www.swi-prolog.org/download/stable);  
2. Se o seu PostgreSQL já estiver devidamente configurado, abra um terminal no diretório prolog\src e digite o comando `swipl run.pl` para executar a aplicação.


## 👩‍💻AUTORES👨‍💻
- [@juniorjse](https://github.com/juniorjse)
- [@Leticiagc](https://github.com/Leticiagc)
- [@carolcordeiro](https://github.com/carolcordeiro)
- [@luizaugustoliveira](https://github.com/luizaugustoliveira)
- [@vitoriapimentel2103](https://github.com/vitoriapimentel2103)
