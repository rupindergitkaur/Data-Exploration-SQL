
-- Creating tables

CREATE TABLE Customer (
    Customer_Id int PRIMARY KEY identity(1,1),
	FirstName varchar(100) NOT NULL,
	LastName varchar(100) NOT NULL,
	Dob date,
	Phone varchar(25),
	Email varchar(100),
	Street varchar(200),
	City varchar(100),
	State varchar(100),
	ZipCode int
);

CREATE TABLE Booking(
    Booking_Id int identity(1,1),
	Booking_Ref varchar(50),
	Customer_Id int,
	Airline char(2) NOT NULL,
	GDS varchar(50) NOT NULL,
	TicketNumber varchar(100),
	IssuedDate date,
	Agent varchar(50),
	PRIMARY KEY(Booking_Id) ,
	FOREIGN KEY(Customer_Id) REFERENCES Customer(Customer_Id)
);

CREATE TABLE Transactions(
	Booking_Id int,
	FOP varchar(20) NOT NULL,
	TotalCost float,
	Comm float,
	Status varchar(20),
	Description varchar(200),
	FOREIGN KEY(Booking_Id) REFERENCES Booking(Booking_Id)
);

CREATE TABLE Invoice(
	Invoice_Num int,
	Booking_Ref varchar(50),
	Vendor varchar(50) NOT NULL,
	PRIMARY KEY(Invoice_Num),
);


---Import Data and inserting into tables

INSERT INTO Customer(Customer_Id,FirstName,LastName,Dob,Phone,Email,Street,City,State,ZipCode) 
SELECT  Customer_Id,FirstName,LastName,Dob,Phone,Email,Street,City,State,ZipCode FROM Customer$;

SET IDENTITY_INSERT iNVOICE ON;

INSERT INTO Booking(Booking_Id,Booking_Ref,Customer_Id,Airline,GDS,TicketNumber,IssuedDate,Agent) 
SELECT Booking_Id,Booking_Ref,Customer_Id,Airline,GDS,TicketNumber,IssuedDate,Agent FROM Booking$;

--to change or add columns in  a table
ALTER TABLE Booking alter column  Booking_Id INT  NOT NULL;
ALTER TABLE Booking$  ADD PRIMARY KEY(Booking_Id);
ALTER TABLE Booking$  ADD FOREIGN KEY(Customer_Id) REFERENCES Customer(Customer_Id);



INSERT INTO Transactions(Booking_Id,FOP,TotalCost,Comm,Status,Description) 
select Booking_Id,FOP,TotalCost,Comm,Status, Description FROM Transactions$;

INSERT INTO Invoice(Invoice_Num,Booking_Ref,Vendor) SELECT * FROM Invoice$;


-- Select Data that are going to be used

SELECT * FROM Customer;

SELECT * FROM Booking;

SELECT * FROM  Transactions;

SELECT * FROM Invoice;

 
 -- To find which Airlines has max tickets sold

 SELECT Airline,Count(Airline) as MaxSoldTicketsByAirline
  FROM Booking 
  GROUP BY Airline
  ORDER BY MaxSoldTicketsByAirline  DESC ;


 -- To find daily Sale 

 SELECT b.Booking_id, b.Booking_Ref, b.Airline,b.IssuedDate,t.Comm
 FROMBooking b
 JOIN Transactions t
 ON  b.Booking_Id = t.Booking_Id;
 
 SELECT b.IssuedDate, Sum(t.Comm) as TotalSalePerDay
