CREATE TABLE QuarterTbl ( 
    QuarterID INT NOT NULL IDENTITY PRIMARY KEY,
    QuarterItem varchar(2)
);

INSERT INTO QuarterTbl([QuarterItem]) 
VALUES ('Q1'), ('Q2'), ('Q3'), ('Q4');

CREATE TABLE ProductSales ( 
    ProductID INT NOT NULL IDENTITY PRIMARY KEY,
    ProductName varchar(10),
    QuarterID int,
    Year varchar(5),
    Sales int
    FOREIGN KEY (QuarterID) REFERENCES QuarterTbl(QuarterID)
);

INSERT INTO ProductSales([ProductName],[QuarterID],[Year],[Sales]) 
VALUES
    ('ProductA', 1, 'Y2017', 100),
    ('ProductA', 2, 'Y2018', 150),
    ('ProductA', 2, 'Y2018', 200),
    ('ProductA', 1, 'Y2019', 300),
    ('ProductA', 2, 'Y2020', 500),
    ('ProductA', 3, 'Y2021', 450),
    ('ProductA', 1, 'Y2022', 675),
    ('ProductB', 2, 'Y2017', 0),
    ('ProductB', 1, 'Y2018', 900),
    ('ProductB', 3, 'Y2019', 1120),
    ('ProductB', 4, 'Y2020', 750),
    ('ProductB', 3, 'Y2021', 1500),
    ('ProductB', 2, 'Y2022', 1980)
;

CREATE OR ALTER PROCEDURE GetProductSalesReport 
    @columns NVARCHAR(MAX)
AS 
DECLARE  @sql NVARCHAR(MAX);

SET @sql = 'SELECT * FROM 
(
    SELECT PS.ProductName, Q.QuarterItem, PS.Year, PS.Sales
    FROM ProductSales PS 
    INNER JOIN QuarterTbl Q
        ON PS.QuarterID = Q.QuarterID
) t
PIVOT (
    SUM(Sales) 
    FOR [Year] IN ( ' + @columns + ')
) AS PV 
ORDER BY 1, 2;';

-- execute the dynamic SQL
EXECUTE sp_executesql @sql;
GO

