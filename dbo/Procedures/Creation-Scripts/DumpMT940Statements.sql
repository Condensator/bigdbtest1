SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DumpMT940Statements]
(
@FlattenedStatements MT940DumpType READONLY,
@JobStepInstanceId BIGINT,
@FileName NVARCHAR(400),
@UserId BIGINT
)
AS
SET NOCOUNT ON;
BEGIN

SELECT * INTO #StmtDetails FROM (SELECT * FROM @FlattenedStatements FlattenedStatements) AS stmts

INSERT INTO MT940File_Dump
(
 TransactionReferenceNumber 
,RelatedReference  
,AccountIdentification 
,StatementNumber 
,SequenceNumber 
,OpeningBalance_DC 
,OpeningBalanceAsOf 
,OpeningBalance_Currency 
,OpeningBalance_Amount 
,ClosingBalance_DC
,ClosingBalanceAsOf 
,ClosingBalance_Currency 
,ClosingBalance_Amount 
,ClosingAvailableBalance_DC 
,ClosingAvailableBalanceAsOf 
,ClosingAvailableBalance_Currency
,ClosingAvailableBalance_Amount
,TransValueDate 
,TransEntryDate 
,Trans_DC 
,TransFundsCode 
,TransactionAmount_Amount 
,TransactionAmount_Currency 
,TransTypeIdCode 
,TransCustomerReference
,TransSupplementaryDetails 
,TransBankReferenceNumber
,InformationToOwner 
,JobStepInstanceID 
,IsValid
,CreatedById 
,FileName
,CreatedTime 
) 
SELECT
 TransactionReferenceNumber 
,RelatedReference  
,AccountIdentification 
,StatementNumber 
,SequenceNumber 
,OpeningBalance_DC 
,OpeningBalanceAsOf 
,OpeningBalance_Currency 
,OpeningBalance_Amount 
,ClosingBalance_DC
,ClosingBalanceAsOf 
,ClosingBalance_Currency 
,ClosingBalance_Amount 
,ClosingAvailableBalance_DC 
,ClosingAvailableBalanceAsOf 
,ClosingAvailableBalance_Currency
,ClosingAvailableBalance_Amount
,TransValueDate 
,TransEntryDate 
,Trans_DC 
,TransFundsCode 
,Transaction_Amount 
,Transaction_Currency 
,TransTypeIdCode 
,TransCustomerReference
,TransSupplementaryDetails 
,TransBankReferenceNumber
,InformationToOwner 
,@JobStepInstanceId
,1
,@UserId
,@FileName
,GETDATE()
FROM #StmtDetails


END

GO
