CREATE TYPE [dbo].[CreditSummaryExposure] AS TABLE(
	[ExposureType] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Direct_Amount] [decimal](24, 2) NOT NULL,
	[Direct_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Indirect_Amount] [decimal](24, 2) NOT NULL,
	[Indirect_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomer_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [date] NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
