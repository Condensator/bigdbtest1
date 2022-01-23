CREATE TYPE [dbo].[CreditOption] AS TABLE(
	[Option] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditOptionTerms] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PurchaseFactor] [decimal](8, 4) NOT NULL,
	[RenewalFactor] [decimal](8, 4) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RestockingFee] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreditApprovedStructureId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
