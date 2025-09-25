### 数据类型

- String
  - CHAR(X) 固定长度
  - VARCHAR(X : 65535 64KB) 可变长度
  - MEDIUMTEXT max : 16MB
  - LONGTEXT max : 4 GB
  - TINYTEXT max: 255 bytes
  - TEXT max : 64KB
- INTEGERS
  - TINYINT  1b [-128 - 127]
  - UNSIGNED TINYINT [0 - 255]
  - SMALLINT  2b [-32K - 32K]
  - MEDIUMINT  3b[-8M - 8M]
  - INT  4b [-2B - 2B]
  - BIGINT  8b [-9Z - 9Z]
- RATIONAL
  - DECIMAL(p, s)
  - DEC
  - NUMERIC
  - FIXED
  - FLOAT
  - DOUBLE
- BOOLEANS
  - BOOL
  - BOOLEAN
- ENUMS
  - ENUM
  - SET
- DATE/TIME
  - DATE
  - TIME
  - DATETIME
  - TIMESTAMP
  - YEAR
- BLOBS
  - TINYBLOB  255b
  - BLOB  65KB
  - MEDIUMBLOB  16MB
  - LONGBLOB  4GB
- JSON


```mysql
UPDATE products
SET properties = '
{
    "dimensions": [1, 2, 3],
    "weight": 10,
    "manufacturer": { "name": "sony" }
}' -- 最好是" "
WHERE product_id = 1;


-- 下面用json函数去设置
UPDATE products
SET properties = JSON_OBJECT(
    'weight', 10,
    'dimensions', JSON_ARRAY(1, 2, 3),
    'manufacturer', JSON_OBJECT('name', 'sony')
)
WHERE product_id = 1;

-- 用JSON_SET去设置修改
UPDATE products
SET properties = JSON_SET(
    properties,
    '$.weight', 20,
    '$.age', 10
)
WHERE product_id = 1;

-- 删除某个属性
UPDATE products
SET properties = JSON_REMOVE(
    properties,
    '$.age'
)
WHERE product_id = 1;

-- 查询json中的一个值
SELECT product_id, JSON_EXTRACT(properties, '$.weight')
FROM products
WHERE product_id = 1;

-- 列路径运算符 ->
SELECT product_id, properties -> '$.weight'
FROM products
WHERE product_id = 1;

SELECT product_id, properties -> '$.weight'
FROM products
WHERE product_id = 1;

SELECT product_id, properties ->> '$.manufacturer.name' -- >>可去掉返回的"", ->一个会返回"sonny"
FROM products
WHERE product_id = 1;
```



### UNION

```mysql
SELECT 
	customer_id,
    first_name,
    points,
    'BRONZE' AS type
    
FROM customers    
WHERE points < 2000 

UNION

SELECT 
	customer_id,
    first_name,
    points,
    'SILVER'
    
FROM customers    
WHERE points >= 2000 AND points < 3000

UNION

SELECT 
	customer_id,
    first_name,
    points,
    'GOLD'
    
FROM customers    
WHERE points >= 3000

ORDER BY first_name
```



### 选择语句

```mysql
SELECT 
    customer_id,
    first_name,
    points,
    IF(points < 2000, 'BRONZE',
       IF(points BETWEEN 2000 AND 3000, 'SILVER',
          IF(points >= 3000, 'GOLD', ''))) AS type
FROM customers
ORDER BY first_name;


SELECT 
    customer_id,
    first_name,
    points,
    CASE
        WHEN points < 2000 THEN 'BRONZE'
        WHEN points BETWEEN 2000 AND 3000 THEN 'SILVER'
        WHEN points >= 3000 THEN 'GOLD'
    END AS type
FROM customers
ORDER BY first_name;
```



### 聚合函数

 GROUP BY可以用SELECT中的别名，但是如果用来`ROLLUP`, 就不能用别名

用了GROUP BY，里面一定要用到上面给的SELECT，或者加到聚合函数里面

```mysql
SELECT 
    p.date,
    pm.name,
    SUM(p.amount) AS total_payments
FROM payments p
JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id
GROUP BY p.date, pm.name;


SELECT 
    p.date,
    MIN(pm.name) AS payment_method_name,
    SUM(p.amount) AS total_payments
FROM payments p
JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id
GROUP BY p.date;
```



