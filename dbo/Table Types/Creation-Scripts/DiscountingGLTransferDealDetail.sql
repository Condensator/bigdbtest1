CREATE TYPE [dbo].[DiscountingGLTransferDealDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLSegmentChangeComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[ExistingFinanceId] [bigint] NOT NULL,
	[DiscountingId] [bigint] NOT NULL,
	[NewLegalEntityId] [bigint] NULL,
	[NewLineofBusinessId] [bigint] NULL,
	[NewCostCenterId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[NewBranchId] [bigint] NULL,
	[DiscountingGLTransferId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
