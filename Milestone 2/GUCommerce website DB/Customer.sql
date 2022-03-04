
CREATE PROC showProducts --a
AS
BEGIN
	SELECT distinct product_name,product_description,price,final_price,color
		FROM Product
END

GO
CREATE PROC ShowProductsbyPrice --b
AS
BEGIN
	SELECT distinct product_name,product_description,price,color
		FROM Product
		ORDER BY price		-- Check
END

GO
CREATE PROC  searchbyname --c
@text varchar(20)
AS
BEGIN
	SELECT distinct product_name,product_description,price,final_price,color
		FROM Product 
		WHERE product_name LIKE @text+'%' OR product_name LIKE '%'+@text OR product_name LIKE '%'+@text+'%'
END


GO
CREATE PROC AddQuestion --d
@serial INT,
@customer VARCHAR(20),
@Question VARCHAR(50) --product customer question
AS
BEGIN
	IF(NOT EXISTS (SELECT * from Customer_Question_Product WHERE serial_no=@serial AND customer_name=@customer))
		BEGIN
			INSERT INTO Customer_Question_Product(serial_no,customer_name,question) 
				VALUES(@serial,@customer,@Question)
		END
END

GO
CREATE PROC addToCart --e1
@customername VARCHAR(20), 
@serial INT
AS 
BEGIN
IF(NOT EXISTS(SELECT * FROM CustomerAddstoCartProduct WHERE customer_name=@customername AND serial_no=@serial))
	BEGIN
		INSERT INTO CustomerAddstoCartProduct VALUES (@serial,@customername)
	END

END

GO
CREATE PROC removefromCart --e2
@customername VARCHAR(20), 
@serial INT
AS 
BEGIN
	if(EXISTS(SELECT * FROM CustomerAddstoCartProduct WHERE customer_name=@customername AND serial_no=@serial))
		BEGIN
			DELETE FROM CustomerAddstoCartProduct 
				WHERE customer_name=@customername AND serial_no=@serial
		END

END

GO
CREATE PROC createWishlist --f
@customername VARCHAR(20), 
@name VARCHAR(20)
AS
BEGIN 
	IF(NOT EXISTS (SELECT * FROM Wishlist WHERE username=@customername AND name=@name))
		BEGIN
			INSERT INTO Wishlist 
				VALUES (@customername,@name)
		END
END

GO
CREATE PROC AddtoWishlist --g1
@customername VARCHAR(20), 
@wishlistname VARCHAR(20), 
@serial INT
AS
BEGIN 
	IF (NOT EXISTS (SELECT * FROM Wishlist_Product WHERE username=@customername AND wish_name=@wishlistname and serial_no=@serial))
		BEGIN
			INSERT INTO Wishlist_Product 
				VALUES (@customername,@wishlistname,@serial)
		END
END

GO
CREATE PROC removefromWishlist --g2
@customername varchar(20), 
@wishlistname varchar(20), 
@serial int
AS
BEGIN 
	IF (EXISTS(SELECT * FROM Wishlist_Product WHERE username=@customername AND wish_name=@wishlistname and serial_no=@serial))
		BEGIN
			DELETE FROM Wishlist_Product 
			WHERE wish_name=@wishlistname AND username=@customername AND serial_no=@serial
		END
END


GO
CREATE PROC showWishlistProduct --h
@customername varchar(20), @name varchar(20)
AS 
BEGIN
	SELECT p.product_name,p.product_description,p.price,p.final_price,p.color
		FROM  Wishlist_Product WP
		INNER JOIN Product p ON p.serial_no=WP.serial_no
		WHERE WP.username=@customername AND WP.wish_name=@name
END

GO
CREATE PROC  viewMyCart --i
@customer varchar(20)
AS 
BEGIN
	SELECT p.product_name,p.product_description,p.price,p.final_price,p.color
		FROM CustomerAddstoCartProduct c INNER JOIN Product p ON c.serial_no=p.serial_no
		WHERE c.customer_name=@customer
END


GO
CREATE PROC calculatepriceOrder --j1
@customername varchar(20),
@result DECIMAL(10,2) OUTPUT
AS
BEGIN 
	--DECLARE @sum DECIMAL (10,2)
	--SELECT @sum=SUM(P.price)
	SELECT @result=SUM(P.final_price)
		FROM CustomerAddstoCartProduct ac INNER JOIN Product P ON P.serial_no=ac.serial_no
		WHERE ac.customer_name=@customername
	IF (@result is null ) SET @result = 0
	print @result
	--RETURN @sum
END
--drop proc productsinorder

