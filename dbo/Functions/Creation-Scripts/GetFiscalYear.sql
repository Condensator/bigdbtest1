SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetFiscalYear](@TaxFiscalYearBeginMonthNo nvarchar(20), @TerminationDate datetime)  
RETURNS int   
AS   
-- fiscal year returns from TaxFiscalYearBeginMonthNo and Termination Date
BEGIN  
    DECLARE @numericmonth int, @LastDateOfMonth datetime, @FIYear VARCHAR(20);  
			IF(@TaxFiscalYearBeginMonthNo = 'January')
            BEGIN
                SET @numericmonth = 1;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'February')
            BEGIN
                SET @numericmonth = 2;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'March')
            BEGIN
               SET @numericmonth = 3;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'April')
            BEGIN
                SET @numericmonth = 4;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'May')
            BEGIN
                SET @numericmonth = 5;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'June')
            BEGIN
                SET @numericmonth = 6;
            END
            ELSE IF (@TaxFiscalYearBeginMonthNo = 'July')
            BEGIN
                SET @numericmonth = 7;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'August')
            BEGIN
                SET @numericmonth = 8;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'September')
            BEGIN
                SET @numericmonth = 9;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'October')
            BEGIN
                SET @numericmonth = 10;
            END
            ELSE IF(@TaxFiscalYearBeginMonthNo = 'November')
			BEGIN
			  SET @numericmonth = 11 
			END
			ELSE IF(@TaxFiscalYearBeginMonthNo = 'December')
			BEGIN 
			  SET @numericmonth = 12
			END 

    SET @LastDateOfMonth = EOMONTH(@TerminationDate)

	SET @FIYear = (CASE WHEN (MONTH(@LastDateOfMonth)) <= 3 THEN convert(varchar(4), YEAR(@LastDateOfMonth)-1) 
	ELSE convert(varchar(4),YEAR(@LastDateOfMonth))END)

	RETURN @FIYear
END

GO