### 子查询

#### WHERE

```mysql
-- 用子查询去做
SELECT *
FROM invoices i
WHERE invoice_total > (
	SELECT AVG(invoice_total)
    FROM invoices
    WHERE client_id = i.client_id
)

-- 建新表做查询，可避免每次查询是都做一次子查询计算
-- 如果想要选择头表，可以用i1.* 这个选用i1的全部头像
SELECT *
FROM invoices i1
JOIN (
	SELECT 
		client_id,
        AVG(invoice_total) AS avg
    FROM invoices
    GROUP BY client_id
) i2
ON i1.invoice_total > i2.avg
WHERE i1.client_id = i2.client_id
```



##### WHERE-EXIST

```mysql
-- EXIST在查询的时候，查询到了就直接返回，不会像IN全部做完才返回全部值列表，提升了一定性能
SELECT *
FROM clients c
WHERE EXISTS (
    SELECT 1
    FROM invoices i
    WHERE i.client_id = c.client_id
);


SELECT *
FROM clients c
WHERE c.client_id IN (
    SELECT client_id
    FROM invoices
);
```



#### SELECT

```mysql
SELECT
    client_id,
    name,
    (
        SELECT SUM(invoice_total)
        FROM invoices
        WHERE client_id = c.client_id
    ) AS total_sales,
    (
        SELECT AVG(invoice_total) FROM invoices
    ) AS average,
    (
        SELECT total_sales - average
    ) AS difference
FROM clients c
```



#### FROM

```mysql
SELECT *
FROM(
    SELECT
        client_id,
        name,
        (
            SELECT SUM(invoice_total)
            FROM invoices
            WHERE client_id = c.client_id
        ) AS total_sales,
        (
            SELECT AVG(invoice_total) FROM invoices
        ) AS average,
        (
            SELECT total_sales - average
        ) AS difference
    FROM clients c
) AS salary_total
WHERE total_sales IS NOT NULL
```



### 函数

#### 数值函数

```mysql
ROUND(5.7245, 1)
ROUND(5.7245, 2)
TRUNCATE(5.7245, 2) -- 截断，直接删去
CEILING(5.7245, 2)
FLOOR(5.7245, 2)
ABS(5.7245)
RAND() -- 0 - 1
-- MYSQL NUMERIC FUNCTION
```

#### 字符串函数

```mysql
UPPER('sky')
LOWER('SKY')
LTRIM('   SKY')
RTRIM('SKY   ')
TRIM(' SKY  ')
LEFT('KINGDOM', 4) -- 返回左侧前4个
RIGHT('KINGDOM', 4) -- 返回右侧的
SUBSTRING('KINGDOM', 3, 4) -- 位置， 长度
LOCATE('LINER', 'LINGER')
REPLACE('RAINAR', 'AR', 'ER') -- 'AR'变'ER
CONCATE('FIRST', 'CASE') -- 结合,中间可以放多个
```

#### 日期函数

```mysql
NOW()
CURDATE()
CURTIME()
YEAR()
YEAR(NOW())
-- MONTH, DAYNAME ... ...
EXTRACT(YEAR FROM NOW())
DATE_FORMAT(NOW(), '%M %d %Y %H %i %p') -- 小写y是2位，Y是4位
```

#### 日期计算

```mysql
SELECT DATE_ADD(now(), interval 1 day/month/year)
SELECT DATE_SUB(now(), interval)
SELECT DATEDIFF(now(), '2025-09-18')
SELECT TIME_TO_SEC('09:00') -- 转为s

```



#### IFNULL && COALESCE

```mysql
USE sql_store;

SELECT
    order_id,
    IFNULL(shipper_id, '...'), -- 判断是否为空
    COALESCE(shipper_id, comments, 'Not assigned') AS assignment_status -- 返回列表里面第一个非 `null` 值
FROM orders;
```



### DATABASE

```mysql
CREATE DATABASE IF NOT EXISTS sql_store2;
USE sql_store2;
```



### 表

#### INSERT

