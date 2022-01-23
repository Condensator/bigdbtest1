SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  

CREATE PROCEDURE [dbo].[GetNonVertexTaxAssessedForOutStandingReceivables]  
(  
	@JobStepInstanceId BIGINT
)  
AS   
SET NOCOUNT ON;  
  
BEGIN  

SELECT ReceivableId,ReceivableDetailId,CalculatedTax,ImpositionType,EffectiveRate
        ,ExemptionType,ExemptionAmount
		FROM NonVertexTaxExtract WHERE JobStepInstanceId = @JobStepInstanceId

END

GO
