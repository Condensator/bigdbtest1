SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReceivableForTransferBlendedItemsFromPayoff]
(
@ReceivableForTransferBlendedItemDetail ReceivableForTransferBlendedItemDetail READONLY,
@BookRecognitionRecognizeImmediately NVARCHAR(40),
@PayoffEffectiveDate DATETIME
)
AS
BEGIN
SET NOCOUNT ON
UPDATE B SET
B.EndDate = CASE WHEN RD.NewEndDate IS NOT NULL THEN RD.NewEndDate ELSE B.EndDate END,
B.IsActive = CASE WHEN RD.ToBeInactivated = 1 THEN 0 ELSE B.IsActive END
FROM
BlendedItems B
JOIN @ReceivableForTransferBlendedItemDetail RD ON B.Id = RD.BlendedItemId
WHERE
( RD.ToBeInactivated = 1
OR
(
RD.NewEndDate IS NOT NULL
AND B.BookRecognitionMode <> @BookRecognitionRecognizeImmediately
AND B.StartDate IS NOT NULL
AND B.EndDate IS NOT NULL
AND (B.StartDate < @PayoffEffectiveDate OR B.EndDate > @PayoffEffectiveDate)
)
)
END

GO
