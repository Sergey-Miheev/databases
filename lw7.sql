-- 1. Добавить внешние ключи.
ALTER TABLE lesson
    ADD CONSTRAINT lesson_subject_id_subject FOREIGN KEY (id_subject)
    REFERENCES subject(id_subject);

ALTER TABLE lesson
    ADD CONSTRAINT lesson_teacher_id_teacher FOREIGN KEY (id_teacher)
    REFERENCES teacher(id_teacher);

ALTER TABLE student
    ADD CONSTRAINT student_group_id_group FOREIGN KEY (id_group)
    REFERENCES "group"(id_group);

ALTER TABLE student
    ADD CONSTRAINT student_group_id_group FOREIGN KEY (id_group)
    REFERENCES "group"(id_group);

ALTER TABLE mark
    ADD CONSTRAINT mark_student_id_student FOREIGN KEY (id_student)
    REFERENCES student(id_student);

ALTER TABLE mark
    ADD CONSTRAINT mark_lesson_id_student FOREIGN KEY (id_lesson)
    REFERENCES lesson(id_lesson);

-- 2. Выдать оценки студентов по информатике если они обучаются данному
-- предмету. Оформить выдачу данных с использованием view.
CREATE OR REPLACE TEMP VIEW mark_informatics
AS SELECT l.id_lesson FROM lesson l
JOIN subject sb on l.id_subject = sb.id_subject
WHERE sb.name = 'Информатика';

DROP VIEW mark_informatics;

SELECT s.name, m.mark FROM mark_informatics mi
JOIN mark m USING (id_lesson)
JOIN student s on m.id_student = s.id_student;

-- 3. Дать информацию о должниках с указанием фамилии студента и названия
-- предмета. Должниками считаются студенты, не имеющие оценки по предмету,
-- который ведется в группе. Оформить в виде процедуры, на входе идентификатор группы.
CREATE OR REPLACE PROCEDURE debtor(IN group_number integer)
LANGUAGE plpgsql AS $$
BEGIN
CREATE TEMP TABLE temp AS
SELECT s.name, sub.name as sub, MAX(m.mark) AS max_mark
	FROM student s
		LEFT JOIN lesson l ON l.id_group = s.id_group
		LEFT JOIN subject sub ON sub.id_subject = l.id_subject
		LEFT JOIN mark m ON m.id_lesson = l.id_lesson AND m.id_student = s.id_student
	WHERE s.id_group = group_number
	GROUP BY s.name, sub.name
	HAVING MAX(m.mark) IS NULL
	ORDER BY s.name, sub.name;
END
$$;

DROP PROCEDURE debtor(integer);


DO $$
DECLARE number int := 1;
BEGIN
  CALL debtor(number);
END
$$;

SELECT * FROM temp;

DROP TABLE temp;

-- 4. Дать среднюю оценку студентов по каждому предмету для тех предметов, по
-- которым занимается не менее 35 студентов
SELECT sb.name, COUNT(DISTINCT m.id_student) max_students, AVG(m.mark) FROM subject sb
LEFT JOIN lesson l on sb.id_subject = l.id_subject
LEFT JOIN mark m on l.id_lesson = m.id_lesson
GROUP BY sb.name
HAVING COUNT(DISTINCT m.id_student) > 34;

-- 5. Дать оценки студентов специальности ВМ по всем проводимым предметам с
-- указанием группы, фамилии, предмета, даты. При отсутствии оценки заполнить
-- значениями NULL поля оценки
SELECT g.name, s.name, sb.name, l.date, m.mark
FROM "group" g
    JOIN lesson l ON g.id_group = l.id_group
    JOIN student s ON g.id_group = s.id_group
    JOIN subject sb ON l.id_subject = sb.id_subject
    LEFT JOIN mark m ON l.id_lesson = m.id_lesson AND s.id_student = m.id_student
WHERE g.name = 'ВМ';

-- 6. Всем студентам специальности ПС, получившим оценки меньшие 5
-- по предмету БД до 12.05, повысить эти оценки на 1 балл
BEGIN TRANSACTION;
savepoint after_increment;

UPDATE mark SET mark = mark + 1
WHERE id_mark IN
(SELECT m.id_mark FROM mark m
JOIN student s on s.id_student = m.id_student
JOIN "group" g on g.id_group = s.id_group
JOIN lesson l on l.id_lesson = m.id_lesson
JOIN subject sb on sb.id_subject = l.id_subject
WHERE sb.name = 'БД' AND l.date < '12.05.2019'
AND g.name = 'ПС' AND m.mark < 5);

ROLLBACK TO after_increment;

COMMIT;

-- 7. Добавить необходимые индексы
CREATE INDEX idx_lesson_date ON lesson(date);

CREATE INDEX idx_subject_name ON subject(name);