```mysql
INSERT INTO table_name (column1, column2, column3, ...)
VALUES (value1, value2, value3, ...);

-- 插入特定列的值
INSERT INTO employees (first_name, last_name, department)
VALUES ('John', 'Doe', 'Sales');

-- 插入所有列的值（必须指定所有列）
INSERT INTO employees
VALUES (1, 'John', 'Doe', 'Sales');
```



#### CREATE

```mysql
CREATE TABLE table_name (
    column1 datatype [constraint],
    column2 datatype [constraint],
    column3 datatype [constraint],
    ...
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,  -- 设置为主键
    first_name VARCHAR(50) NOT NULL, -- 约束条件，非空
    -- first_name VARCHAR(50) CHARACTER SET latin1 NOT NULL, -- 修改字符集，如果想要全部都是这个字符集，写在create 															     db 后面即可
    last_name VARCHAR(50) NOT NULL,  -- 约束条件，非空
    department VARCHAR(50) DEFAULT 'General', -- 设置默认值
    INDEX idx_department (department), -- 添加索引
    salary DECIMAL(10, 2) CHECK (salary >= 0), -- 约束条件
    hire_date DATE
);

```

```mysql
CREATE DATABASE IF NOT EXISTS sql_store2;
USE sql_store2;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
CREATE TABLE IF NOT EXISTS customers(
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    points INT NOT NULL DEFAULT 0,
    email VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE orders(
	order_id INT PRIMARY KEY,
	customer_id INT NOT NULL,
-- 	FOREIGN KEY fk_orders_customer (customer_id)
-- 		REFERENCES customers(customer_id)
--         ON UPDATE CASCADE
--         ON DELETE NO ACTION
	CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)  -- 外键需要这样写才能这种命名，上面的写法会导致系统自动                                                                 命名
			REFERENCES customers(customer_id)
);
```



#### DELETE

```mysql
DELETE FROM table_name
WHERE condition;

-- 删除特定行
DELETE FROM employees
WHERE employee_id = 5;

-- 基于某些条件删除多行
DELETE FROM employees
WHERE department = 'Sales' AND salary < 50000;
```

#### UPDATE

```mysql
UPDATE table_name
SET column1 = value1, column2 = value2, ...
WHERE condition;

-- 更新特定行
UPDATE employees
SET department = 'Marketing'
WHERE employee_id = 5;

-- 基于某些条件更新多行
UPDATE employees
SET salary = salary * 1.1
WHERE department = 'IT';
```

#### SHOW

```mysql
-- 查看payments表的外键约束
SHOW CREATE TABLE payments;

-- 查看invoices表的结构
SHOW CREATE TABLE invoices;
```



#### ALTER

```mysql
ALTER TABLE customers;
    ADD last_name VARCHAR(50) NOT NULL AFTER fist_name,
    ADD city VARCHAR(50) NOT NULL,
    MODIFY COLUMN first_name VARCHAE(55) NOT NULL DEFAULT '', -- 最好别在生产库中修改，会造成不必要麻烦
    DROP points;


-- 在实际操作时，最好是drop和add分开，ALTER会在MYSQL里面自动优化处理，不一定是写的顺序执行，防止错误先drop在add
ALTER TABLE orders
	ADD PRIMARY KEY (order_id), -- 添加一个主键，如果名字存在就添加主键约束
    -- DROP PRIMARY KEY, -- 去掉主键约束，但不是删除
	DROP FOREIGN KEY fk_orders_customer,
    DROP INDEX fk_orders_customer; -- 添加键的时候会自动补一个index，所以drop时在index里也有去除
-- 	ADD FOREIGN KEY fk_orders_customer (customer_id) -- 这种写法不会按写的名字命名外键，会自动命名
-- 			REFERENCES customers(customer_id)
-- 			ON UPDATE CASCADE
-- 			ON DELETE NO ACTION
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_customer
	  FOREIGN KEY (customer_id)
	  REFERENCES customers(customer_id)
	  ON UPDATE CASCADE
	  ON DELETE NO ACTION;
;
SHOW CREATE TABLE orders;
```

```mysql
ALTER TABLE customer
ENGINE = InnoDB -- 设置存储引擎，注意每次设置都会重新建表，会影响性能
```



### 视图

#### View的建立

