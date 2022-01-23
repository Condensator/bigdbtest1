CREATE TYPE [dbo].[ReceivableTaxesReversalParameters] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsDummy] [bit] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[ReceivableTaxId] [bigint] NULL,
	[IsSuccess] [bit] NOT NULL
)
GO
