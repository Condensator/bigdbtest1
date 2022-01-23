CREATE TYPE [dbo].[PayoffTradeUpFee] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TradeUpFeeDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[TradeUpFeeDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[TradeUpFeeDocument_Content] [varbinary](82) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
