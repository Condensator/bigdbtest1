SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetInactiveContractsSundries]
(
   @IsLoansApplicable bit
)
AS
DECLARE @ReceivableCodeCount int;
DECLARE @ReceivableCode NVARCHAR(200);
DECLARE @Count int = 1;
DECLARE @Query Nvarchar(max) = N'';
DECLARE @Query2 Nvarchar(max) = N'';
DECLARE @Query3 Nvarchar(max) = N'';
DECLARE @Query4 Nvarchar(max) = N'';
DECLARE @Query5 Nvarchar(max) = N'';
DECLARE @Query6 Nvarchar(max) = N'';
SELECT @ReceivableCodeCount = Count(DISTINCT 'S_' + ReceivableCodeName) FROM stgSundry 
IF @ReceivableCodeCount > 0 
BEGIN
SELECT Distinct 'S_' + REPLACE(ReceivableCodeName,'''','') Source ,'T_' + REPLACE(ReceivableCodeName,'''','') Target, REPLACE(ReceivableCodeName,'''','') ReceivableCodeName,  0 RowId Into #ReceivableCodes from stgSundry 
UPDATE #ReceivableCodes SET RowId = RS.ROWID FROM  #ReceivableCodes JOIN (SELECT  ROW_NUMBER() OVER(ORDER BY Target) ROWID, Target FROM #ReceivableCodes ) AS RS ON RS.Target = #ReceivableCodes.Target 

SET @Query = N'CREATE TABLE #SundryDetail 
			 (CustomerNumber NVARCHAR(40),' ;
WHILE @Count<=@ReceivableCodeCount
BEGIN
IF @Count <=20 
BEGIN
SET @Query = @Query +  (SELECT QUOTENAME(Source) FROM #ReceivableCodes WHERE RowId = @Count) + ' Decimal(16,2) DEFAULT(0), '  +  (SELECT QUOTENAME(Target) FROM #ReceivableCodes WHERE RowId = @Count) + ' Decimal(16,2) DEFAULT(0), ' +  QUOTENAME((SELECT ReceivableCodeName FROM #ReceivableCodes WHERE RowId = @Count) +'_Matched')   + ' NVARCHAR(10) ' + (CASE WHEN @Count<@ReceivableCodeCount THEN ',' ELSE ' )' END);
END
ELSE
BEGIN 
SET @Query2 = @Query2 +  (SELECT QUOTENAME(Source) FROM #ReceivableCodes WHERE RowId = @Count) + ' Decimal(16,2) DEFAULT(0), '  +  (SELECT QUOTENAME(Target) FROM #ReceivableCodes WHERE RowId = @Count) + ' Decimal(16,2) DEFAULT(0), ' +  QUOTENAME((SELECT ReceivableCodeName FROM #ReceivableCodes WHERE RowId = @Count) +'_Matched')   + ' NVARCHAR(10) ' + (CASE WHEN @Count<@ReceivableCodeCount THEN ',' ELSE ' )' END);
END
SET @Count = @Count + 1 ;
END
SET @Query3 =  N'SELECT 
	*
INTO #SundryFromSource
FROM
	(
		SELECT 
			 CAST(stgCustomer.CustomerNumber AS NVARCHAR(40)) CustomerNumber
			,QUOTENAME(''S_''+REPLACE(stgSundry.ReceivableCodeName,'''''''','''')) ReceivableCodeName
			,Sum(stgSundry.Amount_Amount) Amount_Amount
		FROM	
			stgCustomer
			INNER JOIN stgSundry
				ON stgCustomer.CustomerNumber = stgSundry.CustomerPartyNumber
				AND stgSundry.EntityType = ''CU''
		GROUP BY  
			 stgCustomer.CustomerNumber
			,stgSundry.ReceivableCodeName	
	)AS S

SELECT 
	*
