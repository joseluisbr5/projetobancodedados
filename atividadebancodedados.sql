-- #############################################################################
-- #                                                                           #
-- #        TRABALHO DE BANCO DE DADOS - SISTEMA DE BIBLIOTECA                 #
-- #               SCRIPT COMPLETO: TABELAS, VIEWS, FUNCTIONS E PROCEDURES     #
-- #                                                                           #
-- #############################################################################


-- =============================================================================
-- SEÇÃO 1: CRIAÇÃO DAS TABELAS (SCHEMA)
-- =============================================================================

-- Excluindo tabelas se existirem para permitir a reexecução do script
DROP TABLE IF EXISTS emprestimo;
DROP TABLE IF EXISTS livro;
DROP TABLE IF EXISTS autor;
DROP TABLE IF EXISTS usuario;

-- Criando tabela de autores
CREATE TABLE autor (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

-- Criando tabela de livros
CREATE TABLE livro (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    id_autor INT NOT NULL REFERENCES autor(id),
    ano_publicacao INT
);

-- Criando tabela de usuários
CREATE TABLE usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

-- Criando tabela de empréstimos
CREATE TABLE emprestimo (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuario(id),
    id_livro INT NOT NULL REFERENCES livro(id),
    data_emprestimo DATE NOT NULL,
    data_devolucao DATE
);

-- =============================================================================
-- SEÇÃO 2: INSERÇÃO DE DADOS INICIAIS
-- =============================================================================

-- Inserindo autores
INSERT INTO autor (nome) VALUES
('Machado de Assis'),
('J. K. Rowling'),
('George Orwell'),
('Clarice Lispector');

-- Inserindo livros
INSERT INTO livro (titulo, id_autor, ano_publicacao) VALUES
('Dom Casmurro', 1, 1899),
('Harry Potter e a Pedra Filosofal', 2, 1997),
('1984', 3, 1949),
('A Hora da Estrela', 4, 1977),
('Harry Potter e a Câmara Secreta', 2, 1998);

-- Inserindo usuários
INSERT INTO usuario (nome) VALUES
('Ana'),
('Bruno'),
('Carla'),
('Diego');

-- Inserindo empréstimos
INSERT INTO emprestimo (id_usuario, id_livro, data_emprestimo, data_devolucao) VALUES
(1, 1, '2025-08-01', '2025-08-10'),
(2, 2, '2025-08-02', NULL),
(3, 3, '2025-08-05', '2025-08-15'),
(1, 5, '2025-08-07', NULL),
(4, 4, '2025-08-08', NULL);


-- =============================================================================
-- SEÇÃO 3: ALTERAÇÃO DE TABELA E ATUALIZAÇÃO DE DADOS
-- =============================================================================

-- Adicionando a coluna 'valor' na tabela de empréstimos
ALTER TABLE emprestimo ADD COLUMN valor NUMERIC(10,2);

-- Atualizando os valores de empréstimos existentes
UPDATE emprestimo SET valor = 5.00 WHERE id = 1;
UPDATE emprestimo SET valor = 7.50 WHERE id = 2;
UPDATE emprestimo SET valor = 6.00 WHERE id = 3;
UPDATE emprestimo SET valor = 4.50 WHERE id = 4;
UPDATE emprestimo SET valor = 8.00 WHERE id = 5;


-- =============================================================================
-- SEÇÃO 4: CRIAÇÃO DAS VIEWS
-- =============================================================================

-- View para mostrar livros com seus autores
CREATE OR REPLACE VIEW livros_com_autores AS
SELECT
    l.titulo,
    a.nome AS nome_autor
FROM livro l
JOIN autor a ON l.id_autor = a.id;

-- View para mostrar usuários e os livros que emprestaram
CREATE OR REPLACE VIEW usuarios_com_emprestimos AS
SELECT
    u.nome AS nome_usuario,
    l.titulo AS titulo_livro
FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id
JOIN livro l ON e.id_livro = l.id;

-- View para mostrar empréstimos ainda não devolvidos
CREATE OR REPLACE VIEW emprestimos_em_aberto AS
SELECT
    e.id,
    u.nome AS nome_usuario,
    l.titulo AS titulo_livro,
    e.data_emprestimo
FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id
JOIN livro l ON e.id_livro = l.id
WHERE e.data_devolucao IS NULL;

-- View para o histórico completo de empréstimos
CREATE OR REPLACE VIEW historico_emprestimos AS
SELECT
    u.nome AS nome_usuario,
    l.titulo AS titulo_livro,
    a.nome AS nome_autor,
    e.data_emprestimo
FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id
JOIN livro l ON e.id_livro = l.id
JOIN autor a ON l.id_autor = a.id;

-- View para contar quantos empréstimos cada usuário fez
CREATE OR REPLACE VIEW qtd_emprestimos_por_usuario AS
SELECT
    u.nome,
    COUNT(e.id) AS quantidade_emprestimos
FROM usuario u
LEFT JOIN emprestimo e ON u.id = e.id_usuario
GROUP BY u.nome
ORDER BY quantidade_emprestimos DESC;

-- View para listar livros publicados depois de 1950
CREATE OR REPLACE VIEW livros_mais_recentes AS
SELECT
    l.titulo,
    a.nome AS nome_autor,
    l.ano_publicacao
FROM livro l
JOIN autor a ON l.id_autor = a.id
WHERE l.ano_publicacao > 1950;

-- View para mostrar usuários que fizeram mais de um empréstimo
CREATE OR REPLACE VIEW usuarios_com_mais_de_um_emprestimo AS
SELECT
    u.nome,
    COUNT(e.id) AS total_emprestimos
FROM usuario u
JOIN emprestimo e ON u.id = e.id_usuario
GROUP BY u.nome
HAVING COUNT(e.id) > 1;


-- =============================================================================
-- SEÇÃO 5: CRIAÇÃO DAS FUNCTIONS
-- =============================================================================

-- Função que retorna o nome do autor a partir do ID do livro
CREATE OR REPLACE FUNCTION autor_do_livro(p_id_livro INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_nome_autor VARCHAR;
BEGIN
    SELECT a.nome INTO v_nome_autor
    FROM autor a
    JOIN livro l ON a.id = l.id_autor
    WHERE l.id = p_id_livro;
    RETURN v_nome_autor;
END;
$$;

-- Função que verifica se um livro está emprestado ou disponível
CREATE OR REPLACE FUNCTION livro_emprestado(p_id_livro INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_data_devolucao DATE;
BEGIN
    SELECT data_devolucao INTO v_data_devolucao
    FROM emprestimo
    WHERE id_livro = p_id_livro
    ORDER BY data_emprestimo DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN 'Livro disponível';
    END IF;

    IF v_data_devolucao IS NULL THEN
        RETURN 'Livro emprestado';
    ELSE
        RETURN 'Livro disponível';
    END IF;
END;
$$;

-- Função que verifica se um usuário tem empréstimos atrasados (> 10 dias)
CREATE OR REPLACE FUNCTION usuario_com_atraso(p_id_usuario INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_emprestimos_atrasados INT;
BEGIN
    -- O dia de hoje é 09/09/2025. O empréstimo do usuário 2 foi em 02/08/2025.
    -- Para fins de teste, vamos simular que a data atual é '2025-08-15'.
    -- Para uma verificação em tempo real, use CURRENT_DATE.
    SELECT COUNT(*) INTO v_emprestimos_atrasados
    FROM emprestimo
    WHERE id_usuario = p_id_usuario
      AND data_devolucao IS NULL
      AND ('2025-09-09'::DATE - data_emprestimo) > 10;
      -- Em um ambiente real, substitua '2025-09-09' por CURRENT_DATE

    IF v_emprestimos_atrasados > 0 THEN
        RETURN 'Usuário possui livros atrasados';
    ELSE
        RETURN 'Usuário em dia';
    END IF;
END;
$$;


-- Função que retorna o valor total gasto por um usuário em empréstimos
CREATE OR REPLACE FUNCTION total_gasto_usuario(p_id_usuario INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_gasto NUMERIC(10,2);
BEGIN
    SELECT COALESCE(SUM(valor), 0.00) INTO v_total_gasto
    FROM emprestimo
    WHERE id_usuario = p_id_usuario;
    RETURN v_total_gasto;
END;
$$;


-- =============================================================================
-- SEÇÃO 6: CRIAÇÃO DAS PROCEDURES
-- =============================================================================

-- Procedure para cadastrar um novo usuário
CREATE OR REPLACE PROCEDURE cadastrar_usuario(p_nome VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO usuario (nome) VALUES (p_nome);
END;
$$;

-- Procedure para cadastrar um novo livro
CREATE OR REPLACE PROCEDURE cadastrar_livro(p_titulo VARCHAR, p_id_autor INT, p_ano_publicacao INT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO livro (titulo, id_autor, ano_publicacao) VALUES (p_titulo, p_id_autor, p_ano_publicacao);
END;
$$;

-- Procedure para registrar a devolução de um livro
CREATE OR REPLACE PROCEDURE registrar_devolucao(p_id_emprestimo INT, p_data_devolucao DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE emprestimo
    SET data_devolucao = p_data_devolucao
    WHERE id = p_id_emprestimo;
END;
$$;

-- Procedure para excluir um usuário e todos os seus empréstimos
CREATE OR REPLACE PROCEDURE excluir_usuario(p_id_usuario INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Exclui primeiro os empréstimos para evitar violação de chave estrangeira
    DELETE FROM emprestimo WHERE id_usuario = p_id_usuario;
    -- Depois, exclui o usuário
    DELETE FROM usuario WHERE id = p_id_usuario;
END;
$$;