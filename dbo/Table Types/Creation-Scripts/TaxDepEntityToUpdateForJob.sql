CREATE TYPE [dbo].[TaxDepEntityToUpdateForJob] AS TABLE(
	[Id] [bigint] NULL,
	[IsComputationPending] [bit] NULL,
	[IsGLPosted] [bit] NULL,
	[FxTaxBasisAmount_Amount] [decimal](16, 2) NULL,
	[FxTaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL
)
GO
