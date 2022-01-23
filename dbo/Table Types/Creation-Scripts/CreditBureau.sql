CREATE TYPE [dbo].[CreditBureau] AS TABLE(
	[BureauCustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BureauCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AddedDate] [date] NOT NULL,
	[RemovedDate] [date] NULL,
	[IsNoMatchFound] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[BusinessBureauId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