GO
CREATE PROC productsinorder --j2
@customername varchar(20), @orderID int
AS 
BEGIN
	--SELECT * FROM CustomerAddstoCartProduct
	--with tmp as (SELECT serial_no FROM CustomerAddstoCartProduct WHERE customer_name=@customername)
	UPDATE PRODUCT
		SET customer_username=@customername, customer_order_id=@orderID
		WHERE serial_no IN (	SELECT serial_no
								FROM CustomerAddstoCartProduct
								WHERE customer_name=@customername
							)
	DELETE FROM CustomerAddstoCartProduct
		WHERE serial_no IN	(SELECT serial_no
								FROM CustomerAddstoCartProduct
								WHERE customer_name=@customername)
			AND	(customer_name <> @customername)

	SELECT * FROM Product WHERE serial_no IN (SELECT serial_no 
												FROM CustomerAddstoCartProduct
												WHERE customer_name=@customername )
	SELECT * FROM CustomerAddstoCartProduct
END

GO
CREATE PROC emptyCart --j3
@customername varchar(20)
AS
BEGIN
	DELETE FROM CustomerAddstoCartProduct 
	WHERE customer_name=@customername
END

GO

GO
CREATE PROC makeOrder --j4  انها حقا لعينة يا جورج
@customername varchar(20)
AS
BEGIN
	DECLARE @amo DECIMAL(10,2)
	--SET @amo=dbo.calculatepriceOrder (@customername)
	EXEC calculatepriceOrder @customername, @amo OUTPUT
	INSERT INTO Orders(customer_name,total_amount, order_date) --, order_status)
		VALUES(@customername,@amo, CURRENT_TIMESTAMP) -- ,'not processed')

	DECLARE @orderNO INT
	SELECT @orderNO=MAX(order_no)
		FROM Orders
	EXEC productsinorder @customername, @orderNO
	EXEC emptyCart @customername
END


GO
CREATE PROC cancelOrder --k
@orderid int
AS
BEGIN
	DECLARE @username VARCHAR(20)
				SET @username = (SELECT customer_name
										FROM Orders
										WHERE order_no=@orderid)

	IF EXISTS (SELECT * FROM Orders 
				WHERE order_status ='not processed' OR order_status='in process' 
				AND order_no=@orderid)
		BEGIN
			DECLARE @GCU VARCHAR(10)
			IF (EXISTS (SELECT O.Gift_Card_code_used 
			FROM Orders O Inner JOIN Giftcard G ON G.code=O.Gift_Card_code_used
			WHERE O.order_no=@orderid AND G.expiry_date>CURRENT_TIMESTAMP AND O.Gift_Card_code_used IS NOT NULL ) )
			BEGIN
				DECLARE @points_amount INT
				declare @cash decimal(10,2) declare @credit decimal(10,2)
				SELECT @cash=cash_amount FROM Orders WHERE order_no=@orderid
				SELECT @credit=credit_amount FROM Orders WHERE order_no=@orderid
				IF (@cash IS NOT NULL AND @cash>0)
					begin
						SELECT @points_amount= total_amount - cash_amount
							FROM Orders
							WHERE order_no=@orderid
					end						
				else if (@credit IS NOT NULL AND @credit>0)
					begin
						SELECT @points_amount= total_amount - credit_amount
								FROM Orders
								WHERE order_no=@orderid
					end
				
				UPDATE Customer
					SET points = points + @points_amount
					WHERE username = @username
				DECLARE @code VARCHAR(10)
				SET @code = (SELECT Gift_Card_code_used FROM Orders WHERE order_no=@orderid)
				UPDATE Admin_Customer_Giftcard
					SET remaining_points = remaining_points+@points_amount
					WHERE code=@code AND customer_name=@username
			END
		ELSE IF ((SELECT Gift_Card_code_used
					FROM Orders O
					WHERE O.order_no=@orderid )IS NOT NULL ) 
			BEGIN
				DECLARE @usd VARCHAR(10)
				SELECT @usd=  Gift_Card_code_used FROM Orders O WHERE O.order_no=@orderid
				EXEC removeExpiredGiftCard @usd 
			END
		UPDATE Product
			SET customer_order_id=null,customer_username=null
			WHERE customer_order_id=@orderid
		DELETE FROM Orders
			WHERE order_no=@orderid
		END
	ELSE
		BEGIN
			PRINT 'no can dosville baby doll'
		END
END

