# Trabalho de Banco de Dados: Procedures, Views e Functions

Este repositório contém a solução para um trabalho da disciplina de Banco de Dados, focado na implementação e uso de `Procedures`, `Views` e `Functions` em um sistema de gerenciamento de biblioteca. O banco de dados utilizado é o **PostgreSQL**.

## 1. Explicação dos Conceitos

### O que são Stored Procedures?
**Stored Procedures** (ou procedimentos armazenados) são conjuntos de comandos SQL pré-compilados que são armazenados no banco de dados. Elas podem receber parâmetros de entrada e saída, executar instruções de manipulação de dados (`INSERT`, `UPDATE`, `DELETE`), e encapsular regras de negócio complexas.

* **Vantagens**:
    * **Performance**: São executadas diretamente no servidor de banco de dados, reduzindo o tráfego de rede.
    * **Segurança**: Permitem que usuários executem operações complexas sem ter acesso direto às tabelas.
    * **Reutilização**: Podem ser chamadas por diversas aplicações sem a necessidade de reescrever o código SQL.

### O que são Views?
**Views** são, essencialmente, tabelas virtuais cujo conteúdo é definido por uma consulta `SELECT`. Elas não armazenam dados fisicamente, mas apresentam os dados de uma ou mais tabelas de uma forma estruturada e simplificada.

* **Vantagens**:
    * **Simplicidade**: Ocultam a complexidade de joins e cálculos, facilitando consultas recorrentes.
    * **Segurança**: Podem ser usadas para restringir o acesso a certas colunas ou linhas de uma tabela.
    * **Abstração**: A estrutura das tabelas subjacentes pode ser modificada sem que as aplicações que consomem a view sejam afetadas.

### O que são Functions?
**Functions** (ou UDFs - User-Defined Functions) são rotinas que, assim como as procedures, executam um conjunto de operações. A principal diferença é que uma função **sempre retorna um valor** (seja um valor escalar, como um número ou texto, ou um conjunto de dados, como uma tabela).

* **Vantagens**:
    * **Encapsulamento de Lógica**: Ideais para encapsular cálculos e lógicas de formatação que podem ser reutilizados em várias consultas.
    * **Uso em Queries**: Funções escalares podem ser usadas diretamente em cláusulas `SELECT`, `WHERE` e `ORDER BY`, tornando o código SQL mais limpo e modular.

## 2. Implementação das Atividades

Abaixo estão descritas as implementações realizadas para o sistema da biblioteca.

### Procedures

* `cadastrar_usuario(p_nome VARCHAR)`: Insere um novo usuário na tabela `usuario`.
* `cadastrar_livro(p_titulo VARCHAR, p_id_autor INT, p_ano_publicacao INT)`: Registra um novo livro na tabela `livro`.
* `registrar_devolucao(p_id_emprestimo INT, p_data_devolucao DATE)`: Atualiza a data de devolução de um empréstimo existente.
* `excluir_usuario(p_id_usuario INT)`: Remove todos os empréstimos associados a um usuário e, em seguida, remove o próprio usuário. Garante a integridade referencial.

### Views

* `livros_com_autores`: Lista todos os livros e o nome de seus respectivos autores.
* `usuarios_com_emprestimos`: Mostra o nome de cada usuário e os títulos dos livros que eles pegaram emprestado.
* `emprestimos_em_aberto`: Filtra e exibe todos os empréstimos que ainda não foram devolvidos.
* `historico_emprestimos`: Apresenta um histórico completo, unindo dados de usuários, livros, autores e as datas de empréstimo.
* `qtd_emprestimos_por_usuario`: Calcula e exibe a quantidade total de empréstimos feitos por cada usuário.
* `livros_mais_recentes`: Lista os livros publicados após o ano de 1950, junto com seus autores.
* `usuarios_com_mais_de_um_emprestimo`: Identifica e mostra os usuários que realizaram mais de um empréstimo.

### Functions

* `autor_do_livro(p_id_livro INT)`: Recebe o ID de um livro e retorna o nome do seu autor.
* `livro_emprestado(p_id_livro INT)`: Verifica o status do último empréstimo de um livro e retorna "Livro emprestado" ou "Livro disponível".
* `usuario_com_atraso(p_id_usuario INT)`: Analisa os empréstimos de um usuário e retorna "Usuário possui livros atrasados" se houver algum empréstimo em aberto há mais de 10 dias, ou "Usuário em dia" caso contrário.
* `total_gasto_usuario(p_id_usuario INT)`: Recebe o ID de um usuário e retorna a soma de todos os valores gastos em seus empréstimos. Retorna 0 se o usuário não tiver empréstimos.

## 3. Instruções de Execução

Para configurar e testar o banco de dados, siga a ordem de execução abaixo em um cliente PostgreSQL (como DBeaver, pgAdmin ou psql).

1.  **Criação do Schema e Inserção de Dados**:
    * Execute o script inicial que contém os comandos `CREATE TABLE` e `INSERT INTO` para criar a estrutura e popular o banco com os dados iniciais.
    * Execute os comandos `ALTER TABLE` e `UPDATE` para adicionar e popular a coluna `valor` na tabela `emprestimo`.

2.  **Criação das Funções**:
    * Execute os scripts `CREATE OR REPLACE FUNCTION` para criar todas as funções.

3.  **Criação das Procedures**:
    * Execute os scripts `CREATE OR REPLACE PROCEDURE` para criar todas as procedures.

4.  **Criação das Views**:
    * Execute os scripts `CREATE OR REPLACE VIEW` para criar todas as views.

### Exemplos de Uso

```sql
-- Testando uma Procedure
CALL cadastrar_usuario('Novo Usuario');

-- Testando uma View
SELECT * FROM emprestimos_em_aberto;

-- Testando uma Função
SELECT titulo, autor_do_livro(id) FROM livro WHERE id = 1;
SELECT nome, usuario_com_atraso(id) FROM usuario WHERE id = 2;
SELECT nome, total_gasto_usuario(id) FROM usuario WHERE id = 1;
```

## 4. Diagrama de Entidade e Relacionamento (DER)

O diagrama abaixo representa a estrutura do banco de dados, mostrando as entidades e como elas se relacionam.

![Diagrama de Entidade e Relacionamento do Sistema de Biblioteca](https://i.imgur.com/uH7u7zH.png)

**Descrição das Relações:**

* **autor (1) -- (N) livro**: Um autor pode ter escrito vários livros, mas um livro pertence a apenas um autor.
* **usuario (1) -- (N) emprestimo**: Um usuário pode realizar vários empréstimos, mas cada registro de empréstimo pertence a um único usuário.
* **livro (1) -- (N) emprestimo**: Um livro pode ser emprestado várias vezes (em diferentes momentos), mas cada registro de empréstimo refere-se a um único livro.