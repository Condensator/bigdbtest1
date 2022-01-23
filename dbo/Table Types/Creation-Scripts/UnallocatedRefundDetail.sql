CREATE TYPE [dbo].[UnallocatedRefundDetail] AS TABLE(
	[AmountToBeCleared_Amount] [decimal](16, 2) NOT NULL,
	[AmountToBeCleared_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceiptAllocationId] [bigint] NOT NULL,
	[UnallocatedRefundId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