```mysql
CREATE VIEW clients_balance AS -- 创建的视图View是由Table实表所构建，按逻辑链接起来的
							   -- 所以只要实表改变，视图也会相应发生改变
SELECT 
	client_id,
    name,
    SUM(i.invoice_total - i.payment_total) AS clients_balance
    
FROM clients c
JOIN invoices i
	USING(client_id)
GROUP BY client_id
```

#### View的修改

```mysql
DROP VIEW ... -- 后面直接跟视图名字就可以直接删去

-- 在加一个replace可以替换，如果需要修改的话，通过这个可多次执行，不需要反复DROP在CREATE
CREATE OR REPLACE VIEW clients_balance AS
SELECT 
	client_id,
    name,
    SUM(i.invoice_total - i.payment_total) AS clients_balance
    
FROM clients c
JOIN invoices i
	USING(client_id)
GROUP BY client_id

```

```mysql
CREATE OR REPLACE VIEW invoices_with_balance AS
SELECT
    invoice_id,
    number,
    client_id,
    invoice_total,
    payment_total,
    invoice_total - payment_total AS balance,
    invoice_date,
    due_date,
    payment_date
FROM invoices
WHERE (invoice_total - payment_total) > 0
WITH CHECK OPTION -- 这个是用来检查，防止操作时错误可以看到报错


DELETE FROM invoices_with_balance
WHERE invoice_id = 1


UPDATE invoices_with_balance
SET due_date = DATE_ADD(due_date, INTERVAL 2 DAY)
WHERE invoice_id = 2; -- 注意！此时where的修改会直接同步到基础表
```

#### 基础概念

在 MySQL 里，视图本质上就是一条 `SELECT` 查询的“虚拟表”。
对视图做 `INSERT / UPDATE / DELETE` 时，`MySQL` 会把操作转发到它背后的基表。

但是！并不是所有视图都能修改。

------

#### 可更新视图的条件

一个视图可以修改（`updatable`），必须满足以下条件：

- 视图基于 **单个表**（不是多表 JOIN）
- 没有 `DISTINCT`
- 没有 `GROUP BY` 或 `HAVING`
- 没有 `UNION` 或 `UNION ALL`
- 没有聚合函数（如 `SUM()`、`COUNT()`）
- 没有 `LIMIT`
- 没有计算列（如 `price * quantity`）

只要视图定义简单，几乎等价于基表的子集，那就能修改。

------

#### 不能更新的视图（只读）

如果视图里用了 `JOIN`、`GROUP BY`、`DISTINCT` 这些复杂操作，`MySQL` 就不允许你修改。
这种情况下，它只能查询，不能改。

------

#### 强制只读视图

你还可以在定义时加上：

```sql
CREATE VIEW my_view AS
SELECT ...
WITH CHECK OPTION;
```

这样即使理论上能修改，也会限制只允许符合 `WHERE` 条件的数据被改。

------

#### 举例

##### 可修改的视图

```sql
CREATE VIEW v_customers AS
SELECT customer_id, first_name, last_name
FROM customers;
```

这时候你可以：

```sql
UPDATE v_customers
SET first_name = 'Tom'
WHERE customer_id = 1;
```

它会同步修改到 `customers` 表。

##### 不可修改的视图

```sql
CREATE VIEW v_sales AS
SELECT c.first_name, SUM(o.amount) AS total
FROM customers c
JOIN orders o USING (customer_id)
GROUP BY c.customer_id;
```

这个视图里有 `JOIN` + `SUM()`，所以只能查，不能改。



### PROCEDURE 

#### 无参数

```mysql
DELIMITER $$ -- 表示分隔符，当前用$$分割，就会把$$中间看作整体执行
CREATE PROCEDURE get_clients()
BEGIN
	SELECT *
    FROM clients;
END $$
DELIMITER ;

--

CALL get_clients() -- 通过call去使用，就相当于一个函数相应了

--

DELIMITER $$

DROP PROCEDURE IF EXISTS get_invoices_with_balance $$ -- 如果函数写错了可以删掉后重写，但是如果支持ALTER也可用

CREATE PROCEDURE get_invoices_with_balance()
BEGIN
	SELECT 
		*,
        (invoice_total - payment_total) AS balance
    FROM invoices
    WHERE (invoice_total - payment_total) > 0;
END $$
DELIMITER ;
```



#### 含参数

