-- 1. Добавить внешние ключи.
ALTER TABLE production
    ADD CONSTRAINT production_company_id_company FOREIGN KEY (id_company)
    REFERENCES company(id_company);

ALTER TABLE production
    ADD CONSTRAINT production_medicine_id_medicine FOREIGN KEY (id_medicine)
    REFERENCES medicine(id_medicine);

ALTER TABLE dealer
    ADD CONSTRAINT dealer_company_id_company FOREIGN KEY (id_company)
    REFERENCES company(id_company);

ALTER TABLE "order"
    ADD CONSTRAINT order_dealer_id_dealer FOREIGN KEY (id_dealer)
    REFERENCES dealer(id_dealer);

ALTER TABLE "order"
    ADD CONSTRAINT order_pharmacy_id_pharmacy FOREIGN KEY (id_pharmacy)
    REFERENCES pharmacy(id_pharmacy);

-- 2. Выдать информацию по всем заказам лекарства “Кордеон” компании “Аргус” с
-- указанием названий аптек, дат, объема заказов.
SELECT o.id_order, o.id_production, o.id_dealer, p2.name, o.date, o.quantity FROM "order" o
JOIN dealer d on o.id_dealer = d.id_dealer
JOIN company c on d.id_company = c.id_company
JOIN production p on o.id_production = p.id_production
JOIN medicine m on p.id_medicine = m.id_medicine
JOIN pharmacy p2 on o.id_pharmacy = p2.id_pharmacy
WHERE c.name = 'Аргус' AND m.name = 'Кордеон';

-- 3. Дать список лекарств компании “Фарма”, на которые не были сделаны заказы
-- до 25 января.

SELECT m.name FROM medicine m
LEFT JOIN production p2 on m.id_medicine = p2.id_medicine
LEFT JOIN company c on p2.id_company = c.id_company
WHERE m.name NOT IN (SELECT DISTINCT m2.name FROM medicine m2
    LEFT JOIN production p on m2.id_medicine = p.id_medicine
    LEFT JOIN "order" o on p.id_production = o.id_production
    LEFT JOIN company c on p.id_company = c.id_company
    WHERE o.date < '25-01-2019' AND c.name = 'Фарма')
AND c.name = 'Фарма';

-- 4. Дать минимальный и максимальный баллы лекарств каждой фирмы, которая
-- оформила не менее 120 заказов
CREATE TEMP TABLE count_orders AS (SELECT c2.name, COUNT(o.id_order) count_orders FROM company c2
JOIN dealer d on c2.id_company = d.id_company
JOIN "order" o ON d.id_dealer = o.id_dealer
GROUP BY c2.name HAVING COUNT(o.id_order) >= 120);

SELECT c.name, MAX(p.rating), MIN(p.rating) FROM production p
JOIN company c on c.id_company = p.id_company
WHERE c.name IN (SELECT co.name FROM count_orders co)
GROUP BY c.name;

-- 5. Дать списки сделавших заказы аптек по всем дилерам компании
-- "AstraZeneca". Если у дилера нет заказов, в названии аптеки проставить NULL.
SELECT DISTINCT p.name, d.name FROM pharmacy p
JOIN "order" o ON p.id_pharmacy = o.id_pharmacy
RIGHT JOIN dealer d ON o.id_dealer = d.id_dealer
JOIN company c on d.id_company = c.id_company
WHERE c.name = 'AstraZeneca';

-- 6. Уменьшить на 20% стоимость всех лекарств, если она превышает 3000, а
-- длительность лечения не более 7 дней.
UPDATE production SET price = price * 0.8
WHERE production.price > '3000' AND production.id_medicine IN
(SELECT medicine.id_medicine FROM medicine WHERE cure_duration <= 7);

-- 7. Добавить необходимые индексы.
CREATE INDEX idx_production_price ON production(price);

CREATE INDEX idx_production_rating ON production(rating);