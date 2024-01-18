
--HW-4_-----04.08.23
-- Агрегирующие функции
--1. Вывести:
--a. имя и фамилию пассажира
--b. идентификаторы всех его перелётов
--c. класс бронирования
--d. стоимость каждого перелёта
--e. минимальную, максимальную, среднюю и суммарную
--стоимость билетов пассажира с именем ADELINA
-----ANTONOVA

SELECT
    t.passenger_name AS full_name,
    tf.flight_id,
    tf.fare_conditions AS booking_class,
    tf.amount AS flight_cost,
    MIN(tf.amount) AS min_cost,
    MAX(tf.amount) AS max_cost,
    AVG(tf.amount) AS avg_cost,
    SUM(tf.amount) AS total_cost
FROM
    tickets t
JOIN
    ticket_flights tf ON t.ticket_no = tf.ticket_no
WHERE
    t.passenger_name = 'ADELINA ANTONOVA'
GROUP BY
    t.passenger_name, tf.flight_id, tf.fare_conditions, tf.amount

--2. Вывести аналогичные данные по всем пассажирам с именем  ADELINA
--3. Вывести аналогичные данные по всем пассажирам с именем
--ADELINA с учётом класса бронирования 
SELECT
    t.passenger_name AS full_name,
    tf.flight_id,
    tf.fare_conditions AS booking_class,
    tf.amount AS flight_cost,
    MIN(tf.amount) AS min_cost,
    MAX(tf.amount) AS max_cost,
    AVG(tf.amount) AS avg_cost,
    SUM(tf.amount) AS total_cost
FROM
    tickets t
JOIN
    ticket_flights tf ON t.ticket_no = tf.ticket_no
WHERE
    t.passenger_name LIKE 'ADELINA%'
GROUP BY
    t.passenger_name, tf.flight_id, tf.fare_conditions, tf.amount
    
--Нарастающий итог
--1. Вывести по каждому пассажиру:
--a. Имя и фамилию
--b. Дату отправления
--c. Время отправления
--d. Класс бронирования
--e. Сумму перелёта
--f. Текущую сумму перелётов нарастающим итогом начиная от
--самого раннего перелёта
--g. Общую сумму перелётов
    
 SELECT
    t.passenger_name AS full_name,
    f.scheduled_departure AS departure_date,
    f.scheduled_departure::TIME AS departure_time,
    tf.fare_conditions AS booking_class,
    tf.amount AS flight_cost,
    SUM(tf.amount) OVER (PARTITION BY t.passenger_name ORDER BY f.scheduled_departure) AS cumulative_flight_cost,
    SUM(tf.amount) OVER (PARTITION BY t.passenger_name) AS total_flight_cost
FROM
    tickets t
JOIN
    ticket_flights tf ON t.ticket_no = tf.ticket_no
JOIN
    flights f ON tf.flight_id = f.flight_id
WHERE
    t.passenger_name LIKE 'ADELINA%'
ORDER BY
    t.passenger_name, f.scheduled_departure
    
--Функции ранжирования
--1. Вывести данные о первом полёте каждой модели самолёта:
--a. Название модели самолёта на английском языке
--b. Дата и время первого полёта самолёта
SELECT
    aircraft_code AS model,
    MIN(scheduled_departure) AS first_flight_date
FROM
    flights
GROUP BY
    aircraft_code

--2. Вывести аналогичные данные о крайнем полёте каждой модели
--самолёта
SELECT
    aircraft_code AS model,
    MAX(scheduled_departure) AS last_flight_date
FROM
    flights
GROUP BY
    aircraft_code
    
--3. Составим рейтинг моделей самолётов по количеству перелётов.
--Вывести:
--a. Название модели самолёта на английском языке
--b. Общее количество перелётов данной модели самолёта
--c. Рейтинг модели самолёта по количеству перелётов
SELECT
    model,
    flight_count,
    RANK() OVER (ORDER BY flight_count DESC) AS flight_rank
FROM (
    SELECT
        aircraft_code AS model,
        COUNT(*) AS flight_count
    FROM
        flights
    GROUP BY
        aircraft_code
) AS subquery

