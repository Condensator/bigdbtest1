CREATE TYPE [dbo].[AssumptionTaxAssessmentTaxBasisType] AS TABLE(
	[IsOtherBasisType] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxBasisTypeId] [bigint] NULL,
	[AssumptionTaxAssessmentDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
