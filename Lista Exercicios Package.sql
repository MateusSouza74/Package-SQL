CREATE OR REPLACE PACKAGE PKG_GESTAO_ALUNO IS
    PROCEDURE remover_aluno(p_aluno_id IN NUMBER);

    CURSOR cursor_alunos_maiores_18 IS
        SELECT nome, data_nascimento
        FROM alunos
        WHERE FLOOR(MONTHS_BETWEEN(SYSDATE, data_nascimento) / 12) > 18;

    CURSOR cursor_alunos_curso(p_curso_id IN NUMBER) IS
        SELECT aluno.nome
        FROM alunos aluno
        INNER JOIN matriculas mat ON aluno.id_aluno = mat.id_aluno
        WHERE mat.id_curso = p_curso_id;
END PKG_GESTAO_ALUNO;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_ALUNO IS

    PROCEDURE remover_aluno(p_aluno_id IN NUMBER) IS
    BEGIN
        DELETE FROM matriculas WHERE id_aluno = p_aluno_id;
        DELETE FROM alunos WHERE id_aluno = p_aluno_id;
        COMMIT;
    END remover_aluno;

END PKG_GESTAO_ALUNO;
/


CREATE OR REPLACE PACKAGE PKG_GESTAO_DISCIPLINA IS

    PROCEDURE adicionar_disciplina(
        p_nome IN VARCHAR2,
        p_descricao IN VARCHAR2,
        p_carga_horaria IN NUMBER
    );

    CURSOR cursor_disciplinas_populares IS
        SELECT disc.id_disciplina, disc.nome, COUNT(mat.id_aluno) AS qtd_alunos
        FROM disciplinas disc
        JOIN matriculas mat ON disc.id_disciplina = mat.id_disciplina
        GROUP BY disc.id_disciplina, disc.nome
        HAVING COUNT(mat.id_aluno) > 10;

    CURSOR cursor_idade_media_disciplina(p_disciplina_id IN NUMBER) IS
        SELECT AVG(FLOOR(MONTHS_BETWEEN(SYSDATE, aluno.data_nascimento) / 12)) AS media_idade
        FROM alunos aluno
        JOIN matriculas mat ON aluno.id_aluno = mat.id_aluno
        WHERE mat.id_disciplina = p_disciplina_id;

    PROCEDURE listar_alunos_disciplina(p_disciplina_id IN NUMBER);
END PKG_GESTAO_DISCIPLINA;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_DISCIPLINA IS

    PROCEDURE adicionar_disciplina(
        p_nome IN VARCHAR2,
        p_descricao IN VARCHAR2,
        p_carga_horaria IN NUMBER
    ) IS
    BEGIN
        INSERT INTO disciplinas (nome, descricao, carga_horaria)
        VALUES (p_nome, p_descricao, p_carga_horaria);
        COMMIT;
    END adicionar_disciplina;

    PROCEDURE listar_alunos_disciplina(p_disciplina_id IN NUMBER) IS
    BEGIN
        FOR aluno IN (
            SELECT aluno.nome
            FROM alunos aluno
            JOIN matriculas mat ON aluno.id_aluno = mat.id_aluno
            WHERE mat.id_disciplina = p_disciplina_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Nome do Aluno: ' || aluno.nome);
        END LOOP;
    END listar_alunos_disciplina;

END PKG_GESTAO_DISCIPLINA;
/


CREATE OR REPLACE PACKAGE PKG_GESTAO_PROFESSOR IS

    CURSOR cursor_turmas_por_professor IS
        SELECT prof.nome, COUNT(turma.id_turma) AS qtd_turmas
        FROM professores prof
        JOIN turmas turma ON prof.id_professor = turma.id_professor
        GROUP BY prof.nome
        HAVING COUNT(turma.id_turma) > 1;

    FUNCTION total_turmas_professor(p_professor_id IN NUMBER) RETURN NUMBER;

    FUNCTION professor_responsavel_disciplina(p_disciplina_id IN NUMBER) RETURN VARCHAR2;

END PKG_GESTAO_PROFESSOR;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_PROFESSOR IS

    FUNCTION total_turmas_professor(p_professor_id IN NUMBER) RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM turmas
        WHERE id_professor = p_professor_id;
        RETURN v_total;
    END total_turmas_professor;

    FUNCTION professor_responsavel_disciplina(p_disciplina_id IN NUMBER) RETURN VARCHAR2 IS
        v_nome VARCHAR2(100);
    BEGIN
        SELECT prof.nome
        INTO v_nome
        FROM professores prof
        JOIN disciplinas disc ON prof.id_professor = disc.id_professor
        WHERE disc.id_disciplina = p_disciplina_id;
        RETURN v_nome;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Nenhum professor encontrado para esta disciplina.';
    END professor_responsavel_disciplina;

END PKG_GESTAO_PROFESSOR;
/
