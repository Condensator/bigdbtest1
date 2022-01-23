CREATE TYPE [dbo].[IDCLOBDetail] AS TABLE(
	[IDCPercent] [decimal](5, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Basis] [nvarchar](28) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdditionalFixedAmount_Amount] [decimal](16, 2) NULL,
	[AdditionalFixedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[IDCTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
