CREATE TYPE [dbo].[AssetSaleReceivable] AS TABLE(
	[InstallmentNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Tax_Amount] [decimal](16, 2) NOT NULL,
	[Tax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[SundryRecurringId] [bigint] NULL,
	[SundryReceivableId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[AssetSaleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
