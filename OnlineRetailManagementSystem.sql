create database hellofromtheotherside;
use hellofromtheotherside ;

CREATE TABLE Customer
(
  Cust_id VARCHAR(255) NOT NULL,
  First_Name VARCHAR(255) NOT NULL,
  Last_name VARCHAR(255) NOT NULL,
  Phone_number BIGINT NOT NULL,
  Email_address VARCHAR(255) NOT NULL,
  Date_of_signup DATE NOT NULL,
  UNIQUE (Phone_number),
  UNIQUE (Email_address)
  );
  Select * from customer;
  
ALTER TABLE `Customer` ADD  PRIMARY KEY (`Cust_id`);

CREATE TABLE Address
(
  Apartment_name VARCHAR(255) NOT NULL,
  Pincode INT NOT NULL,
  street_name VARCHAR(255) NOT NULL,
  Address_id VARCHAR(255) NOT NULL,
  Cust_id VARCHAR(255) NOT NULL
);
ALTER TABLE `Address` ADD  PRIMARY KEY (`Address_id`);
Select * from address;

CREATE TABLE Zip_code
(
  City VARCHAR(255) NOT NULL,
  State VARCHAR(255) NOT NULL,
  Country VARCHAR(255) NOT NULL,
  Zipcode_id VARCHAR(255) NOT NULL,
  Address_id VARCHAR(255) NOT NULL
);
ALTER TABLE `Zip_code` ADD  PRIMARY KEY (`Zipcode_id`);
Select * from zip_code;
CREATE TABLE Invoice
(
  Billing_ID VARCHAR(255) NOT NULL,
  Amount FLOAT NOT NULL
);
ALTER TABLE `Invoice` ADD  PRIMARY KEY (`Billing_ID`);
Select * from invoice;

CREATE TABLE Products
(
  Product_id VARCHAR(255) NOT NULL,
  height FLOAT NOT NULL,
  weight FLOAT NOT NULL,
  colour VARCHAR(255) NOT NULL
);
ALTER TABLE `Products` ADD  PRIMARY KEY (`Product_id`);
Select * from products;

CREATE TABLE Payment
(
  Payment_id VARCHAR(255) NOT NULL,
  payment_mode VARCHAR(255) NOT NULL,
  Amount FLOAT NOT NULL,
  Card_type VARCHAR(255) NOT NULL,
  Cust_id VARCHAR(255) NOT NULL,
  Billing_ID VARCHAR(255) NOT NULL
);
ALTER TABLE `Payment` ADD  PRIMARY KEY (`Payment_id`);
Select * from payment;

CREATE TABLE Product_details
(
  product_name VARCHAR(255) NOT NULL,
  Supplier_id VARCHAR(255) NOT NULL,
  Product_id VARCHAR(255) NOT NULL
);

Select * from product_details;

CREATE TABLE Orders
(
  Order_id VARCHAR(255) NOT NULL,
  Order_date DATE NOT NULL,
  Shipment_status VARCHAR(255) NOT NULL,
  quantity INT NOT NULL,
  Payment_id VARCHAR(255) NOT NULL,
  Product_id VARCHAR(255) NOT NULL
);
ALTER TABLE `Orders` ADD  PRIMARY KEY (`Order_id`);
Select * from orders;

CREATE TABLE Employee
(
  First_name VARCHAR(255) NOT NULL,
  Last_name VARCHAR(255) NOT NULL,
  Employee_id VARCHAR(255) NOT NULL,
  Department VARCHAR(255) NOT NULL,
  Salary INT NOT NULL,
  Order_id VARCHAR(255) NOT NULL,
  FOREIGN KEY (Order_id) REFERENCES Orders(Order_id)
);
ALTER TABLE `Employee` ADD  PRIMARY KEY (`Employee_id`);
Select * from employee;

--------- Relationships ------------

ALTER TABLE `Address` ADD CONSTRAINT `will have` FOREIGN KEY (`Cust_id`) REFERENCES `Customer` (`Cust_id`) ON DELETE RESTRICT ON UPDATE RESTRICT ;