```mysql
DELIMITER $$

DROP PROCEDURE IF EXISTS get_invoices_by_clients $$

CREATE PROCEDURE get_invoices_by_clients(id INT) -- 注意，mysql这里添加参数是，参数类型后置
BEGIN
	SELECT *
    FROM invoices
    WHERE client_id = id;
END $$
DELIMITER ;
```



```mysql
DELIMITER $$

DROP PROCEDURE IF EXISTS get_payments $$
CREATE PROCEDURE get_payments (
	client_id INT,
    payment_method_id TINYINT
)
BEGIN
	SELECT *
    FROM payments p
	WHERE p.client_id = IFNULL(client_id, p.client_id) AND p.payment_method = IFNULL(payment_method_id, p.payment_method); -- 即使是ifnull，输入参数也要写一个null
END $$
DELIMITER ;
```

```mysql
DELIMITER $$
DROP PROCEDURE IF EXISTS make_payment $$

CREATE PROCEDURE make_payment(
	invoice_id INT,
    payment_amount DECIMAL(9, 2), -- 表示最大9位数，小数最多后两位
    payment_date DATE
)
BEGIN
	IF payment_amount <= 0 THEN
		SIGNAL SQLSTATE '22003'
			SET MESSAGE_TEXT = 'Invalid payment amount'; -- 用于放置报错信息
	END IF;
    
    UPDATE invoices i
    SET 
		i.payment_total = payment_amount,
        i.payment_date = payment_date
	WHERE i.invoice_id = invoice_id;
END $$
DELIMITER ;
```



#### 参数输出

```mysql
DELIMITER $$
DROP PROCEDURE IF EXISTS get_unpaied_invoice_by_clientid $$

CREATE PROCEDURE get_unpaied_invoice_by_clientid(
	cliend_id INT,
    OUT invoices_count INT,
    OUT invoices_total DECIMAL(9, 2)
)
BEGIN
	SELECT COUNT(*), SUM(invoice_total)
    INTO invoices_count, invoices_total
    FROM invoices i
    WHERE i.client_id = cliend_id
		AND payment_total = 0;
END $$
DELIMITER ;
```

```mysql
-- 用 @ 来当前缀去定义变量， 并用set去设置初始值
set @invoices_count = 0;
set @invoices_total = 0;
call sql_invoicing.get_unpaied_invoice_by_clientid(1, @invoices_count, @invoices_total);
select @invoices_count, @invoices_total;

```



#### 变量

```mysql
DELIMITER $$
DROP PROCEDURE IF EXISTS get_risk_factor $$

CREATE PROCEDURE get_risk_factor ()
BEGIN
    DECLARE risk_factor DECIMAL(9, 2) DEFAULT 0; -- 先申明变量，变量名 + 变量类型
    DECLARE invoices_total DECIMAL(9, 2);
    DECLARE invoices_count INT;

    SELECT COUNT(*), SUM(invoice_total)
    INTO invoices_count, invoices_total
    FROM invoices;

    SET risk_factor = invoices_total / invoices_count * 5;

    SELECT risk_factor;
END $$
DELIMITER ;
```



### FUNCTION

```mysql
CREATE DEFINER=`root`@`localhost` FUNCTION `get_risk_for_client`(
	client_id INT
) RETURNS int
	DETERMINISTIC -- 确定性，表示每次查询只要参数一致，返回值一致，不会因为表数据改变而改变
	CONTAINS SQL  -- 包含SQL语句，包含 动态 构造的 SQL 语句，这些语句可能在运行时才确定
    READS SQL DATA -- 只读取不修改
    MODIFIES SQL DATA  -- 会进行修改数据
    NO SQL  -- 不执行任何SQL语句，不访问也不修改数据库中的数据
BEGIN
	DECLARE risk_factor DECIMAL(9, 2) DEFAULT 0;
    DECLARE invoices_total DECIMAL(9, 2);
    DECLARE invoices_count INT;

    SELECT COUNT(*), SUM(invoice_total)
    INTO invoices_count, invoices_total
    FROM invoices i
    WHERE i.client_id = client_id;

    SET risk_factor = invoices_total / invoices_count * 5;
	RETURN IFNULL(risk_factor, 0);
END
```

