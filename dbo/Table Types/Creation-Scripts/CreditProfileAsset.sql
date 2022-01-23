CREATE TYPE [dbo].[CreditProfileAsset] AS TABLE(
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Type] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Quantity] [int] NULL,
	[LocationCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
