CREATE TYPE [dbo].[QuoteLeaseType] AS TABLE(
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCloseEndLease] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsFloatRate] [bit] NOT NULL,
	[VATBasis] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[MinimumResidualValuePercentage] [decimal](5, 2) NULL,
	[DealProductTypeId] [bigint] NULL,
	[DealTypeId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
