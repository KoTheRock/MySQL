USE lesson_4;

/*
    Задание 1. Создайте таблицу users_old, аналогичную таблице users. 
    Создайте процедуру, с помощью которой можно переместить любого (одного) пользователя из таблицы users в таблицу users_old. 
    (использование транзакции с выбором commit или rollback – обязательно).
*/

DROP TABLE IF EXISTS users_old;
CREATE TABLE IF NOT EXISTS users_old (
    id INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    email VARCHAR(120)
);

DROP PROCEDURE IF EXISTS moving_user;

DELIMITER //

CREATE PROCEDURE moving_user(IN user_id_to_moving INT)
BEGIN
    START TRANSACTION;
    
    -- Шаг 1. Проверка, существует ли пользователь в таблице users
    IF EXISTS (
        SELECT 1 FROM users WHERE id = user_id_to_moving
    ) THEN
        -- Запись user'a в users_old
        INSERT INTO users_old (id, firstname, lastname, email)
        SELECT id, firstname, lastname, email
        FROM users
        WHERE id = user_id_to_moving;

	-- Шаг 2. Удаление записи за таблицы users. (Если мы говорим о перемещении то при этом действии она должна поиявиться в новой таблице и проспасть из старой, верно?)
		delete from users where id = user_id_to_moving;

	-- Шаг 3. Проверка, успешно ли прошла запись в users_old
	IF ROW_COUNT() > 0
          THEN
            COMMIT;
            SELECT 'Пользователь успешно перемещен в users_old, изменения сохранены' AS message;
        ELSE
            ROLLBACK;
            SELECT 'Ошибка: Пользователь не был удален из users, откат транзакции' AS message;
        END IF;
    ELSE
        ROLLBACK;
        SELECT 'Ошибка: Пользователь с данным ID не найден в таблице users' AS message;
    END IF;

END //
DELIMITER ;

CALL moving_user(6);

/*
    Задание 2. Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. 
    С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", 
    с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
    с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".
*/

DELIMITER //

CREATE FUNCTION hello() 
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE greeting VARCHAR(50);
    DECLARE current_time TIME;
    
    SET current_time = CURTIME();
    
    SET greeting = CASE
		WHEN current_time BETWEEN '06:00:00' AND '11:59:59' THEN 'Доброе утро'
		WHEN current_time BETWEEN '12:00:00' AND '17:59:59' THEN 'Добрый день'
        WHEN current_time BETWEEN '18:00:00' AND '23:59:59' THEN 'Добрый вечер'
		ELSE 'Доброй ночи'
	END;
    RETURN greeting;

END //

DELIMITER ;

SELECT hello();


/*
    Задание 3. (по желанию)* Создайте таблицу logs типа Archive. 
    Пусть при каждом создании записи в таблицах users, communities и messages 
    в таблицу logs помещается время и дата создания записи, название таблицы, идентификатор первичного ключа."!
*/

  CREATE TABLE logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50),
    record_id INT
) ENGINE=ARCHIVE;

DELIMITER //
 
CREATE TRIGGER after_users_insert		-- Тригер для users
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO logs (table_name, record_id)
    VALUES ('users', NEW.user_id);
END;

CREATE TRIGGER after_communities_insert			-- Тригер для communities
AFTER INSERT ON communities
FOR EACH ROW
BEGIN
    INSERT INTO logs (table_name, record_id)
    VALUES ('communities', NEW.community_id);
END;

CREATE TRIGGER after_messages_insert		-- Тригер для messages
AFTER INSERT ON messages
FOR EACH ROW
BEGIN
    INSERT INTO logs (table_name, record_id)
    VALUES ('messages', NEW.message_id);
END;

DELIMITER ;


    


