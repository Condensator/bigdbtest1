CREATE TYPE [dbo].[AssetServiceHistory] AS TABLE(
	[RowNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ServiceDate] [date] NOT NULL,
	[AccountingDocumentNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ServiceAmountInclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ServiceAmountInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ServiceConfigId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
