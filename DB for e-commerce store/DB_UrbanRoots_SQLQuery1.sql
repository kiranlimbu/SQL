CREATE DATABASE DB_UrbanRoots;
GO

USE DB_UrbanRoots;
GO

-- Create Schema
----------------------------------------
CREATE SCHEMA HR AUTHORIZATION dbo;
GO
CREATE SCHEMA Sales AUTHORIZATION dbo;
GO
CREATE SCHEMA Production AUTHORIZATION dbo;
GO


-- Create Table
----------------------------------------
CREATE TABLE HR.Employees
(
	empID int NOT NULL PRIMARY KEY,
	lastname nvarchar(50),
	firstname nvarchar(50),
	address nvarchar(80),
	city nvarchar(80),
	state nvarchar(2),
	zipcode int,
	phone BIGINT -- has to be atleast 10 numbers
);
GO

CREATE TABLE Sales.Customers
(
	custID int NOT NULL PRIMARY KEY,
	lastname nvarchar(50),
	firstname nvarchar(50),
	address nvarchar(80),
	city nvarchar(80),
	state nvarchar(2),
	zipcode int,
	email nvarchar(320),
	phone BIGINT 
);
GO

-- needs alter fK
CREATE TABLE Sales.OrderDetails
(
	orderID int NOT NULL,
	productID int NOT NULL,
	unitprice DECIMAL(5,2) NOT NULL, -- has to be more then $0
	qty int DEFAULT 1
);
GO

-- needs alter fk
CREATE TABLE Sales.Orders
(
	orderID int NOT NULL PRIMARY KEY,
	custID int NOT NULL,
	empID int NOT NULL,
	orderdate date DEFAULT GETDATE(),
	shippeddate date DEFAULT GETDATE(),
	shipname nvarchar(100),
	shipaddress nvarchar(80),
	shipcity nvarchar(80),
	shipstate nvarchar(2),
	shipzipcode int
);
GO

CREATE TABLE Production.Products
(
	productID int NOT NULL PRIMARY KEY,
	productname nvarchar(100),
	unitprice DECIMAL(5,2) -- has to be more then $0
);
GO

-------------------------------------------------------------------
-- Verify
--SELECT * FROM INFORMATION_SCHEMA.TABLES
-------------------------------------------------------------------


-- Alter Table
----------------------------------------
ALTER TABLE Sales.Orders
ADD CONSTRAINT fk_cust FOREIGN KEY (custID) REFERENCES Sales.Customers(custID),
	CONSTRAINT fk_emp FOREIGN KEY (empID) REFERENCES HR.Employees(empID);
GO

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT fk_ord FOREIGN KEY (orderID) REFERENCES Sales.Orders(orderID),
	CONSTRAINT fk_prod FOREIGN KEY (productID) REFERENCES Production.Products(productID);
GO

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT chk_Det_unitprice CHECK (unitprice > 0);
GO
ALTER TABLE Production.Products
ADD CONSTRAINT chk_Prod_unitprice CHECK (unitprice > 0);
GO
ALTER TABLE HR.Employees
ADD CONSTRAINT chk_Emp_phone CHECK (phone BETWEEN 1000000000 and 9999999999);
GO

-------------------------------------------------------------------
-- Verify
--exec sp_help 'HR.Employees';
--GO
-------------------------------------------------------------------

-- Insert data
INSERT INTO HR.Employees
VALUES 
(1, N'Limbu', N'Kiran', N'1234 Juno St', N'Lacey', N'WA', 98516, 2537776108),
(2, N'Ata', N'Catherine', N'5678 Bruno Ave', N'Tacoma', N'WA', 98433, 2537776108),
(3, N'Oh', N'Mary', N'9123 Pacific Blvd', N'Olympia', N'WA', 98516, 2537776108);
GO

INSERT INTO Sales.Customers
VALUES 
(1, N'Ell', N'Caron', N'1043 Huston St', N'Seattle', N'WA', 98101, N'caronell@gmail.com', 2531904532),
(2, N'Selma', N'Beckman', N'23 Dimond Rd', N'Dallas', N'TX', 75019, N'selmabackman@yahoo.com', 4698192034),
(3, N'Thom', N'Martin', N'567 Martinway Blvd', N'Lacey', N'WA', 98516, N'martin.thom1@gmail.com', 4156667100);
GO

INSERT INTO Production.Products
VALUES 
(1, N'Rose bouquet', 38.99),
(2, N'Lily bouquet', 29.99),
(3, N'7 Blue Orchids bouquet', 19.99);
GO

INSERT INTO Sales.Orders
VALUES 
(1, 1, 3, '2020-11-02', '2020-11-03', N'Ell, Caron', N'1043 Huston St', N'Seattle', N'WA', 98101),
(2, 2, 1, '2020-11-04', '2020-11-05', N'Musk, Elon', N'789 Hollywood St', N'Puyallup', N'WA', 98371),
(3, 3, 2, '2020-11-08', '2020-11-09', N'Thom, Martin', N'567 Martinway Blvd', N'Lacey', N'WA', 98516);
GO

INSERT INTO Sales.OrderDetails
VALUES 
(1, 1, 38.99, 1),
(2, 3, 19.99, 2),
(3, 1, 38.99, 2);
GO

-------------------------------------------------------------------
-- Verify
--SELECT * FROM HR.Employees;
--GO
--SELECT * FROM Sales.Customers;
--GO
--SELECT * FROM Sales.OrderDetails;
--GO
--SELECT * FROM Sales.Orders;
--GO
--SELECT * FROM Production.Products;
--GO

--UPDATE HR.Employees
--SET zipcode = 98501
--WHERE empID = 3;
--GO
-------------------------------------------------------------------

-- aggregate function / FIND GROSS SALES
CREATE VIEW Sales.GrossSales
AS
	SELECT SUM(unitprice*qty) AS totalSales
	FROM Sales.OrderDetails;
GO

SELECT * FROM Sales.GrossSales;
GO

-- JOIN statement / FIND THE BEST EMPLOYEE
CREATE VIEW HR.BestEmployee
AS
	SELECT TOP 3
	o.orderID, e.lastname, e.firstname, SUM(d.unitprice*d.qty) AS totalSales
	FROM Sales.OrderDetails AS d
	JOIN Sales.Orders AS o
	ON o.orderID = d.orderID
	JOIN HR.Employees AS e
	ON e.empID = o.empID
	GROUP BY o.orderID, e.lastname, e.firstname
	ORDER BY totalSales DESC;
GO

SELECT * FROM HR.BestEmployee;
GO

-- Stored Procedure / FIND MOST POPULAR ITEM SOLD
CREATE OR ALTER PROCEDURE Sales.GetTopProduct
AS
BEGIN
	SELECT 
		p.productname,
		SUM(od.qty) AS [total qty sold]
	FROM Production.Products AS p
	JOIN Sales.OrderDetails AS od 
	ON od.productID = p.productID
	GROUP BY p.productname
	ORDER BY [total qty sold] DESC
END;
GO

EXEC Sales.GetTopProduct;
GO

-- 