
GO
CREATE PROC postProduct	--a
@vendorUsername VARCHAR(20),
@product_name VARCHAR(20),
@category VARCHAR(20),
@product_description VARCHAR(200),
@price DECIMAL(10,2),
@color VARCHAR(20)
AS
BEGIN
INSERT INTO 
Product(vendor_username, product_name,category,product_description,price,final_price,color,available)
VALUES(@vendorUsername,@product_name,@category,@product_description,@price,@price,@color,1)

END


GO
CREATE PROC vendorviewProducts  --b
@vendorname VARCHAR(20)
AS
BEGIN
	SELECT p.* 
	FROM Vendor v INNER JOIN Product p
	ON v.username = p.vendor_username
	WHERE v.username = @vendorname
END


GO
CREATE PROC EditProduct	--c
@vendorname VARCHAR(20),
@serialnumber INT,
@product_name VARCHAR(20),
@category VARCHAR(20),
@product_description VARCHAR(200),
@price DECIMAL(10,2),
@color VARCHAR(20)
AS
BEGIN
	UPDATE Product
	SET vendor_username =@vendorname ,
	--serial_no =  @serialnumber,    --- maynf3sh y update l primary key asl keda han3rf l product l han3mlo edit ezay
	product_name = @product_name,
	category = @category , 
	product_description = @product_description , 
	final_price = @price,
	color = @color
	WHERE serial_no = @serialnumber    -- hay update el product el nafs l serialnumber input??

END



GO
CREATE PROC deleteProduct --d
@vendorname VARCHAR(20),
@serialnumber int
AS
BEGIN
	DELETE FROM Product
		WHERE serial_no = @serialnumber AND vendor_username = @vendorname

END


GO
CREATE PROC viewQuestions	--e
@vendorname VARCHAR(20)
AS
BEGIN
	SELECT c.*
	FROM Vendor v INNER JOIN Product p
	ON v.username = p.vendor_username
	INNER JOIN Customer_Question_Product c
	ON c.serial_no = p.serial_no
	WHERE v.username =@vendorname
END



GO
CREATE PROC answerQuestions	--f
@vendorname VARCHAR(20),
@serialno INT,
@customername VARCHAR(20),
@answer TEXT
AS
BEGIN
	UPDATE Customer_Question_Product 
		SET answer = @answer
		FROM Product p INNER JOIN Customer_Question_Product c
		ON c.serial_no = p.serial_no 
		WHERE p.vendor_username = @vendorname AND p.serial_no = @serialno AND c.customer_name = @customername
END

GO
CREATE PROC addOffer	--g1
@offeramount INT,
@expiry_date DATETIME
AS
BEGIN
	INSERT INTO offer(offer_amount,expiry_date)            
		VALUES(@offeramount,@expiry_date)
END

GO
CREATE PROC checkOfferonProduct	--g2
@serial INT,
@activeoffer BIT OUTPUT
AS
BEGIN
	DECLARE @number INT
	SELECT @number = COUNT(*)
		From offersOnProduct 
		WHERE serial_no = @serial
	IF @number = 0
		BEGIN
			SET @activeoffer = 0
			PRINT (@activeoffer)
		END
	ELSE
		BEGIN
			SET @activeoffer = 1
			PRINT (@activeoffer)
		END
END


GO
CREATE PROC checkandremoveExpiredoffer	--g3
@offerid int
AS
BEGIN
	DECLARE @todaysDate DATETIME
	SELECT @todaysDate = GETDATE()
	UPDATE Product
		SET final_price = price
		WHERE serial_no IN
			(SELECT oo.serial_no
				FROM offer o INNER JOIN offersOnProduct oo
				ON o.offer_id = oo.offer_id
				WHERE oo.offer_id = @offerid AND @todaysDate >= o.expiry_date
			)
	DELETE 
		FROM offersOnProduct
		WHERE offer_id IN 
			( SELECT offer_id 
				FROM offer
				WHERE offer_id=@offerid AND @todaysDate>= expiry_date
			)
	DELETE 
		FROM offer
		WHERE @todaysDate>expiry_date AND offer_id=@offerid

END

GO
CREATE PROC applyOffer
@vendorname VARCHAR(20), 
@offerid INT,
@serial INT
AS
BEGIN
	--IF(@offerid NOT IN (SELECT offer_id FROM offersOnProduct))
	IF(@serial NOT IN (SELECT serial_no FROM offersOnProduct))
		BEGIN
			DECLARE @price DECIMAL(10,2)
			DECLARE @offerAmount INT
			
			SELECT @offerAmount = offer_amount
				FROM offer
				WHERE offer_id = @offerid

			SELECT @price = price 
				FROM Product
				WHERE serial_no = @serial

			DECLARE @newPrice DECIMAL(10,2)
			SET @newPrice = @price - @offerAmount

			UPDATE Product
				SET final_price = @newPrice
				WHERE serial_no=@serial

			INSERT INTO offersOnProduct 
				VALUES (@offerid,@serial)
		END
	ELSE 
		PRINT 'The product has an active offer'
END