SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetPrivateLabelFlag]
(
@ContractOriginationId BIGINT
)
RETURNS BIT
AS
BEGIN
DECLARE @PrivateLabel BIT
SET @PrivateLabel=
(
SELECT IsPrivateLabel
FROM ServicingDetails
JOIN ContractOriginationServicingDetails ON ServicingDetails.Id =ContractOriginationServicingDetails.ServicingDetailId
JOIN ContractOriginations ON ContractOriginationServicingDetails.ContractOriginationId =ContractOriginations.Id
WHERE ServicingDetails.IsActive=1 AND ContractOriginations.Id=@ContractOriginationId
)
RETURN ISNULL(@privatelabel,0)
END

GO
