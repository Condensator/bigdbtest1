CREATE TYPE [dbo].[ContractHoldingStatusHistory] AS TABLE(
	[HoldingStatusChange] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[HoldingStatusStartDate] [date] NULL,
	[RNI_Amount] [decimal](16, 2) NULL,
	[RNI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[HoldingStatusComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[UpdatedByDate] [date] NULL,
	[LastUpdatedByUserId] [bigint] NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