FROM Booking  as b,Transactions t
WHERE b.Booking_Id = t.Booking_Id
GROUP BY b.IssuedDate;




 -- Which Agent has highest Monthly Sale 
 SELECT DISTINCT 
  b.Agent ,FORMAT(b.IssuedDate,'MMM') aS Month,
  Sum(t.Comm)  OVER ( partition by Agent) as TotalSale
  FROM Booking b
  JOIN Transactions t
  ON b.Booking_Id = t.Booking_Id
  ORDER BY TotalSale DESC;



  
  

 

 -- Find total  sales per month by using Procedure
   
   DROP PROCEDURE IF EXISTS  MonthlySales;

   CREATE PROCEDURE MonthlySales @Month nvarchar(30)
   as
     SELECT Sum(t.Comm) 
	 FROM Booking b
	 JOIN Transactions t
	 ON b.Booking_Id = t.Booking_Id
	 WHERE FORMAT(b.IssuedDate,'MMM') = @Month;
	
	 EXEC MonthlySales  @Month ='Sep';



	 
 -- With Cte total sales

    With TotalSales (Agent ,Month,Comm)
	as 
	(
		SELECT DISTINCT
		b.Agent ,FORMAT(b.IssuedDate,'MMM') as Month,
		Sum(t.Comm)  OVER ( partition by Agent ) as TotalSale
		FROM Booking b
		JOIN Transactions t
		ON b.Booking_Id = t.Booking_Id
		--order by TotalSale desc;
     )
	SELECT * FROM  TotalSales ORDER BY Comm DESC;

 -- Use Join to print invoices for a particular customer with mutiple tables.

 
 SELECT i.Invoice_Num,i.Booking_Ref,Concat( c.FirstName,' ',c. LastName ) as CustomerName , b.TicketNumber,t.TotalCost,t.FOP
 FROM Invoice i  Join Booking b
 ON i.Booking_Ref = b.Booking_Ref 
 JOIN Transactions t
 ON t.Booking_Id = b.Booking_Id
 JOIN Customer c
 ON c.Customer_Id =b.Customer_Id;


  -- To find the Customers who has not purchased the ticket's yet using subqueries

  SELECT Customer_id, FirstName, LastName, Phone  FROM Customer
  WHERE Customer_Id IN (SELECT Customer_id FROM Booking
  WHERE Booking_Id  IN (Select Booking_Id FROM Transactions WHERE Upper(Status) ='PENDING'));



  --To  Calculate total Sales per month
    SELECT  year(b.IssuedDate) as Year,FORMAT(b.IssuedDate,'MMM') as Month,Sum(Comm) as TotalSales
	FROM Booking b,Transactions t
	WHERE b.Booking_Id =t.Booking_Id
	GROUP BY  year(b.IssuedDate),FORMAT(b.IssuedDate,'MMM');
	

	--To Calulate Total Average Sale Yearly
	  
	SELECT  year(b.IssuedDate) as Year, Sum(t.Comm) as TotalSales, Avg(t.Comm) as AverageSales
	FROM Booking b,Transactions t
	WHERE b.Booking_Id =t.Booking_Id
	GROUP BY year(b.IssuedDate);

 -- Creating View to store data for later visualization
     
	 CREATE VIEW MonthlySale
	  as
	      SELECT  year(b.IssuedDate) as Year,FORMAT(b.IssuedDate,'MMM') as Month,Sum(Comm) as TotalSales
		  FROM Booking b,Transactions t
		  WHERE b.Booking_Id =t.Booking_Id
		  GROUP BY  year(b.IssuedDate),FORMAT(b.IssuedDate,'MMM');

 
 SELECT  * FROM Transactions$;

 -- To delete records 

 DELETE FROM  Transactions$;
 DELETE FROM Booking$;
 DELETE FROM Customer$;

SET IDENTITY_INSERT Booking on;

-- to add more records in existing table
INSERT INTO  Customer(Customer_Id,FirstName,LastName,Dob,Phone,Email,Street,City,State,ZipCode) 
SELECT  Customer_Id,FirstName,LastName,Dob,Phone,Email,Street,City,State,ZipCode FROM Customer$
WHERE Customer_Id > 20;

INSERT INTO Booking(Booking_Id,Booking_Ref,Customer_Id,Airline,GDS,TicketNumber,IssuedDate,Agent) 
SELECT Booking_Id,Booking_Ref,Customer_Id,Airline,GDS,TicketNumber,IssuedDate,Agent FROM Booking$
WHERE Booking_Id > 20;


INSERT INTO Transactions(Booking_Id,FOP,TotalCost,Comm,Status,Description) 
SELECT Booking_Id,FOP,TotalCost,Comm,Status, Description FROM Transactions$;

SELECT  * FROM Transactions;








