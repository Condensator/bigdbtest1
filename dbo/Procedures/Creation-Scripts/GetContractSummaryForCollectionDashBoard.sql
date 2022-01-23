SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[GetContractSummaryForCollectionDashBoard] (
    @CustomerId BIGINT,
	@CollectionWorkListId BIGINT,
	@IsOtherContractFilter BIT,
	@EntityTypeCT NVarChar(2),
	@ReceiptEntityTypeLease NVarChar(14),
	@ReceiptEntityTypeLoan NVarChar(14),
	@ReceiptStatusPosted  NVarChar(15),
	@PartyContactTypeMain NVarChar(21),
	@PartyContactTypeCollection NVarChar(21),
	@StartingRowNumber INT,
	@EndingRowNumber INT,
	@OrderBy NVARCHAR(6) = NULL,
	@OrderColumn NVARCHAR(MAX) = NULL,
	@WHEREClause NVARCHAR(MAX) = ''
)
AS 
BEGIN 

SET NOCOUNT ON;
   
   CREATE TABLE #CollectionWorkListContractDetails
   (     
	 ContractId						    BIGINT,
	 CollectionWorkListContractDetailId BIGINT,
	 CollectionWorkListId			    BIGINT,
	 CustomerId                         BIGINT,
	 RemitToId                          BIGINT NULL,
	 ContractType						NVarChar(14),
	 Currency                           NVarChar(3),
	 SequenceNumber					    NVarchar(max),
	 AmountPastDue_Amount               Decimal(18,2),
	 ContractBalanceRemaining_Amount    Decimal(18,2),
	 CommencementDate				    Date,
	 MaturityDate					    Date,
	 LastPaidDate					    Date,
	 OriginationSourceType				NVarChar(8),
	 ContactName					    NVarchar(max), 
	 UpdatedDate					    Date
   );
     
   INSERT INTO #CollectionWorkListContractDetails (ContractId,CollectionWorkListContractDetailId,CollectionWorkListId,CustomerId,RemitToId,ContractType,Currency,UpdatedDate)
   SELECT
      CollectionWorkListContractDetails.ContractId,
	  CollectionWorkListContractDetails.Id,
	  CollectionWorkLists.Id,
	  CollectionWorkLists.CustomerId,
	  CollectionWorkLists.RemitToId,
	  Contracts.ContractType,
	  CurrencyCodes.ISO,
	  Convert(DATE,
	       CASE WHEN CollectionWorkListContractDetails.UpdatedTime IS NOT NULL AND CollectionWorkListContractDetails.IsWorkCompleted = 1 
	            THEN CollectionWorkListContractDetails.UpdatedTime 
		        ELSE
				 CollectionWorkListContractDetails.CreatedTime
		   END) UpdatedDate
   FROM 
      CollectionWorkLists
   INNER JOIN CollectionWorkListContractDetails
      ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
   INNER JOIN Contracts 
      ON CollectionWorkListContractDetails.ContractId = Contracts.Id
   INNER JOIN Currencies 
	    ON Contracts.CurrencyId = Currencies.Id
    INNER JOIN CurrencyCodes 
	    ON Currencies.CurrencyCodeId = CurrencyCodes.Id 
   WHERE CollectionWorkLists.CustomerId = @CustomerId
   AND (( @IsOtherContractFilter = 1 AND CollectionWorkLists.Id <> @CollectionWorkListId AND CollectionWorkListContractDetails.IsWorkCompleted = 0 ) OR ( @IsOtherContractFilter = 0 AND CollectionWorkLists.Id = @CollectionWorkListId))    
   
   Select Distinct ContractId,RemitToId,CustomerId into #ContractDetails from #CollectionWorkListContractDetails

   UPDATE #CollectionWorkListContractDetails
   SET AmountPastDue_Amount = TotalPastDueAmount
   FROM
   (
     SELECT
		 #ContractDetails.ContractId
		,Sum(ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) TotalPastDueAmount
     FROM 
		#ContractDetails  
     INNER JOIN ReceivableInvoiceDetails   
		ON #ContractDetails.ContractId = ReceivableInvoiceDetails.EntityId AND 
		   ReceivableInvoiceDetails.EntityType = @EntityTypeCT
     INNER JOIN ReceivableInvoices   
		ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND 
		   #ContractDetails.CustomerId = ReceivableInvoices.CustomerId AND
		   ReceivableInvoiceDetails.IsActive=1 AND 
		   ReceivableInvoices.IsActive=1
	 INNER JOIN ReceivableInvoiceDeliquencyDetails 
		ON ReceivableInvoices.Id = ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId
	 WHERE (
				-- To fetch records belonging to worklist remit to
				(#ContractDetails.RemitToId IS NOT NULL AND #ContractDetails.RemitToId = ReceivableInvoices.RemitToId AND ReceivableInvoices.IsPrivateLabel = 1)
				OR (#ContractDetails.RemitToId IS NULL AND ReceivableInvoices.IsPrivateLabel = 0)
			)

     GROUP BY 
		#ContractDetails.ContractId
	)	AS ContractPastDue
	WHERE #CollectionWorkListContractDetails.ContractId = ContractPastDue.ContractId
		


   UPDATE #CollectionWorkListContractDetails
      SET SequenceNumber = LeaseInfoes.SequenceNumber,
          CommencementDate = LeaseInfoes.CommencementDate,
          MaturityDate = LeaseInfoes.MaturityDate,
          OriginationSourceType = LeaseInfoes.OriginationSourceType
   FROM
   (
    SELECT
	   #CollectionWorkListContractDetails.ContractId,
	   Contracts.SequenceNumber,
	   LeaseFinanceDetails.CommencementDate,
	   LeaseFinanceDetails.MaturityDate,
	   OriginationSourceTypes.Name OriginationSourceType
	FROM
	   #CollectionWorkListContractDetails 
	JOIN Contracts
	   ON #CollectionWorkListContractDetails.ContractId = Contracts.Id
	JOIN LeaseFinances 
	   ON Contracts.Id = LeaseFinances.ContractId AND IsCurrent = 1
    JOIN LeaseFinanceDetails 
	   ON LeaseFinances.Id = LeaseFinanceDetails.Id 
    LEFT JOIN ContractOriginations 
	   ON LeaseFinances.ContractOriginationId = ContractOriginations.Id 
    LEFT JOIN OriginationSourceTypes 
	   ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id AND OriginationSourceTypes.IsActive = 1
    ) AS LeaseInfoes
	WHERE #CollectionWorkListContractDetails.ContractId = LeaseInfoes.ContractId

	UPDATE #CollectionWorkListContractDetails
      SET SequenceNumber = LoanInfoes.SequenceNumber,
          CommencementDate = LoanInfoes.CommencementDate,
          MaturityDate = LoanInfoes.MaturityDate,
          OriginationSourceType = LoanInfoes.OriginationSourceType
    FROM
    (
     SELECT
	   #CollectionWorkListContractDetails.ContractId,
	   Contracts.SequenceNumber,
	   LoanFinances.CommencementDate,
	   LoanFinances.MaturityDate,
	   OriginationSourceTypes.Name OriginationSourceType
	FROM
	   #CollectionWorkListContractDetails 
	JOIN Contracts
	   ON #CollectionWorkListContractDetails.ContractId = Contracts.Id
	JOIN LoanFinances 
	   ON Contracts.Id = LoanFinances.ContractId AND IsCurrent = 1
    LEFT JOIN ContractOriginations 
	   ON LoanFinances.ContractOriginationId = ContractOriginations.Id
    LEFT JOIN OriginationSourceTypes 
	   ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id AND OriginationSourceTypes.IsActive = 1
    ) AS LoanInfoes
	WHERE #CollectionWorkListContractDetails.ContractId = LoanInfoes.ContractId

    UPDATE #CollectionWorkListContractDetails
      SET ContractBalanceRemaining_Amount = ContractReceivables.ContractBalanceRemaining_Amount 
	  FROM
    (
	 Select 
	   #ContractDetails.ContractId,
	   Sum(Receivables.TotalBalance_Amount) ContractBalanceRemaining_Amount 
	 From 
	 #ContractDetails
	 join Receivables on #ContractDetails.ContractId = Receivables.EntityId AND Receivables.EntityType = @EntityTypeCT AND Receivables.CustomerId = #ContractDetails.CustomerId
	 join ReceivableCodes on Receivables.ReceivableCodeId = ReceivableCodes.Id
	 join ReceivableTypes on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
	 WHERE Receivables.IsActive = 1 
	   AND ReceivableCodes.IsActive = 1 
	   AND ReceivableTypes.IsActive = 1
	   AND ReceivableTypes.IsRental = 1	   
	 Group BY #ContractDetails.ContractId
    ) AS ContractReceivables
	WHERE #CollectionWorkListContractDetails.ContractId = ContractReceivables.ContractId
    
	
	UPDATE #CollectionWorkListContractDetails
     SET LastPaidDate = ContractReceipts.LastPaidDate
    FROM
    (
	  SELECT 
	    #CollectionWorkListContractDetails.ContractId,
	    Max(Receipts.ReceivedDate) LastPaidDate
	  From Receipts
	  JOIN #CollectionWorkListContractDetails on Receipts.ContractId = #CollectionWorkListContractDetails.ContractId 
	  WHERE Receipts.Status = @ReceiptStatusPosted 
	    AND Receipts.EntityType IN (@ReceiptEntityTypeLease,@ReceiptEntityTypeLoan)
	  Group BY #CollectionWorkListContractDetails.ContractId
    ) AS ContractReceipts
	WHERE #CollectionWorkListContractDetails.ContractId = ContractReceipts.ContractId
	
	CREATE TABLE #ContractContactInfo
   (
     Id                               BIGINT IDENTITY(1,1) PRIMARY KEY,
	 ContractContactId                BIGINT,
	 ContractId 					  BIGINT,
     ContactSortingOrder              BIGINT,
	 ContactName                      NVarChar(max),
	 PartyContactId                   BIGINT,
	 RowNumber				          BIGINT NULL
   );

   INSERT INTO #ContractContactInfo
   SELECT  
    ContractContacts.Id ContractContactId,
    ContractContacts.ContractId,
	CASE WHEN PartyContactTypes.ContactType = @PartyContactTypeCollection THEN 1 
	     WHEN PartyContactTypes.ContactType = @PartyContactTypeMain  THEN 2
		 ELSE 3 
    END ContactSortingOrder,
	PartyContacts.FullName PartyContactName,
	PartyContacts.Id PartyContactId,
	NULL
   FROM  #CollectionWorkListContractDetails
   INNER JOIN ContractContacts  ON #CollectionWorkListContractDetails.ContractId = ContractContacts.ContractId  
   INNER JOIN PartyContacts ON ContractContacts.PartyContactId = PartyContacts.Id 
   LEFT JOIN PartyContactTypes  on PartyContacts.Id = PartyContactTypes.PartyContactId
   where ContractContacts.IsActive=1 AND PartyContacts.IsActive=1
   AND ( PartyContactTypes.Id IS NULL OR  PartyContactTypes.IsActive=1)  
    

   UPDATE #ContractContactInfo
   SET RowNumber=  row_num
   from #ContractContactInfo 
   JOIN 
   (
      select
	   Id
	   ,ROW_NUMBER() OVER (
	   partition by ContractId
	   ORDER BY ContactSortingOrder,ContractContactId 
      ) row_num
      from #ContractContactInfo 
   ) AS OrderedContacts ON #ContractContactInfo.Id= OrderedContacts.Id  
   
   UPDATE #CollectionWorkListContractDetails
   SET #CollectionWorkListContractDetails.ContactName = #ContractContactInfo.ContactName
   FROM #ContractContactInfo
   JOIN #CollectionWorkListContractDetails
      ON #ContractContactInfo.ContractId = #CollectionWorkListContractDetails.ContractId
   WHERE RowNumber = 1

    
      ------------- DYNAMIC QUERY ----------	

   DECLARE @SkipCount BIGINT
   DECLARE @TakeCount BIGINT

   SET @SkipCount = @StartingRowNumber - 1;

   SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;
    
  DECLARE @OrderStatement NVARCHAR(MAX) = 
  CASE 
	WHEN @OrderColumn='SequenceNumber' THEN 'SequenceNumber' + ' ' + @OrderBy
	WHEN @OrderColumn='ContractType.Value' THEN 'ContractType'  + ' ' + @OrderBy
	WHEN @OrderColumn='UpdatedDate' THEN 'UpdatedDate'  + ' ' + @OrderBy
	WHEN @OrderColumn='ContactName' THEN 'ContactName'  + ' ' + @OrderBy
	WHEN @OrderColumn='CommencementDate' THEN 'CommencementDate'  + ' ' + @OrderBy
	WHEN @OrderColumn='MaturityDate' THEN 'MaturityDate'  + ' ' + @OrderBy
	WHEN @OrderColumn='LastPaidDate' THEN 'LastPaidDate'  + ' ' + @OrderBy
	WHEN @OrderColumn='OriginationSourceType.Value' THEN 'OriginationSourceType'  + ' ' + @OrderBy
	WHEN @OrderColumn='AmountPastDue.Amount' THEN 'AmountPastDue_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='AmountPastDue.Currency' THEN 'AmountPastDue_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='ContractBalanceRemaining.Amount' THEN 'ContractBalanceRemaining_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='ContractBalanceRemaining.Currency' THEN 'ContractBalanceRemaining_Amount' + ' ' + @OrderBy
  ELSE 'AmountPastDue_Amount DESC'  END
 
   
  DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + ' 
	
  DECLARE @Count BIGINT = (	
    SELECT  
         COUNT(CollectionWorkListContractDetailId)
    FROM
    #CollectionWorkListContractDetails
    WHERE '+ @WHEREClause + ' 1 = 1
	) ;
	
    SELECT
	    CollectionWorkListContractDetailId
	   ,SequenceNumber		
	   ,ContractType			   
	   ,AmountPastDue_Amount  
	   ,Currency AmountPastDue_Currency        
	   ,ContractBalanceRemaining_Amount  ContractBalanceRemaining_Amount   
	   ,Currency ContractBalanceRemaining_Currency       
	   ,CommencementDate				    
	   ,MaturityDate					    
	   ,LastPaidDate					     
	   ,OriginationSourceType				    
	   ,ContactName					    
	   ,UpdatedDate					    
	   ,@Count TotalRecords
    FROM 
	  #CollectionWorkListContractDetails
	WHERE '+ @WHEREClause + ' 1 = 1
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END
	
EXEC sp_executesql @SelectQuery,N'@TakeCount BIGINT,@SkipCount BIGINT',@TakeCount,@SkipCount

	DROP TABLE #CollectionWorkListContractDetails
	DROP TABLE #ContractContactInfo

END

GO
