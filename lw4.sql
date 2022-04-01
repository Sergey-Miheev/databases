
-- 3.1 INSERT
-- a. Без указания списка полей
INSERT INTO company VALUES (default, 'Ambrella', 'Yoshkar-Ola, Palm str, 56', 552);
-- b. С указанием списка полей
INSERT INTO employee (name, salary)
VALUES ('Kirill Bebrilov', 300);
-- c. С чтением данных из другой таблицы
INSERT INTO company (staff) SELECT staff FROM department;

-- 3.2 DELETE
-- a. Всех записей
DELETE FROM trash;
-- b. По условию
DELETE FROM company WHERE id_company > 4;

-- 3.3 UPDATE
-- a. Всех записей
UPDATE employee SET salary=110;
-- b. По условию обновляя один атрибут
UPDATE employee SET salary = 300 WHERE salary = 110;
-- c. По условию обновляя несколько атрибутов
UPDATE department SET staff = 111, name = 'Attack' where id_company = 4;

-- 3.4 SELECT
-- a. С набором извлекаемых атрибутов
SELECT name, salary FROM employee;
-- b. Со всеми атрибутами
SELECT * FROM  post;
-- c. С условием по атрибуту
SELECT * FROM employee WHERE phone_number IS NULL;

-- 3.5 SELECT ORDER BY + TOP (LIMIT)
-- a. С сортировкой по возрастанию ASC + ограничение вывода количества записей
SELECT * FROM employee
ORDER BY salary ASC LIMIT 3;
-- b. С сортировкой по убыванию DESC
SELECT * FROM company
ORDER BY staff DESC;
-- c. С сортировкой по двум атрибутам + ограничение вывода количества записей
-- В этом случае сначала строки сортируются по первому столбцу по возрастанию.
-- Затем если есть строки, в которых первый столбец имеет одинаковое значение,
-- то они сортируются по второму столбцу также по возрастанию.
-- Но с помощью ASC и DESC можно отдельно для разных столбцов определить сортировку:
SELECT * FROM employee
ORDER BY name, salary LIMIT 4;
-- d. С сортировкой по первому атрибуту, из списка извлекаемых
SELECT salary, phone_number FROM employee
ORDER BY 1;

-- 3.6. Работа с датами
-- a. WHERE по дате
SELECT * FROM employee
WHERE date_birth > '1991.11.15 12:41:00';
-- b. WHERE дата в диапазоне
SELECT * FROM employee
WHERE date_birth <= '1991-11-15' AND date_birth >= '1930-1-2';
-- c. Извлечь из таблицы не всю дату, а только год
-- SELECT extract(year from date_birth) from employee;
SELECT date_part('year', date_birth) FROM employee;

-- 3.7 Функции агрегации
-- a. Посчитать количество записей в таблице
SELECT COUNT(*) FROM post;
-- b. Посчитать количество уникальных записей в таблице
SELECT DISTINCT COUNT(*) FROM participation_in_project;
-- c. Вывести уникальные значения столбца
SELECT DISTINCT staff FROM department;
-- d. Найти максимальное значение столбца
SELECT MAX(staff) FROM company;
-- e. Найти минимальное значение столбца
SELECT MIN(staff) FROM company;
-- f. Написать запрос COUNT() + GROUP BY
SELECT COUNT(id_company) AS count_company, address FROM company
GROUP BY address;

-- 3.8 SELECT GROUP BY + HAVING
-- a. Количество компаний, находящихся в Йошкар-Оле
SELECT COUNT(id_company) AS count_company, address FROM company
GROUP BY address HAVING COUNT(id_company) > 1;
-- b. Максимальное количество сотрудников среди отделов компаний с id > 2
-- err
SELECT MAX(staff) AS max_num_employees, id_company FROM department
GROUP BY id_company HAVING MAX(STAFF) > 12;
-- с. Сумма зарплаты сотрудников у которых нет номеров телефонов
-- err
SELECT SUM(salary) AS sum_salary, phone_number FROM employee
GROUP BY phone_number HAVING SUM(salary) > 300;

-- 3.9 SELECT JOIN
-- a. LEFT JOIN двух таблиц и WHERE по одному из атрибутов
SELECT * FROM post
LEFT JOIN participation_in_project ON post.id_post = participation_in_project.id_post
WHERE post.id_post = 4;
-- b. RIGHT JOIN. Получить такую же выборку, как и в 3.9(a)
--err
SELECT * FROM participation_in_project
RIGHT JOIN post ON post.id_post = participation_in_project.id_post
WHERE post.id_post = 4;
-- c. LEFT JOIN трех таблиц + WHERE по атрибуту из каждой таблицы
SELECT department.id_department, department.name, department.staff FROM department
LEFT JOIN belong_to ON department.id_department = belong_to.id_department
LEFT JOIN employee
ON employee.id_employee = belong_to.id_employee
LEFT JOIN participation_in_project
ON employee.id_employee = participation_in_project.id_employee
WHERE belong_to.id_employee > 2 AND employee.phone_number IS NOT NULL
AND participation_in_project.id_post IS NOT NULL;
-- d. INNER JOIN двух таблиц
SELECT participation_in_project.id_employee, post.id_post, participation_in_project.id_project
FROM participation_in_project
INNER JOIN post ON participation_in_project.id_post = post.id_post;

-- 3.10 Подзапросы
-- a. Написать запрос с условием WHERE IN (подзапрос)
SELECT id_department, name, id_company FROM department WHERE id_company
IN (SELECT company.id_company FROM company WHERE company.address = 'Yoshkar-Ola');
-- b. Написать запрос SELECT atr1, atr2, (подзапрос) FROM
SELECT id_department, name, (SELECT id_company WHERE staff > 20) FROM department;
-- c. Написать запрос вида SELECT * FROM (подзапрос )
SELECT * FROM (SELECT name FROM employee WHERE phone_number IS NULL) AS employee_name;
-- d. Написать запрос вида SELECT * FROM table JOIN (подзапрос ) ON
SELECT * FROM post JOIN
(SELECT id_employee FROM participation_in_project WHERE id_post = 3) AS id_department
ON post.id_post = 3;