```mysql
SELECT
	client_id,
    name,
    get_risk_for_client(client_id) AS risk
FROM clients
```

```mysql
DROP FUNCTION IF EXISTS get_risk_for_client
```



### 触发器

#### 编写

```mysql
DELIMITER $$
CREATE TRIGGER payments_after_insert
	AFTER INSERT ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total = NEW.amount + payment_total
    WHERE invoice_id = NEW.invoice_id;
END $$
DELIMITER ;
```

```mysql
DELIMITER $$
CREATE TRIGGER payments_after_delete
	AFTER DELETE ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total= payment_total - OLD.amount
    WHERE invoice_id = OLD.invoice_id;
END $$
DELIMITER ;

-- 注意，这里的触发器只是根据了invoice_id进行的判断修改，并且，payments这个表的外键是invoice_id, 并且invoice_id是invoices这个表的主键，修改是即使client_id不对，也只根据invoice_id去修改，这个由触发器里面决定，而这个主键以及外键约束条件决定是否插入修改成功（invoice_id是否存在决定）
-- 如果需要都修改正确，要么修改触发器条件，要么修改外键设计
-- 1.WHERE invoice_id = OLD.invoice_id AND client_id = OLD.client_id;
-- 2.把 invoices 的主键改成 (invoice_id, client_id) 或者建唯一键，再让 payments 外键同时依赖这两个字段
```



#### 查看

```mysql
SHOW TRIGGERS
SHOW TRIGGERS LIKE 'payments%'
```



#### 删除

```mysql
DELIMITER $$
DROP TRIGGER IF EXISTS payments_after_delete $$ -- 一般与创建写一块
CREATE TRIGGER payments_after_delete
	AFTER DELETE ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total= payment_total - OLD.amount
    WHERE invoice_id = OLD.invoice_id;
END $$
DELIMITER ;
```



### 审计表

```mysql
-- 主要用于记录每次的操作，可用一个大表记录，不然可能会有大量重复操作
DELIMITER $$
DROP TRIGGER IF EXISTS payments_after_insert $$
CREATE TRIGGER payments_after_insert
	AFTER INSERT ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total = NEW.amount + payment_total
    WHERE invoice_id = NEW.invoice_id;
    
    INSERT INTO payments_audit
    VALUE(NEW.client_id, NEW.date, NEW.amount, 'INSERT', NOW());
END $$
DELIMITER ;
```



### EVENT

```mysql
DELIMITER $$
DROP EVENT IF EXISTS yearly_delate_stable_audit_rows $$
CREATE EVENT yearly_delate_stable_audit_rows
ON SCHEDULE 
	-- AT '' -- 用于一次，某次时间进行一次
	EVERY 1 YEAR STARTS '2019-01-01' ENDS '2029-01-01' -- 周期性，开始时间与结束时间不是一定需要的
DO BEGIN
	DELETE FROM payments_audit
    WHERE action_date < NOW() - INTERVAL 1 YEAR;
END $$
DELIMITER ;

-- SHOW EVENT LIKE '%%'
-- ALTER EVENT yearly_delate_stable_audit_rows DISABLE/ENABLE -- 暂时的开启关闭
```



### TRANSACTION--事务

- 属性
  - Atomicty 原子性
  - Consistency 一致性
  - Isolation 隔离性
  - Durability 持久性

#### 创建事务

```mysql
USE sql_store;

START TRANSACTION;

INSERT INTO orders(customer_id, order_date, status)
VALUE(1, '2019-01-01', 1);

INSERT INTO order_items
VALUE(LAST_INSERT_ID(), 1, 1, 1);

COMMIT; -- 回退机制
-- ROLLBACK
```

#### 并发问题

- Lose Updates 
- Dirty Reads --> 读取未提交的信息
- Non-repeating Readings 不可重读性, 读取时可能另一个事务在修改update，导致数据不一致
- Phantom Reads 幻读 

#### 解决方案

- READ UNCOMMITTED
- READ COMMITTED --> 2 只读commit的事务数据
- REPEATABLE READ --> 1 2 3， 建立快照，通过读取快照保证数据一致
- SERIALIZABLE --> ALL，序列化，完全隔离

！！！ 隔离性越强，性能开销越大