ALTER TABLE `Zip_code` ADD CONSTRAINT `will zip` FOREIGN KEY (`Address_id`) REFERENCES `Address` (`Address_id`) ON DELETE RESTRICT ON UPDATE RESTRICT ;

ALTER TABLE `Payment` ADD CONSTRAINT `makes` FOREIGN KEY (`Cust_id`) REFERENCES `Customer` (`Cust_id`) ON DELETE RESTRICT ON UPDATE RESTRICT; 

ALTER TABLE `Payment` ADD CONSTRAINT `will bill` FOREIGN KEY (`Billing_ID`) REFERENCES `Invoice` (`Billing_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE `Warehouse` ADD CONSTRAINT `will keep` FOREIGN KEY (`Product_id`) REFERENCES `Products` (`Product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT ; 

ALTER TABLE `Product_details` ADD CONSTRAINT `will contain` FOREIGN KEY (`Product_id`) REFERENCES `Products` (`Product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT ; 

ALTER TABLE `Orders` ADD CONSTRAINT `will pay` FOREIGN KEY (`Payment_id`) REFERENCES `Payment` (`Payment_id`) ON DELETE RESTRICT ON UPDATE RESTRICT ; 

ALTER TABLE `Orders` ADD CONSTRAINT `contains` FOREIGN KEY (`Product_id`) REFERENCES `Products` (`Product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT ; 

ALTER TABLE `Employee` ADD CONSTRAINT `observes` FOREIGN KEY (`Order_id`) REFERENCES `Orders` (`Order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT ; 



SELECT * FROM address;
SELECT * FROM customer;
SELECT * FROM employee;
SELECT * FROM invoice;
SELECT * FROM orders;
SELECT * FROM payment;
SELECT * FROM product_details;
SELECT * FROM products;
SELECT * FROM zip_code;

# 1) Getting employees by Department:
drop procedure GetEmployeesByDepartment;
DELIMITER //
CREATE PROCEDURE GetEmployeesByDepartment(
IN DepartmentName VARCHAR(200)
)
BEGIN
SELECT *
FROM employee
WHERE Department = DepartmentName;
END //
DELIMITER ;

CALL GetEmployeesByDepartment('Sales');

DROP PROCEDURE MaxPurchase;

# 2) Finding the customer with the highest purchase:
DELIMITER //

Create Procedure MaxPurchase() 
Begin
	select Max(payment.amount) As MaxPurchase, invoice.Billing_ID, customer.Cust_id, customer.First_Name, customer.Last_name
    from customer
    inner join
    payment
    on customer.Cust_id = payment.Cust_id 
    inner join
    invoice
    on payment.Billing_ID = invoice.Billing_ID;
end//
DELIMITER ;
CALL MaxPurchase();

select * from orders;
# 3) To count the total number of orders by the status (Procedure)
drop procedure GetOrderCount;
DELIMITER $$
CREATE PROCEDURE GetOrderCount (
IN orderStatus VARCHAR(25),
OUT total INT
)
BEGIN
SELECT COUNT(Order_id)
INTO total
FROM orders
WHERE Shipment_status = orderStatus;
END $$

DELIMITER ;

CALL GetOrderCount('In Progress', @total); # @ is used to declare tempoary variables In Progress
select @total as total;

# 4) Trigger for employee updates
drop table employee_updates;
drop trigger after_employee_update;
##First creating a new table with details of updates
CREATE TABLE employee_updates(Customer_id VARCHAR(255) NOT NULL, Old_First_Name VARCHAR(255) NOT NULL, New_First_Name VARCHAR(255) NOT NULL, update_time TIMESTAMP DEFAULT NOW());

## Defining an after update trigger
DELIMITER $$
CREATE TRIGGER after_employee_update 
AFTER UPDATE ON customer 
FOR EACH ROW
BEGIN
INSERT INTO employee_updates(Customer_id, Old_First_Name, New_First_Name) 
VALUES(OLD.Cust_id, OLD.First_Name, NEW.First_Name);
END$$

DELIMITER ;

select * from employee_updates;
update customer 
set First_name = 'Jui'
where Cust_id = 'C10000';

# 5) Categorizing customers into bronze, silver & gold based on the amount incurred in transacting (Use of Case statements)
drop procedure GetCustomerCategory;
DELIMITER $$

CREATE PROCEDURE GetCustomerCategory(IN customer_ID VARCHAR(255), OUT Category VARCHAR(255))
BEGIN
	DECLARE amt INT;
    
SELECT Amount INTO amt from payment where Cust_id = customer_ID;

CASE 
	WHEN amt > 0 and amt < 100000 THEN
		SET Category = 'Bronze';
	WHEN amt >= 100000 and amt < 200000 THEN
		SET Category = 'Silver';
	ELSE
		SET Category = 'Gold';
END CASE;

END $$
DELIMITER ;

CALL GetCustomerCategory('C10000',@cat);
SELECT @cat;

#6) Exception handling for salaries
drop trigger before_salary_update;
DELIMITER $$

CREATE TRIGGER before_salary_update
BEFORE UPDATE
ON employee FOR EACH ROW
BEGIN
DECLARE errorMessage VARCHAR(255);
SET errorMessage = CONCAT('The new salary ',
NEW.salary,
' cannot be less than two times the current salary',
OLD.salary);

IF new.salary < old.salary * 2 THEN
SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = errorMessage;
END IF;
END $$

DELIMITER ;
select * from employee;
UPDATE employee
SET salary = 15000
WHERE Employee_id = 'E100'; ## Gives an error as the salary should be more than or equal to 6k


#7)

DELIMITER $$
DROP PROCEDURE if exists createPhoneList;
CREATE PROCEDURE createPhoneList (
   INOUT phoneList varchar(4000)
)
BEGIN
   DECLARE finished INTEGER DEFAULT 0;
   DECLARE contact_no varchar(100) DEFAULT "";
   DECLARE f_name varchar(100) DEFAULT "";
   -- DECLARING cursor FOR FIRSTNAME & CONTACT NO
   DECLARE curPhone
       CURSOR FOR
           SELECT Phone_number,First_name FROM Customer;
 
   -- DECLARING not found HANDLER
   DECLARE CONTINUE HANDLER
       FOR NOT FOUND SET finished = 1;
 
   OPEN curPhone;
 
   getPhone: LOOP
       FETCH curPhone INTO contact_no,f_name ;
       IF finished = 1 THEN
           LEAVE getPhone;
       END IF;
       -- CREATING CONTACT LIST OF STUDENTS
       SET phoneList = CONCAT(contact_no,"-",f_name,";",phoneList);
   END LOOP getPhone;
   CLOSE curPhone;
 
END$$
DELIMITER ;

SET @phoneList = "";
CALL createPhoneList(@phoneList);
SELECT @phoneList;

drop procedure employee_info;
#8)
DELIMITER //
CREATE PROCEDURE employee_info()
BEGIN
DECLARE inc INT;
	SET inc=1;
WHILE inc<=5 DO
	SELECT CONCAT(First_name, " ", Last_name) AS Full_Name FROM Employee;
    SET inc=inc+1;
END WHILE;
END //
DELIMITER ;

call employee_info();

9)
DELIMITER $$
CREATE PROCEDURE InvoicePriority(IN Bill_ID varchar(255),OUT Priority Varchar(255))
BEGIN
	DECLARE amt INT;

SELECT Amount INTO amt from invoice where Billing_ID = Bill_ID;

CASE
	WHEN amt > 0 and amt < 20000 THEN
		SET Priority = 'Not Urgent';
	WHEN amt >= 20000 and amt < 100000 THEN
		SET Priority = 'Priority level 1';
	ELSE
		SET Priority = 'Priority level Urgent';
END CASE;

END $$
DELIMITER ;
call InvoicePriority('B1000',@priority);
SELECT @priority;

#10)
Finding the customer with the lowest purchase:
DELIMITER //

Create Procedure MinPurchase() 
Begin
	select Min(payment.amount) As MaxPurchase, invoice.Billing_ID, customer.Cust_id, customer.First_Name, customer.Last_name
    from customer
    inner join
    payment
    on customer.Cust_id = payment.Cust_id 
    inner join
    invoice
    on payment.Billing_ID = invoice.Billing_ID;
end//
DELIMITER ;
CALL MinPurchase();