GO
CREATE PROC returnProduct --l
@serialno int, @orderid int
AS
BEGIN
	--DECLARE @total_amount decimal(10,2) 
	DECLARE @cash_amount DECIMAL(10,2)
	DECLARE @credit_amount DECIMAL(10,2)
	--DECLARE @payment_type VARCHAR(20)
	DECLARE @order_status VARCHAR(20)
	--remaining_days INT
	DECLARE @time_limit VARCHAR(20)
	--DECLARE @Gift_Card_code_used VARCHAR(10)
	DECLARE @customer_name VARCHAR(20)
	DECLARE @delivery_id INT
	DECLARE @creditCard_number VARCHAR(20)

	DECLARE @serials table (serial_no INT)
	DECLARE @newordercart table (serial_no INT,customer_name VARCHAR(20))
	DECLARE @originalcart table (serial_no INT,customer_name VARCHAR(20))

	SELECT @cash_amount=cash_amount,@credit_amount=credit_amount,
	@order_status=order_status,@time_limit=time_limit,@customer_name=customer_name,
	@delivery_id=delivery_id,@creditCard_number=creditCard_number
		FROM Orders
		WHERE order_no=@orderid
		--AND order_status='delivered'
	
	
	INSERT INTO @newordercart (serial_no)
	SELECT serial_no FROM Product
		WHERE customer_order_id=@orderid and serial_no <> @serialno
	UPDATE @newordercart SET customer_name=@customer_name

	INSERT INTO @originalcart (serial_no)
		SELECT @serialno
			FROM CustomerAddstoCartProduct
			WHERE customer_name=@customer_name
	UPDATE @originalcart SET customer_name=@customer_name

	DELETE FROM CustomerAddstoCartProduct
		WHERE customer_name=@customer_name


	EXEC cancelOrder @orderid
	
	INSERT INTO CustomerAddstoCartProduct (serial_no,customer_name)
		SELECT * FROM @newordercart
	
	EXEC makeOrder @customer_name
	
	DECLARE @newOrder INT
	SELECT @newOrder =MAX(order_no)
		FROM Orders

	UPDATE Orders 
		SET order_status=@order_status,time_limit=@time_limit,
			delivery_id=@delivery_id,creditCard_number= @creditCard_number
		WHERE order_no=@newOrder
	EXEC SpecifyAmount @customer_name,@newOrder,@cash_amount,@credit_amount
	
	INSERT INTO CustomerAddstoCartProduct 
		SELECT * FROM @originalcart
END

GO
CREATE PROC ShowproductsIbought --m
@customername varchar(20)
AS
BEGIN
	SELECT serial_no, product_name, category, product_description, price, final_price, color
	FROM Product
	WHERE customer_username=@customername
END

GO
CREATE PROC rate --n
@serialno int, @rate int , @customername varchar(20)
AS
BEGIN
	UPDATE Product
	SET rate=@rate
	WHERE customer_username=@customername AND serial_no=@serialno

END

GO
CREATE PROC SpecifyAmount --o
@customername varchar(20), @orderID int, @cash decimal(10,2), @credit decimal(10,2)
AS
BEGIN 
	
	DECLARE @order_amount DECIMAL (10,2)
	SET @order_amount = (SELECT total_amount FROM Orders WHERE order_no=@orderID)
	IF @cash >0
		BEGIN
			UPDATE Orders
					SET cash_amount=@cash, payment_type='cash'
					WHERE customer_name=@customername AND order_no=@orderID
			IF (@cash < @order_amount)
				BEGIN
					IF ((SELECT points FROM Customer WHERE username=@customername) >= @order_amount-@cash  )
						BEGIN
							DECLARE @code1 VARCHAR(10)
						
							SET @code1 =	(
								SELECT TOP 1 G.code
									FROM Giftcard G INNER JOIN Admin_Customer_Giftcard ACG ON G.code = ACG.code
									WHERE ACG.remaining_points >= @order_amount-@cash AND G.expiry_date>CURRENT_TIMESTAMP
									ORDER BY G.expiry_date 
									)
							UPDATE Customer
								SET points = points- (@order_amount-@cash) 
								WHERE username=@customername
							UPDATE Admin_Customer_Giftcard
								SET remaining_points = remaining_points - (@order_amount-@cash) 
								WHERE customer_name=@customername AND code=@code1
							UPDATE Orders
								SET Gift_Card_code_used = @code1
								WHERE order_no=@orderID
						END
				END
		END
	ELSE IF @credit>0
		BEGIN
		--Will copy the code of Cash here ; change every cash->credit ; 
		--after completeing the part OF SET @code
			UPDATE Orders
					SET credit_amount=@credit, payment_type='credit'
					WHERE customer_name=@customername AND order_no=@orderID
			IF (@credit < @order_amount)
				BEGIN
					IF ((SELECT points FROM Customer WHERE username=@customername) >= @order_amount -@credit )
						BEGIN
							DECLARE @code2 VARCHAR(10)
						
							SET @code2 =	(
								SELECT TOP 1 G.code
									FROM Giftcard G INNER JOIN Admin_Customer_Giftcard ACG ON G.code = ACG.code
									WHERE ACG.remaining_points >= @order_amount-@credit AND G.expiry_date>CURRENT_TIMESTAMP
									ORDER BY G.expiry_date 
									)
							UPDATE Customer
								SET points = points- (@order_amount-@credit) 
								WHERE username=@customername
							UPDATE Admin_Customer_Giftcard
								SET remaining_points = remaining_points - (@order_amount-@credit) 
								WHERE customer_name=@customername AND code=@code2
							UPDATE Orders
								SET Gift_Card_code_used = @code2
								WHERE order_no=@orderID
						END
				END
		END

