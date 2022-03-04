
CREATE PROC customerRegister --a ,hn hande zy elnetworks wla fakes?
@username VARCHAR(20),
@first_name VARCHAR(20), 
@last_name VARCHAR(20),
@password VARCHAR(20),
@email VARCHAR(50)
AS 
BEGIN 
-- INSERT INTO Customer(username,first_name,last_name,pass,email)
IF(not exists(select * from users where username=@username))
begin
INSERT INTO Users(username,first_name,last_name,password,email)
VALUES(@username,@first_name,@last_name,@password,@email)
INSERT INTO Customer(username,points)
VALUES (@username,0)
end

END

GO 
CREATE PROC vendorRegister --b
 @username VARCHAR(20),
 @first_name VARCHAR(20), 
 @last_name VARCHAR(20),
 @password VARCHAR(20),
 @email VARCHAR(50), 
 @company_name VARCHAR(20), 
 @bank_acc_no VARCHAR(20)
 AS
BEGIN 
IF(not exists(select * from users where username=@username))
begin
 INSERT INTO Users(username,first_name,last_name,password,email)--,company_name,bank_acc_no)
 VALUES(@username,@first_name,@last_name,@password,@email)--,@company_name,@bank_acc_no)
 INSERT INTO Vendor(username,activated,company_name,bank_acc_no)
 VALUES (@username,'0',@company_name,@bank_acc_no)
 end
 
END
