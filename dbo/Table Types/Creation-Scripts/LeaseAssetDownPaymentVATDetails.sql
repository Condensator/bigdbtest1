CREATE TYPE [dbo].[LeaseAssetDownPaymentVATDetails] AS TABLE(
	[VATAmount_Amount] [decimal](16, 2) NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VATCodeId] [bigint] NULL,
	[VATTypeId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