```mysql
SHOW VARIABLES LIKE 'transaction_isolation%'
SET TRANSACTION ISOLATION LEVEL name/SERIALIZABLE
SET SESSION TRANSACTION ISOLATION LEVEL name/SERIALIZABLE -- 当前会话的后续所有事务
SET GLOBAL TRANSACTION ISOLATION LEVEL name/SERIALIZABLE -- 设置全局
```



### 高校索引

#### 创建索引

```mysql
EXPLAIN SELECT customer_id FROM customers WHERE state = 'CA'; -- 查看查询过程

CREATE INDEX idx_state ON customers (state); -- 为表中那一列创建索引
```

1. `EXPLAIN` 的 `rows` 是 **优化器的估算值（估计要读/处理多少行/页）**，不是实际耗时。

- 加索引后优化器可能改用 **索引范围扫描 + 回表** 的计划。它会根据索引统计估算匹配的行数（有时候估算会更保守或更激进），因此 `rows` 数值可能上升。
- 即使 `rows` 上升，**执行代价 = 估算行数 × 每行代价**。如果走索引能够避免扫描大量不相关页、减少 I/O（尤其是能利用缓存或顺序读取），总体代价仍可能更低。
- 如果索引导致大量随机回表（每匹配行需要一次随机读），而匹配行很多，则随机 I/O 的开销会很高；这时全表顺序扫描（顺序读，预读效率高）可能更快。优化器会基于统计信息决定。

2. **回表（bookmark lookup）及其成本**

- 读二级索引得到匹配主键后，若结果还需要其他列，就要按主键去聚簇索引读整行。

- 如果很多匹配主键分散在大量不同页上，回表会导致大量随机读（代价高）。

- 如果匹配的行在同一页/相邻页（比如 WHERE 的条件使匹配行有聚簇性），回表的随机页数远小于匹配行数，代价就低。

3. **什么是回表**

- 在 InnoDB 里，**主键索引 = 聚簇索引**，叶子存放整行数据。

- 二级索引（非主键索引）的叶子存放 `(索引列值 + 主键值)`，没有整行。

- 如果你需要取索引里没有的其他列，就要用主键去聚簇索引里再查一次 → 这就是 **回表**。

- 回表 = “二次查找”，可能导致**多次随机 I/O**（尤其当行分散时），所以性能不如覆盖索引。

  

#### 查看索引

```mysql
SHOW INDEX IN customers; -- 用于查看索引的信息
ANALYZE TABLE customers; -- 会重新扫描表的统计信息，用于更新统计信息，让信息更准确
```



#### 前缀索引

```mysql
CREATE INDEX idx_lastname ON customers (last_name(20)); -- 这个是CHAR或者VARCHAR，可选择是否需要前缀，但是text和blob一定需要，因为数据量大，至于前缀长度多少，根据表中数据去判断长度多少可以更好的区分，不一定是越大越小越好，要尽可能多的区分，但是又不能太长
```



#### 全文索引

```mysql
CREATE FULLTEXT INDEX idx_title_body ON posts (title, body); -- 创建索引，类似与搜索引擎一样搜索
SELECT 
	*,
    MATCH(title, body) AGAINST ('react redux') -- 用于返回相关性
FROM posts
WHERE MATCH(title, body) AGAINST ('react redux') -- 在全文索引用MATCH去匹配，一般默认的自然语言模式
-- WHERE MATCH(title, body) AGAINST ('react -redux +form' IN BOOLEAN MODE) ,-表示不包含，+表示包含
```



#### 复合索引

```mysql
CREATE INDEX idx_state_points ON customers (state, points); -- 最多可以加16列
EXPLAIN SELECT 
	customer_id
FROM customers
WHERE state = 'CA' AND points > 1000; -- 如果不是复合索引而是每个单一的话，他只会对前面的state索引，后面的还是正常的扫描，创建复合索引的时候，根据查询的需求排序，等值查询放前面，其余根据缩小范围的效率由高到低
```

