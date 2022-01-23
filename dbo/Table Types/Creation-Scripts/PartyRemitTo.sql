CREATE TYPE [dbo].[PartyRemitTo] AS TABLE(
	[IsDefault] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RemittanceGroupingOption] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[RemitToId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
