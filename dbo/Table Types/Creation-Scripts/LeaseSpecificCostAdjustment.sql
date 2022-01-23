CREATE TYPE [dbo].[LeaseSpecificCostAdjustment] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[CapitalizeFrom] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayableInvoiceOtherCostId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