- **索引的选择**

  - **经常用作筛选**且选择性高（很少匹配）→ 建索引。
  - 查询只返回**少量列**，且这些列都能**由索引提供** → **建覆盖索引**（避免回表）。
  - 如果筛选会匹配表的**大部分行**（常见阈值 5–20%，视系统而异）→ 全表扫描更可能更快。
  - 组合索引顺序按“等值优先 → 范围 → 排序/分组列” 来放置（**最左前缀原则**）。
  - 写频繁的表要权衡索引数量（**索引越多写越慢**）。
  - 使用 `EXPLAIN ANALYZE` 来验证是真慢还是只是估算不准。
  - `WHERE` 中包含索引列部分尽量不用算式，会导致**索引失效**

- ##### **复合索引只能从最左边开始匹配**。

索引 `(a, b, c)`, 只能从`a`开始作为查询依据,不可以直接用`b` / `c`去查询

- ##### **选择性高的列放前面**

  - “选择性”指的是这个列能把数据筛选得多精确。

  - 比如有一百万行数据：

    - `gender` 只有 M/F → 选择性差
    - `email` 唯一 → 选择性高

  - 一般把 `选择性高` 的列放在前面，可以更快缩小范围。

- ##### **等值匹配列优先，范围列往后**

  - 如果你的查询经常是 `WHERE a = ? AND b = ? AND c > ?`
  - 那么索引顺序应该是 `(a, b, c)`，因为 a 和 b 是等值查询，可以一起用，c 是范围条件，放最后。

- ##### **和 ORDER BY / GROUP BY 配合**

  - 如果你经常 `ORDER BY a, b`，那 `(a, b)` 索引会同时帮你加速排序。
  - 如果写 `(b, a)` 就用不上了。
  - `ORDER BY a, b / a / b / a DESC, b DESC` 但是不能 `ORDER BY a, b DESC`，不能破坏`index`的原有方式，负责引入外部方法会增加性能消耗

- **考虑覆盖索引**

  - 如果你常常查询 `SELECT a, b FROM table WHERE a = ?`，那 `(a, b)` 比 `(a)` 好，因为它可以“覆盖索引”，不需要回表。

- **注意索引的维护，删除冗余索引，如果(a, b), 可以建立(b, a)或者(b), 但是不能有(a)，因为a已经包含在(a, b)**



### 数据库与用户

#### 创建用户

```mysql
-- CREATE USER test@127.0.0.1 -- 表示test可以从这个ip地址连接数据库
-- CREATE USER test@localhost -- 主机名
-- CREATE USER test@codewithmosh.com -- 域名
-- CREATE USER test@'%.codewithmosh.com' -- 子网域
CREATE USER test IDENTIFIED BY '1234' -- 表示没有任何限制
```



#### 查询与删除

```mysql
SELECT * FROM mysql.user;
CREATE USER Bob@codewithmosh.com IDENTIFIED BY '1234';
DROP USER Bob@codewithmosh.com;
```



#### 修改密码

```mysql
SET PASSWORD FOR test = '1234'; -- 用户的地址之类的也要写清楚，比如Bob@codewithmosh.com
SET PASSWORD = '1234'; -- 表示给当前用户改密码
```



#### 权限管理

```mysql
-- 1: web/desktop application
CREATE USER moon_app IDENTIFIED BY '1234';

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE -- 给予什么权限
ON sql_store.* -- 指定数据库
TO moon_app; -- 指定用户账户，有域名之类的要写清楚

-- 2: admin
GRANT ALL
ON *.*
TO test;
```

```mysql
SHOW GRANTS FOR test; -- 查看权限
SHOW GRANTS; 
```

```mysql
GRANT CREATE VIEW
ON sql_store.*
TO moon_app;

REVOKE CREATE VIEW -- 用于撤销某个权限
ON sql_store.*
FROM moon_app;
```



### 标准化

#### 第一范式

- 第一范式要求一行中的每个单元格都应该有单一值，且不能现重列

#### 第二范式

- 在符合第一范式的基础上，表中的非主键列必须完全依赖于主键（即候选主键），而不是部分依赖于主键。
  - 表中不应该包含任何非主键列，这些列的值可以由其他非主键列的值决定（部分函数依赖）。
  - 所有非主键列之间不能存在任何函数依赖关系。
- 在符合第一范式条件下，每个表table对应一个实体，不需要多余的，必须orders里面，customer name可以用id替换，在customer表中用id作为orders的外键，这样存储简单修改方便

#### 第三范式

- 表中的列不应派生自其他列