--Функции смещения
--Построим таблицу для моделей самолёта с использованием оконных
--функций смещения:
--1. Наименование модели самолёта на русском языке
--2. Номер первого полёта + Дата первого полёта в одной колонке
--3. Номер предыдущего полёта + Дата предыдущего полёта в одной
--колонке
--4. Номер текущего полёта + Дата текущего полёта в одной колонке
--5. Номер следующего полёта + Дата следующего полёта в одной
--колонке
--6. Номер крайнего полёта + Дата первого крайнего в одной колонке
SELECT
    aircrafts_data.aircraft_code AS model_code,
    aircrafts_data.model->>'ru' AS model_name_ru,
    CONCAT(flights.flight_id, ' - ', flights.scheduled_departure::DATE) AS first_flight,
    CONCAT(LEAD(flights.flight_id) OVER (PARTITION BY flights.aircraft_code 
    ORDER BY flights.scheduled_departure),' - ', LEAD(flights.scheduled_departure)
    OVER (PARTITION BY flights.aircraft_code 
    ORDER BY flights.scheduled_departure)::DATE) AS next_flight,
    CONCAT(LAG(flights.flight_id) OVER (PARTITION BY flights.aircraft_code 
    ORDER BY flights.scheduled_departure), ' - ', LAG(flights.scheduled_departure) OVER (PARTITION BY flights.aircraft_code 
    ORDER BY flights.scheduled_departure)::DATE) AS prev_flight,
    CONCAT(LAST_VALUE(flights.flight_id) OVER (PARTITION BY flights.aircraft_code
    ORDER BY flights.scheduled_departure), ' - ', LAST_VALUE(flights.scheduled_departure) OVER (PARTITION BY flights.aircraft_code
    ORDER BY flights.scheduled_departure)::DATE) AS last_flight
FROM
    flights
JOIN
    aircrafts_data ON flights.aircraft_code = aircrafts_data.aircraft_code
    
--Построим маршрут перелётов для всех пассажиров, у которых имя
--начинается на «A», а фамилия «POPOVA»:
--1. Имя и фамилия пассажира
--2. Дата предыдущего вылета и аэропорт вылета (в одной колонке)
--3. Дата вылета и аэропорт вылета (в одной колонке)
--4. Дата следующего вылета и аэропорт вылета (в одной колонке)
WITH PassengerFlights AS (
    SELECT
        t.passenger_name AS full_name,
        f.scheduled_departure AS departure_date,
        CONCAT(ad_airport.airport_name, ' (', ad_airport.city, ')') AS departure_airport,
        LAG(f.scheduled_departure) OVER (PARTITION BY t.passenger_name 
        ORDER BY f.scheduled_departure) AS prev_departure_date,
        CONCAT(LAG(ad_airport.airport_name) OVER (PARTITION BY t.passenger_name
        ORDER BY f.scheduled_departure), ' (', LAG(ad_airport.city) OVER (PARTITION BY t.passenger_name 
        ORDER BY f.scheduled_departure), ')') AS prev_departure_airport,
        LEAD(f.scheduled_departure) OVER (PARTITION BY t.passenger_name 
        ORDER BY f.scheduled_departure) AS next_departure_date,
        CONCAT(LEAD(ad_airport.airport_name) OVER (PARTITION BY t.passenger_name 
        ORDER BY f.scheduled_departure), ' (', LEAD(ad_airport.city) OVER (PARTITION BY t.passenger_name
        ORDER BY f.scheduled_departure), ')') AS next_departure_airport
    FROM
        tickets t
    JOIN
        ticket_flights tf ON t.ticket_no = tf.ticket_no
    JOIN
        flights f ON tf.flight_id = f.flight_id
    JOIN
        airports_data ad_airport ON f.departure_airport = ad_airport.airport_code
    WHERE
        t.passenger_name LIKE 'A%' AND t.passenger_name LIKE '%POPOVA'
)
SELECT
    full_name,
    departure_date::DATE || ' - ' || departure_airport AS current_flight,
    next_departure_date::DATE || ' - ' || next_departure_airport AS next_flight,
    prev_departure_date::DATE || ' - ' || prev_departure_airport AS prev_flight
FROM
    PassengerFlights






  