INTO #SundryFromTarget
FROM
	(
		SELECT 
			 CAST(Parties.PartyNumber AS NVARCHAR(40)) CustomerNumber 
			,QUOTENAME(''T_''+REPLACE(ReceivableCodes.Name,'''''''','''')) ReceivableCodeName
			,Sum(Receivables.TotalAmount_Amount) Amount_Amount
		FROM	
			Receivables
			INNER JOIN Parties
				ON Receivables.EntityId = Parties.Id
				AND Receivables.EntityType = ''CU''
				AND Receivables.SourceTable in (''Sundry'')
			INNER JOIN ReceivableCodes
				ON Receivables.ReceivableCodeId = ReceivableCodes.Id
			
		GROUP BY  
			 Parties.PartyNumber
			,ReceivableCodes.Name	

	)AS T'
	
SET @Query4 = N' INSERT INTO #SundryDetail (CustomerNumber) SELECT CustomerNumber FROM #SundryFromSource UNION SELECT CustomerNumber FROM #SundryFromTarget '

SET @Count = 1
WHILE @Count<=@ReceivableCodeCount
BEGIN
SELECT @ReceivableCode = QUOTENAME(Source) From #ReceivableCodes WHERE RowId = @Count
SET @Query4 = @Query4 +  ' UPDATE #SundryDetail SET '+ @ReceivableCode + ' = Amount_Amount FROM  #SundryDetail INNER JOIN #SundryFromSource ON #SundryDetail.CustomerNumber = #SundryFromSource.CustomerNumber 
						  AND #SundryFromSource.ReceivableCodeName = '''  + @ReceivableCode +'''';
SET @Count = @Count + 1 ;
END
SET @Count = 1

WHILE @Count<=@ReceivableCodeCount
BEGIN
SELECT @ReceivableCode = QUOTENAME(Target) From #ReceivableCodes WHERE RowId = @Count
SET @Query5 = @Query5 +  ' UPDATE #SundryDetail SET '+ @ReceivableCode + ' = Amount_Amount FROM  #SundryDetail INNER JOIN #SundryFromTarget ON #SundryDetail.CustomerNumber = #SundryFromTarget.CustomerNumber 
						  AND #SundryFromTarget.ReceivableCodeName = '''  + @ReceivableCode +'''';
SET @Count = @Count + 1 ;
END

SET @Count = 1

WHILE @Count<=@ReceivableCodeCount
BEGIN
SELECT @ReceivableCode = ReceivableCodeName From #ReceivableCodes WHERE RowId = @Count
SET @Query5 = @Query5 +  ' UPDATE #SundryDetail SET ['+ @ReceivableCode + '_Matched] = CASE WHEN  [S_' +  @ReceivableCode + '] = [T_' +  @ReceivableCode + '] THEN ''True'' ELSE ''False'' END FROM  #SundryDetail INNER JOIN #SundryFromSource ON #SundryDetail.CustomerNumber = #SundryFromSource.CustomerNumber 
						   WHERE #SundryFromSource.ReceivableCodeName = QUOTENAME(''' +'S_' +  @ReceivableCode +''''+')';
SET @Query5 = @Query5 + ' Update #SundryDetail set ['+@ReceivableCode+'_Matched] = ''True'' WHERE [S_' +  @ReceivableCode + '] = ''0.00'' AND [T_' +  @ReceivableCode + '] = ''0.00'''
SET @Count = @Count + 1 ;
END
SET @Query = @Query + @Query2 + @Query3 + @Query4 + @Query5 + @Query6 + ' SELECT * FROM #SundryDetail '
EXEC sp_executesql @Query
DROP TABLE #ReceivableCodes
IF OBJECT_ID('tempdb..#SundryDetail') IS NOT NULL  DROP TABLE #SundryDetail
IF OBJECT_ID('tempdb..#SundryFROMSource') IS NOT NULL  DROP TABLE #SundryFROMSource
IF OBJECT_ID('tempdb..#SundryFROMTarget') IS NOT NULL  DROP TABLE #SundryFROMTarget
END

GO
