SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ReOpenKeptPromises] 
(
	@CustomerId BIGINT,
	@PaymentPromiseStatusOpen NVARCHAR(6),
	@PaymentPromiseStatusKept NVARCHAR(6),
	@ReceiptStatusReversed NVARCHAR(15),
	@UserId BIGINT,
	@ServerTimeStamp DATETIMEOFFSET,
	@AccessibleLegalEntities CollectionsReceiptReversalLegalEntityId READONLY
)
AS
BEGIN

	CREATE TABLE #ReversedReceipts
	(
		PaymentPromiseId BIGINT
	)

	UPDATE PTPApplications
			SET IsActive = 0, UpdatedById = @UserId, UpdatedTime = @ServerTimeStamp
		OUTPUT INSERTED.PaymentPromiseId
		INTO #ReversedReceipts
	FROM PTPApplications
		INNER JOIN
			(
				SELECT PTPApplications.PaymentPromiseId
				FROM PTPApplications
					INNER JOIN Receipts ON PTPApplications.ReceiptId = Receipts.Id
					INNER JOIN CollectionsJobContractExtracts
						ON CollectionsJobContractExtracts.ContractId = PTPApplications.ContractId
					INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
						ON AccessibleLegalEntities.LegalEntityId = CollectionsJobContractExtracts.LegalEntityId
				WHERE Receipts.Status = @ReceiptStatusReversed AND PTPApplications.IsActive = 1
						AND (@CustomerId = 0 OR PTPApplications.CustomerId = @CustomerId)
			) 
			AS PTPApplicationsReversed
				ON PTPApplications.PaymentPromiseId = PTPApplicationsReversed.PaymentPromiseId
		
			
	-- Mark PTP as OPEN if Receipt is reversed..
	UPDATE PaymentPromises
			SET Status = @PaymentPromiseStatusOpen, UpdatedById = @UserId, UpdatedTime = @ServerTimeStamp
		FROM PaymentPromises
			INNER JOIN #ReversedReceipts ON PaymentPromises.Id = #ReversedReceipts.PaymentPromiseId
		WHERE Status = @PaymentPromiseStatusKept

	DROP TABLE #ReversedReceipts;

END

GO
