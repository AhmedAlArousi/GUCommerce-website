
CREATE TABLE Users(
username VARCHAR(20), 
first_name VARCHAR(20), 
last_name VARCHAR(20),  
password VARCHAR(20),
email VARCHAR(50),
PRIMARY KEY (username),
CONSTRAINT email_unique UNIQUE(email)
);

CREATE TABLE User_mobile_numbers(
mobile_number VARCHAR(20), 
username VARCHAR(20),
PRIMARY KEY(mobile_number,username),
FOREIGN KEY(username) REFERENCES Users --ON DELETE CASCADE ON UPDATE CASCADE,
-- same mobile number may belong to more than one user ; so won't make it UNIQUE
);

CREATE TABLE User_Addresses(
address VARCHAR(100), 
username VARCHAR(20)
PRIMARY KEY(address,username),
FOREIGN KEY(username) REFERENCES Users -- ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Customer(
username VARCHAR(20), 
points INT default 0 NOT NULL,
-- should we add default value 0 for points ?
PRIMARY KEY(username),
FOREIGN KEY(username) REFERENCES Users --ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Admins(
username VARCHAR(20),
PRIMARY KEY(username),
FOREIGN KEY(username) REFERENCES Users --ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Vendor(
username VARCHAR(20) , 
activated BIT,						-- Not mentioned explicitly
company_name VARCHAR(20), 
bank_acc_no VARCHAR(20), 
admin_username VARCHAR(20),
PRIMARY KEY (username),
FOREIGN KEY(username) REFERENCES Users, --ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY(admin_username) REFERENCES Admins -- ON UPDATE CASCADE
--TODO : Trigger ?
--WHAT SHOULD WE DO HERE if an Admin is DELETED !? TAKE CARE
);

CREATE TABLE Delivery_Person(
username VARCHAR(20), 
is_activated BIT --NOT MENTIONED EXPLICITLY
PRIMARY KEY (username),
FOREIGN KEY (username) REFERENCES Users  --ON DELETE CASCADE ON UPDATE CASCADE
);

GO
--drop trigger User_delete
CREATE TRIGGER User_delete
ON Users
INSTEAD OF DELETE
AS
BEGIN
	DELETE FROM User_mobile_numbers WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM User_Addresses WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM Admins WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM Vendor WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM Customer WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM Delivery_Person WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM Users WHERE username IN (SELECT username FROM DELETED)
END

GO
CREATE TRIGGER User_update
ON Users
AFTER UPDATE
AS
BEGIN
IF UPDATE(username) 
	BEGIN
		UPDATE  User_mobile_numbers 
			SET username = inserted.username 
			FROM User_mobile_numbers,deleted,inserted 
			WHERE deleted.username= User_mobile_numbers.username
		UPDATE User_Addresses
			SET username = inserted.username
			FROM User_Addresses,deleted,inserted
			WHERE deleted.username=User_Addresses.username
		UPDATE Admins 
			SET username = inserted.username
			FROM Admins,deleted,inserted
			WHERE deleted.username=Admins.username
		UPDATE Vendor 
			SET username = inserted.username
			FROM Vendor,deleted,inserted
			WHERE deleted.username=Vendor.username
		UPDATE Customer 
			SET username = inserted.username
			FROM Customer,deleted,inserted
			WHERE deleted.username=Customer.username
		UPDATE Delivery_Person 
			SET username = inserted.username
			FROM Delivery_Person ,deleted,inserted
			WHERE deleted.username=Delivery_Person.username
	END
END

GO
--DROP TRIGGER Admin_delete
CREATE TRIGGER Admin_delete
ON Admins
INSTEAD OF DELETE
AS
BEGIN
	DELETE FROM Vendor WHERE admin_username IN (SELECT username FROM DELETED)
	DELETE FROM Delivery WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM Todays_Deals WHERE admin_username IN (SELECT username FROM DELETED)
	DELETE FROM Giftcard WHERE username IN (SELECT username FROM DELETED)
	DELETE FROM Admin_Customer_Giftcard WHERE admin_username IN (SELECT username FROM DELETED)
	DELETE FROM Admin_Delivery_Order WHERE admin_username IN (SELECT username FROM DELETED)
	DELETE FROM Admins WHERE username IN (SELECT username FROM DELETED)
--DELETE FROM Users WHERE username IN (SELECT username FROM DELETED)
END
GO


CREATE TRIGGER Admin_update
ON Admins
AFTER UPDATE
AS
BEGIN
IF UPDATE(username)
	BEGIN
		UPDATE Vendor 
			SET username = inserted.username
			FROM Vendor,deleted,inserted
			WHERE deleted.username=Vendor.username
		UPDATE Delivery 
			SET username = inserted.username
			FROM Delivery,deleted,inserted
			WHERE deleted.username=Delivery.username
		UPDATE Todays_Deals 
			SET admin_username = inserted.username
			FROM Todays_Deals,deleted,inserted
			WHERE deleted.username=Todays_Deals.admin_username
		UPDATE Giftcard 
			SET username = inserted.username
			FROM Giftcard,deleted,inserted
			WHERE deleted.username=Giftcard.username
		UPDATE Admin_Customer_Giftcard 
			SET admin_username = inserted.username
			FROM Admin_Customer_Giftcard ,deleted,inserted
			WHERE deleted.username=Admin_Customer_Giftcard.admin_username
		UPDATE Admin_Delivery_Order
			SET admin_username = inserted.username
			FROM Admin_Delivery_Order ,deleted,inserted
			WHERE deleted.username=Admin_Customer_Giftcard.admin_username
	END
END
GO


--drop trigger Customer_delete
CREATE TRIGGER Customer_delete
ON Customer
INSTEAD OF DELETE
AS
BEGIN
	DELETE FROM Orders WHERE customer_name IN (SELECT username FROM DELETED);
	DELETE FROM Product WHERE customer_username IN (SELECT username FROM DELETED);
	DELETE FROM CustomerAddstoCartProduct WHERE customer_name IN (SELECT username FROM DELETED);
	DELETE FROM Customer_Question_Product WHERE customer_name IN (SELECT username FROM DELETED);
	DELETE FROM Wishlist WHERE username IN (SELECT username FROM DELETED);
	DELETE FROM Admin_Customer_Giftcard WHERE customer_name IN (SELECT username FROM DELETED);
	DELETE FROM Customer_CreditCard WHERE customer_name IN (SELECT username FROM DELETED);
	DELETE FROM Customer WHERE username IN (SELECT username FROM DELETED)
END

GO
CREATE TRIGGER Customer_update
ON Customer
AFTER UPDATE
AS
BEGIN
IF UPDATE(username)
	BEGIN
		UPDATE Orders 
			SET customer_name = inserted.username
			FROM Orders,inserted,deleted
			WHERE deleted.username=Orders.customer_name
		UPDATE Product 
			SET customer_username = inserted.username
			FROM Product,inserted,deleted
			WHERE deleted.username = Product.customer_username
		UPDATE CustomerAddstoCartProduct
			SET customer_name = inserted.username
			FROM CustomerAddstoCartProduct ,inserted,deleted
			WHERE deleted.username=CustomerAddstoCartProduct.customer_name
		UPDATE Customer_Question_Product 
			SET customer_name = inserted.username
			FROM Customer_Question_Product ,inserted,deleted
			WHERE deleted.username=Customer_Question_Product.customer_name
		UPDATE Wishlist 
			SET username = inserted.username
			FROM Wishlist,inserted,deleted
			WHERE deleted.username = Wishlist.username	
		UPDATE Admin_Customer_Giftcard 
			SET customer_name = inserted.username
			FROM Admin_Customer_Giftcard, inserted,deleted
			WHERE deleted.username=Admin_Customer_Giftcard.customer_name
		UPDATE Customer_CreditCard 
			SET customer_name = inserted.username
			FROM Customer_CreditCard , inserted,deleted
			WHERE deleted.username=Customer_CreditCard.customer_name
	END
END

GO
CREATE TRIGGER Vendor_delete
ON Vendor
INSTEAD OF DELETE
AS
BEGIN
DELETE FROM Product WHERE vendor_username IN (SELECT username FROM DELETED)
DELETE FROM Vendor WHERE username IN (SELECT username FROM DELETED)
END

GO
CREATE TRIGGER Vendor_update
ON Vendor
AFTER UPDATE
AS
BEGIN
IF UPDATE(username)
	BEGIN
		UPDATE Product 
			SET vendor_username=inserted.username
			FROM Product,inserted,deleted
			WHERE deleted.username=Product.vendor_username
	END
END


GO
--drop trigger DeliveryPerson_delete
CREATE TRIGGER DeliveryPerson_delete
ON Delivery_Person
INSTEAD OF DELETE
AS
BEGIN
--is admin_delivery_order true to be deleted ?
DELETE FROM Admin_Delivery_Order WHERE delivery_username IN (SELECT username FROM DELETED)
DELETE FROM Delivery_Person WHERE username IN (SELECT username FROM DELETED)
END

GO
CREATE TRIGGER DeliveryPerson_update
ON Delivery_Person
AFTER UPDATE
AS
BEGIN
IF UPDATE(username)
	BEGIN
		UPDATE Admin_Delivery_Order 
			SET delivery_username=inserted.username
			FROM Admin_Delivery_Order, inserted, deleted
			WHERE deleted.username=Admin_Delivery_Order.delivery_username
	END
END


GO
CREATE TABLE Giftcard(
code VARCHAR(10),
expiry_date DATETIME,
amount INT, 
username VARCHAR(20),
PRIMARY KEY (code),
FOREIGN KEY (username) REFERENCES Admins
);

CREATE TABLE Credit_Card(
number VARCHAR(20),
expiry_date DATE,--what ?, 
cvv_code VARCHAR(4),
PRIMARY KEY (number)
);


CREATE TABLE Delivery(
id INT IDENTITY, --Not mentioned explicitly
time_duration INT NOT NULL, 
fees DECIMAL (5,3) NOT NULL, 
username VARCHAR(20),
delivery_type VARCHAR(20),  
-- should we make it 2nd attr; to MATCH FinalSchema ?
PRIMARY KEY (id),
FOREIGN KEY (username) REFERENCES Admins
);


CREATE TABLE Orders(
order_no INT IDENTITY, 
order_date DATETIME, 
total_amount decimal(10,2), 
cash_amount DECIMAL(10,2),
credit_amount DECIMAL(10,2),
payment_type VARCHAR(20), 
order_status VARCHAR(20) DEFAULT 'not processed' ,	
remaining_days INT,  -- Mentioned in (s) in page 4 
time_limit VARCHAR(20) , 	--BALABIZO ;; WHAT IS THIS !!?
Gift_Card_code_used VARCHAR(10),
customer_name VARCHAR(20), 
delivery_id INT, 
creditCard_number VARCHAR(20),
PRIMARY KEY (order_no),
FOREIGN KEY (Gift_Card_code_used) REFERENCES Giftcard ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (customer_name) REFERENCES Customer,
FOREIGN KEY (delivery_id) REFERENCES Delivery ON DELETE SET NULL ON UPDATE CASCADE, -- is it so?,
FOREIGN KEY (creditCard_number) REFERENCES Credit_Card ON DELETE NO ACTION ON UPDATE CASCADE 
	-- I THINK THE LAST SHOULD BE NO ACTION ???
);

CREATE TABLE Product(
serial_no INT IDENTITY,
product_name VARCHAR(20),
category VARCHAR(20),
product_description VARCHAR(200),--text,
price DECIMAL (10,2),
final_price DECIMAL(10,2),	--On (a) and (c) in page 5
color VARCHAR (20), 		--on (a) page 5
available BIT , -- didn't mention type
rate INT, -- (n) in page +4+
vendor_username VARCHAR(20), 
customer_username VARCHAR(20), 
customer_order_id INT,
PRIMARY KEY(serial_no),
FOREIGN KEY(vendor_username) REFERENCES Vendor, --ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (customer_username) REFERENCES Customer, -- ON DELETE CASCADE ON UPDATE CASCADE, 
FOREIGN KEY(customer_order_id) REFERENCES Orders ON DELETE CASCADE ON UPDATE CASCADE 
);


CREATE TABLE CustomerAddstoCartProduct(
serial_no INT, 
customer_name VARCHAR (20),
PRIMARY KEY (serial_no,customer_name),
FOREIGN KEY (serial_no) REFERENCES Product ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (customer_name) REFERENCES Customer --ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Todays_Deals(
deal_id INT IDENTITY,
deal_amount INT,
expiry_date DATETIME,
admin_username VARCHAR(20),
PRIMARY KEY (deal_id),
FOREIGN KEY (admin_username) REFERENCES Admins --ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Todays_Deals_Product(
deal_id INT,
serial_no INT,
PRIMARY KEY (deal_id ,serial_no),
FOREIGN KEY (deal_id) REFERENCES Todays_Deals ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (serial_no) REFERENCES Product ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE offer(
offer_id INT IDENTITY,
offer_amount INT,
expiry_date DATETIME,
PRIMARY KEY (offer_id)
);


CREATE TABLE offersOnProduct(
offer_id INT,
serial_no INT,
PRIMARY KEY (offer_id , serial_no),
FOREIGN KEY (offer_id) REFERENCES offer ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (serial_no) REFERENCES Product ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Customer_Question_Product(
serial_no INT,
customer_name VARCHAR(20),
question VARCHAR(50), -----question type is not stated	-- see (d) in page 2
answer TEXT,	--TRUE (y) <3
PRIMARY KEY (serial_no ,customer_name),
FOREIGN KEY (serial_no) REFERENCES Product ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (customer_name) REFERENCES Customer --ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Wishlist(
username VARCHAR (20),
name VARCHAR (20),
PRIMARY KEY (username , name),
FOREIGN KEY (username) REFERENCES Customer -- ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Wishlist_Product(
username VARCHAR (20),
wish_name VARCHAR (20),
serial_no INT,
PRIMARY KEY (username , wish_name , serial_no),
FOREIGN KEY (username , wish_name) REFERENCES WishList ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (serial_no) REFERENCES Product ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Admin_Customer_Giftcard(
code VARCHAR(10),
customer_name VARCHAR (20),
admin_username VARCHAR(20),
remaining_points INT,	--added after finSch(3)
PRIMARY KEY (code , customer_name ,admin_username),
FOREIGN KEY (code) REFERENCES Giftcard ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (customer_name) REFERENCES Customer , --ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (admin_username) REFERENCES Admins --ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Admin_Delivery_Order(
delivery_username VARCHAR (20),
order_no INT,
admin_username VARCHAR (20), 
delivery_window VARCHAR (50),	--(c) in page 7
PRIMARY KEY (delivery_username,order_no),
FOREIGN KEY (delivery_username) REFERENCES Delivery_person,-- ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (order_no) REFERENCES Orders ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (admin_username) REFERENCES Admins --ON DELETE CASCADE ON UPDATE CASCADE);
);

CREATE TABLE Customer_CreditCard(
customer_name VARCHAR(20), 
cc_number VARCHAR (20),
PRIMARY KEY (customer_name,cc_number),
FOREIGN KEY (customer_name) REFERENCES Customer ,-- ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (cc_number) REFERENCES Credit_Card ON DELETE CASCADE ON UPDATE CASCADE
);