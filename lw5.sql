-- 1. Добавить внешние ключи.

ALTER TABLE booking
      ADD CONSTRAINT booking_client_id_client_fk FOREIGN KEY (id_client)
          REFERENCES client (id_client);

ALTER TABLE room_in_booking
      ADD CONSTRAINT room_in_booking_booking_id_booking_fk FOREIGN KEY (id_booking)
          REFERENCES booking (id_booking);

ALTER TABLE room_in_booking
      ADD CONSTRAINT room_in_booking_room_id_room_fk FOREIGN KEY (id_room)
          REFERENCES room (id_room);

ALTER TABLE room
      ADD CONSTRAINT room_room_category_id_room_category_fk FOREIGN KEY (id_room_category)
          REFERENCES room_category (id_room_category);

ALTER TABLE room
      ADD CONSTRAINT room_hotel_id_hotel_fk FOREIGN KEY (id_hotel)
          REFERENCES hotel (id_hotel);

-- 2. Выдать информацию о клиентах гостиницы “Космос ”, проживающих в номерах
-- категории “Люкс” на 1 апреля 2019г.

SELECT client.id_client, client.name, client.phone FROM client
LEFT JOIN booking ON client.id_client = booking.id_client
LEFT JOIN room_in_booking   ON booking.id_booking = room_in_booking.id_booking
LEFT JOIN room ON room_in_booking.id_room = room.id_room
LEFT JOIN room_category ON room.id_room_category = room_category.id_room_category
WHERE room_in_booking.checkin_date <= '01-04-2019' AND room_in_booking.checkout_date > '01-04-2019'
AND room.id_hotel = 1 AND room_category.name = 'Люкс';

-- 3. Дать список свободных номеров всех гостиниц на 22 апреля.

SELECT room.number, room.id_hotel FROM room WHERE room.id_room NOT IN
(SELECT id_room FROM room_in_booking
WHERE room_in_booking.checkin_date <= '22-04-2019'
AND room_in_booking.checkout_date > '22-04-2019');

-- 4. Дать количество проживающих в гостинице “Космос” на 23 марта по
-- каждой категории номеров

SELECT COUNT(booking.id_client) AS "Count of clients", room.id_room_category FROM booking
LEFT JOIN room_in_booking ON booking.id_booking = room_in_booking.id_booking
LEFT JOIN room ON room_in_booking.id_room = room.id_room
WHERE room.id_hotel = 1 AND room_in_booking.checkin_date <= '23-03-2019'
AND room_in_booking.checkout_date > '23-03-2019'
GROUP BY room.id_room_category;

-- 5. Дать список последних проживавших клиентов по всем комнатам
-- гостиницы “Космос”, выехавшим в апреле с указанием даты выезда

-- крайний срок выезда из каждой комнаты ОТЕЛЯ КОСМОС в апреле(временнная таблица)
CREATE TEMP TABLE temp_tab AS (SELECT MAX(room_in_booking.checkout_date) AS last_checkout_date,
room_in_booking.id_room FROM room_in_booking
LEFT JOIN booking ON room_in_booking.id_booking = booking.id_booking
WHERE room_in_booking.id_room IN (SELECT id_room FROM room WHERE id_hotel = 1) AND
room_in_booking.checkin_date >= '1-04-2019' AND room_in_booking.checkout_date <= '30-04-2019'
GROUP BY room_in_booking.id_room
ORDER BY room_in_booking.id_room);

-- конечный запрос
SELECT c.name,tt.last_checkout_date, tt.id_room
FROM temp_tab tt
LEFT JOIN room_in_booking rib ON rib.checkout_date = tt.last_checkout_date
    AND rib.id_room = tt.id_room
LEFT JOIN booking b ON rib.id_booking = b.id_booking
LEFT JOIN client c ON b.id_client = c.id_client
ORDER BY tt.id_room;

-- 6.Продлить на 2 дня дату проживания в гостинице “Космос” всем клиентам
-- комнат категории “Бизнес”, которые заселились 10 мая.
UPDATE room_in_booking SET checkout_date = checkout_date + '2 days'::INTERVAL
WHERE checkout_date IN (SELECT checkout_date FROM room_in_booking rib
LEFT JOIN room r on rib.id_room = r.id_room
LEFT JOIN room_category rc on r.id_room_category = rc.id_room_category
LEFT JOIN hotel h on r.id_hotel = h.id_hotel
WHERE rib.checkin_date = '10-05-2019' AND rc.name = 'Бизнес' AND h.name = 'Космос');

-- 7. Найти все "пересекающиеся" варианты проживания. Правильное состояние: не может быть
-- забронирован один номер на одну дату несколько раз, т.к. нельзя заселиться нескольким
-- клиентам в один номер. Записи в таблице room_in_booking с id_room_in_booking = 5 и
-- 2154 являются примером неправильного состояния, которые необходимо найти.
-- Результирующий кортеж выборки должен содержать информацию о двух конфликтующих номерах.

SELECT * FROM room_in_booking rib1
INNER JOIN room_in_booking rib2 ON rib1.id_room = rib2.id_room
WHERE (rib1.checkin_date <= rib2.checkin_date
AND rib1.checkout_date > rib2.checkout_date)
OR (rib2.checkin_date <= rib1.checkin_date
AND rib2.checkout_date > rib1.checkout_date)
AND rib1.id_room_in_booking != rib2.id_room_in_booking;

-- 8. Создать бронирование в транзакции.

BEGIN;
SAVEPOINT start_point;

INSERT INTO booking (id_client, booking_date)
VALUES (11, current_date + 1);

INSERT INTO room_in_booking (id_booking, id_room, checkin_date, checkout_date)
VALUES ((SELECT booking.id_booking FROM booking ORDER BY 1 DESC LIMIT 1), 7,
    current_date + 1, current_date + 6);

--ROLLBACK TO start_point;
COMMIT;

-- 9. Добавить необходимые индексы для всех таблиц

CREATE INDEX idx_hotel_stars
ON hotel (stars);

CREATE INDEX idx_room_category
ON room (id_room_category);

CREATE INDEX idx_room_price
ON room (price);

CREATE INDEX idx_id_hotel
ON room (id_hotel);

CREATE INDEX idx_room_in_booking_room_id
ON room_in_booking (id_room);

CREATE INDEX idx_booking_id_client
ON booking (id_client);