END

GO
CREATE PROC AddCreditCard --p
@creditcardnumber varchar(20), 
@expirydate date , 
@cvv varchar(4), 
@customername varchar(20)
AS
BEGIN
	INSERT INTO Credit_Card
	VALUES (@creditcardnumber, @expirydate, @cvv);
	INSERT INTO Customer_CreditCard
	VALUES (@customername, @creditcardnumber);
END

GO
CREATE PROC ChooseCreditCard --q
@creditcard varchar(20), @orderid int
AS
BEGIN
	DECLARE @cust VARCHAR(20)
	SELECT @cust =  customer_name FROM Orders WHERE order_no=@orderid
	IF (EXISTS (SELECT * FROM Credit_Card C INNER JOIN Customer_CreditCard CC ON C.number=CC.cc_number WHERE cc.customer_name=@cust))
		BEGIN
			UPDATE Orders
				SET creditCard_number=@creditcard
				WHERE order_no=@orderid
		END
END

GO
CREATE PROC vewDeliveryTypes --r
AS 
BEGIN
SELECT delivery_type as 'TYPE', time_duration as 'Duration in Days',fees 
FROM Delivery
END

GO
CREATE PROC specifydeliverytype --s
@orderID int, @deliveryID INT
AS
BEGIN
	DECLARE @dur int
	SELECT @dur = time_duration
		FROM Delivery
		WHERE id = @deliveryID

	UPDATE Orders
		SET delivery_id=@deliveryID,
			remaining_days =  @dur  -  DATEDIFF (DAY,order_date,CURRENT_TIMESTAMP)
		WHERE order_no=@orderID
END

GO
CREATE PROC trackRemainingDays --t
@orderid int, @customername varchar(20), --el input customername malosh lazma
@days INT OUTPUT                      --fa homa 7atino leh
AS                                     --fa 8aleban ely ana 3amlo 8alat
BEGIN
	SET NOCOUNT ON
	DECLARE @dur int
	DECLARE @Did INT

	SELECT @Did = delivery_id
		FROM Orders
		WHERE order_no= @orderid

	SELECT @dur = time_duration
		FROM Delivery
		WHERE id = @Did

	UPDATE Orders 
		SET remaining_days =  @dur  - DATEDIFF (DAY,order_date,CURRENT_TIMESTAMP)
		WHERE order_no=@orderid AND customer_name=@customername

	SELECT @days=remaining_days		-- can't we do this in the previous statement ?
		FROM Orders
		WHERE order_no=@orderid AND customer_name=@customername
	print @days
END

GO
create procedure recommend
@customername varchar(20)
AS
BEGIN

DECLARE @Product2serials TABLE(
serial int,num int);

INSERT INTO @Product2serials(serial,num)
select top 3 p.serial_no ,count(p.serial_no)
from Product p inner join Wishlist_product wp on p.serial_no=wp.serial_no
where p.category in (SELECT top 3 p.category
FROM Product p2 INNER JOIN CustomerAddstoCartProduct adc ON adc.seriaL_no=p2.serial_no
where adc.customer_name=@customername
group by p2.category
order by count(p2.category) desc)
group by p.serial_no
order by count(p.serial_no) desc;

INSERT INTO @Product2serials(serial,num)
select top 3 p.serial_no ,count(p.serial_no)
from Product p inner join Wishlist_Product wp on p.serial_no=wp.serial_no
where wp.username in(select top 3 cpp.customer_name 
  from CustomerAddstoCartProduct cpp
  where cpp.customer_name<>@customername and cpp.serial_no in(select cp.serial_no
  from CustomerAddstoCartProduct cp
  where cp.customer_name=@customername) 
  group by cpp.customer_name
  order by count(cpp.customer_name) desc)
  group by p.serial_no
  order by count(p.serial_no) desc;

  select DISTINCT p.serial_no,p.product_name,p.category,p.product_description,p.price,p.final_price,p.color
  from Product p inner join @Product2serials ps on p.serial_no=ps.serial
 
END